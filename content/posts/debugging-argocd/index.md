---
title: Debugging Argo CD and OIDC logins
date: 2024-08-21T00:00:00+02:00
draft: false
---

Over the past years a constant reoccurring pain in my daily job is when we have spun up a fresh kubernetes cluster and need to sign into [Argo CD](https://argoproj.github.io/cd/) for the first time. We are greeted with the following failure:

> failed to get token: oauth2: "invalid client" "invalid client credentials."

We know the issue is with Argo CD itself since our Identity Provider is used for logging with 5+ different applications within the same cluster.

Now I have lost hope that this login issue will be resolved by updating Argo CD, at least without someone (_me, I guess_) pinpointing the root cause.

Let me take you through my journey of discovery or you can skip to [The Root Cause](#the-root-cause).

## The Test Setup

First I made an empty [kind](https://kind.sigs.k8s.io) cluster and started building a minimum setup to make an OIDC login into Argo CD where I used the following products:

- Argo CD
- OIDC identity provider | [Dex](https://dexidp.io/)
- Ingress | [ingress-nginx](https://kubernetes.github.io/ingress-nginx/)

This means this simple cluster looks like this:

```goat
              .------.
    .---------. Kind .-----------.
    |         .------.           |
    |                            |
.---------.        .-------.     |
| Ingress |--.--> | Argo CD |    |
.---------.  |     '-------'     |
    |        |       .---.       |
    |        .----> | Dex |      |
    |                '---'       |
    |                            |
    .----------------------------.
```

Knowing I would need to run and re-run setups, teardowns and tests many, many, many times to know if the issue was consistently reproduced I figured it would be a good idea to organize everything in a Makefile.

Some of code snippets in this post will have variables that when run by `make` is replaced by actual values by [`envsubst`](https://www.gnu.org/software/gettext/manual/html_node/envsubst-Invocation.html). _This is to make sure they are the same value across all of the configuration._

Example variables:
- `$ARGO` - The host for Argo CD
- `$CLIENT_SECRET` - A shared secret

Let us review the rest of the relevant configuration before we mimic the OIDC login flow.

### Dex

Dex is a widely used OpenID Connect Provider that can be configured with static clients and static user logins which is beneficial for our test setup.

The installation uses its Helm chart and for completeness you may review the values file used below.

{{<collapsed-code summary="View Dex values file" language="yaml" source="values/dex.yaml">}}

### Argo CD

Argo CD is installed using its Helm chart and with mostly default values. The important non-default settings are:
 - Disabling the builtin Dex
 - Providing OIDC configuration to use the Dex we installed

That makes the values file look like this:

{{<code language="yaml" source="values/argocd.yaml">}}

### Kind

It was not trouble-free to setup Kind. You must configure port mapping to make anything inside the Kind cluster available on the outside.

You could use port forwarding instead instead of configuring Kind, however managing those ports becomes painful when you want to run multiple `make` recipes to run test cases.

The easier solution was to create the Kind cluster with the following configuration:

{{<code language="yaml" source="kind.config">}}

### Ingress

There was a guide to setting up [ingress on Kind](https://kind.sigs.k8s.io/docs/user/ingress) and we only needed simple host mapping. You can review the ingress manifests below.

{{<collapsed-code summary="View ingress manifests" language="yaml" source="manifests/ingress.yaml">}}

### Client Secrets

For the OIDC login flow to function both Argo CD and Dex will need to know a shared client secret and both applications can be configured to read this client secret from [Kubernetes secrets](https://kubernetes.io/docs/concepts/configuration/secret/).

The Makefile contains a variable that will be used as the shared secret to generate two secrets with the same value to configure both applications.

For instance the secret provided for Dex looks like this:

{{<code language="yaml" source="manifests/dex-secret.yaml">}}

### Bypass HTTPS/SSL requirements

It is common to run into issues with SSL when testing locally because you want to keep everything simple while you debug. It is also common for there to be a way to turn the SSL requirement off.

Currently we only have port `80`/`http` mapped in our Kind cluster. The ingress happily routes traffic on port `80` towards our applications. Dex does not - _at least not per default_ - enforce using SSL. Argo CD needs to be configured to allow using unencrypted `http`. This is done with the following line in its values file:

```yaml
server.insecure: true
```

### Bypass DNS requirements

Both applications we have set up are routed to using the hostnames `dex.host` and `argocd.host` and these hostnames do not exist in any DNS anywhere.

#### From the Outside

I wanted to make sure running the make recipes for testing purposes would work in isolation therefore adding the hostnames to the `/etc/hosts` file was a no-go.

It was a good thing that I went looking for a different way to handle hostnames because I learned a new thing about [`curl`](https://curl.se) from this list of [name resolving tricks](https://everything.curl.dev/usingcurl/connections/name.html).

The `--resolve` option can override resolving a `hostname:port` combination to a specific address (_or addresses_). This means I can run curl command towards the Argo CD running in my Kind cluster with the following command:

```sh
curl -v \
 --resolve argocd.host:80:127.0.0.1 \
 http://argocd.host/
```

Running the curl in verbose mode lets you know that the option simply adds fake records to the DNS cache for the current execution with the following logging output:

```
* Added argocd.host:80:127.0.0.1 to DNS cache
* Hostname argocd.host was found in DNS cache
*   Trying 127.0.0.1:80...
* Connected to argocd.host (127.0.0.1) port 80
...
```

#### On the Inside

_As you will see later_ ArgoCD needs to resolve the hostname for Dex internally in the Kind cluster. We do not have much choice on the inside of the cluster and will need to manipulate [CoreDNS](https://coredns.io).

Thankfully manipulating CoreDNS is as easy as providing a custom `ConfigMap` with its configuration.

We grab and expand the current configuration to make CoreDNS resolve the hostname for Dex as the service named `http.dex.svc`. See the highlighted `line 14` in this `ConfigMap`:

{{<code language="yaml" source="manifests/coredns.yaml" options="linenos=table,hl_lines=14">}}

Note that `http.dex.svc` is a service we will have to add ourselves. You can review the service manifest below.

{{<collapsed-code summary="View service manifest" language="yaml" source="manifests/dex-service.yaml">}}

## Mimicking OIDC Login Flow

After preparing the setup and configuration we are now ready to run tests. _Obviously I ran the setup and test recipes many times to get the setup and configuration working too_.

My very first step before debugging this issue was to find some way of using `curl` to mimic OIDC logins and I had found this [StackOverflow answer](https://stackoverflow.com/a/65814771/190599). I was able to piece together the commands that leads to a token using the `curl` commands from that answer (_in verbose mode_) supported by inspection of logins into an Argo CD in the wild.

I am letting the diagram below do most of the explaining with HTTP verbs and paths, but there will be more explanation after the diagram.

{{< comment >}}
https://textart.io/sequence

object HTTP ArgoCD Dex
HTTP->ArgoCD: GET login
note right of ArgoCD: Sets state cookie
ArgoCD-> HTTP: Redirects to Dex
HTTP->Dex: GET login
Dex-> HTTP: Login form
HTTP->Dex: POST form
Dex->HTTP: Redirects to ArgoCD callback with code
HTTP->ArgoCD: GET callback
ArgoCD->Dex: GET token
Dex->ArgoCD: Token
note right of ArgoCD: Sets token cookie
ArgoCD-> HTTP: Redirects to /
{{< /comment >}}

```goat
+-------+                               +---------+                                +-----+
| curl  |                               | Argo CD |                                | Dex |
+---.---+                               +----.----+                                +--.--+
    |                                        |                                        |
  1 | GET /auth/login                        |                                        |
    .--------------------------------------->|                                        |
    |                                        |                                        |
    |                                        | +---------------------------+          |
  2 |                                        .-. Sends state cookie header |          |
    |                                        | +---------------------------+          |
    |                                        |                                        |
  3 |             303 - http://dex.host/auth |                                        |
    |<---------------------------------------.                                        |
    |                                        |                                        |
  4 | GET /auth                              |                                        |
    .----------------------------------------)--------------------------------------->|
    |                                        |                                        |
  5 |                                        |                       200 - login form |
    |<---------------------------------------)----------------------------------------.
    |                                        |                                        |
  6 | POST /auth/local/login                 |                                        |
    .----------------------------------------)--------------------------------------->|
    |                                        |                                        |
  7 |                                        | 303 - http://argocd.host/auth/callback |
    |                                        |                                        |
    |<---------------------------------------)----------------------------------------.
    |                                        |                                        |
  8 | GET /auth/callback                     |                                        |
    .--------------------------------------->|                                        |
    |                                        |                                        |
  9 |                                        | GET /token                             |
    |                                        .--------------------------------------->|
    |                                        |                                        |
 10 |                                        |                            200 - empty |
    |                                        |<---------------------------------------.
    |                                        |                                        |
    |                                        | +---------------------------+          |
 11 |                                        .-. Sends token cookie header |          |
    |                                        | +---------------------------+          |
    |                                        |                                        |
 12 |                                303 - / |                                        |
    |<---------------------------------------.                                        |
    |                                        |                                        |
```

### Diagram additional explanations

**#2** The cookies must be captured since Argo CD uses them for verification in #8.

**#5** The html for the login form must be captured since we need to POST to the action endpoint of that form in #6.

**#6** This step includes the username and password in the POST payload.

**#9** This step was the problematic DNS lookup that required tinkering with CoreDNS.

**#11** The cookies must be captured since they now contain the JWT.

## Conclusion

At this point while getting the OIDC login in a working state I had already stumbled over the problem that leads to the failure message:

> failed to get token: oauth2: "invalid client" "invalid client credentials."

The root cause I found is only relevant when Argo CD is configured to use "SSO clientSecret with secret references", see [Argo CD documentation](https://argo-cd.readthedocs.io/en/stable/operator-manual/user-management/#sensitive-data-and-sso-client-secrets) for details.

We are referencing such a secret at `line 12` in the Argo CD values file.

{{<code language="yaml" source="values/argocd.yaml" options="linenos=table,hl_lines=12">}}

The problem is that the secrets and config maps with a `app.kubernetes.io/part-of: argocd` label is queried and replaced into Argo CD configuration only under certain conditions:

- Initially during startup and is cached afterwards
- CRUD operations related to the list of cluster managed
- Performing CLI operations

You may check my setup and test cases by reviewing the Makefile I have been referencing, or run its recipes:

```sh
# start out working and then break it
make working test
make break
make test
# start out broken and then fix it
make broken test
make fix
make test
```

{{<collapsed-code summary="Show Makefile" language="make" source="Makefile">}}

## The Root Cause

Summarized, **Argo CD does not detect if any of your secrets have changed**.

Therefore it is imperative that all secrets are created prior to installing Argo CD or to restart the Argo CD deployments when secrets are updated.

_Not really a satisfying solution, but good enough for now_.
