---
title: Set up a self-hosted OIDC provider
date: 2026-03-15T00:00:00+02:00
draft: false
---

Let us go through how you can set up an OIDC provider in a kubernetes cluster. We will use:

- [Dex](https://dexidp.io) as a federated OIDC provider
- [GLAuth](https://glauth.github.io) as an authentication backend

After going through the general setup we will set up a local [proof of concept](#proof-of-concept).

## GLAuth

GLAuth is an LDAP server that handles user and group management. We will configure it to function as an authentication backend for Dex.

### Kubernetes manifests

A helm chart does exist for [GLAuth](https://github.com/glauth/helm-glauth), but it does not suit our needs. We are configuring this application to use statically defined users and will therefore need a deployment, a service and a secret for its configuration.

_Note_ - the communication between Dex and GLAuth is LDAP, but should be LDAP over SSL in a production cluster.

#### Service

The service exposes port `3893` where we will communicate over LDAP.
{{<collapsed-code summary="Show the service manifest" language="yaml" source="manifests/svc-ldap.yaml" options="linenos=table">}}

#### Deployment

The deployment is a very locked-down single replica with rolling updates of GLAuth in version 2.4.0 that mounts and uses the following secret as its configuration.
{{<collapsed-code summary="Show the deployment manifest" language="yaml" source="manifests/deploy-ldap.yaml" options="linenos=table">}}

#### Secret

The secret contains all the configuration of GLAuth which we will need to dive a little deeper into in the next section.
{{<collapsed-code summary="Show the secret manifest" language="yaml" source="manifests/secret-ldap.yaml" options="linenos=table">}}

### Configuration

The configuration consists of two parts, one for defining the statically defined users and groups and one for defining how to connect with the server.

#### Users and Groups

You can configure users and groups where a user can be a member of multiple groups, but this can feel a little quirky.

You can only assign a single group to a user, however you can configure groups to include members of another group.

The following example for Alice makes her a member of both the admin group and the editor group.

{{<code language="toml" source="manifests/secret-ldap.yaml" options="linenos=table,lineNoStart=1" lines="32-41,64-67,53-58">}}

Line 4
: This assigns Alice as a member of the admin group

Line 12
: The admin group is number 5003

Line 17
: The editor group is assigned to everyone in the number 5003 group

#### Connections and queries

The following configuration sets up the credentials Dex will use and defines the organization of the users.

{{<code language="toml" source="manifests/secret-ldap.yaml" options="linenos=table,lineNoStart=1" lines="18-30">}}

Line 3
: Sets the organization elements

Line 5-10
: Define the service account for Dex

Line 11-13
: Grants the service account search privileges

## Dex

Dex can federate with [many backends](https://dexidp.io/docs/connectors/) - GitHub, Google, LDAP, SAML, etc.

We are using the LDAP connector to talk to GLAuth.

### Configuration

The following configuration for Dex defines a bind user to connect to the LDAP with and configuration on how to perform user and group queries.

{{<code language="yaml" source="values/dex.yaml" options="linenos=table" lines="28-52">}}

Line 8-9
: Sets credentials for the service account

Line 11-17
: Define user queries that uses `uid` as username

Line 19-25
: Define group queries that use `memberUid` to resolve groups

### Static Clients

Static clients are applications that will use Dex for authentication. Each client must be registered with Dex to allow the OIDC authorization flow.

{{<code language="yaml" source="values/dex.yaml" options="linenos=table" lines="10-15">}}

Each client has:

- A unique id - this is what the application uses as its `client_id`
- A name for the Dex UI
- A secret (or secretEnv referencing an environment variable from a secret)
- redirectURIs - Dex will only redirect to these URLs after authentication.

### Groups

The group membership defined for the users in GLAuth can be queried by Dex using the `groupSearch`.
Any group memberships will result in tokens issued having a `groups` claim with the names of each group.

_Note_ - the `group` claim is only included if the OIDC login flow is started with `groups` as one of the requested scopes.

## Securing an Application with OIDC Groups and RBAC

The purpose of the GLAuth/Dex setup we have discussed so far can be used to secure an OIDC-capable application.

Let us use it to secure Argo CD including RBAC as an example.

The RBAC in Argo CD can use the groups claim from the OIDC token to make authorization decisions.

Argo CD has built-in support for OIDC and can be configured like the following:

{{<code language="yaml" source="values/argocd.yaml" options="linenos=table" lines="10-11,14-20">}}

The key parts:

- `issuer` must match the issuer URL from Dex exactly
- `clientID` matches the static client ID we defined in Dex
- `clientSecret` matches the same secret value as the static client
- The `requestedScopes` include `groups` - this is critical for RBAC

_Note_ - current version of Argo CD has a [bug related to referenced secrets](https://github.com/argoproj/argo-cd/issues/26269), that made it necessary to place the client secret in directly argocd-secret.

Argo CD uses OIDC groups for authorization. The RBAC configuration maps groups to roles:

{{<code language="yaml" source="values/argocd.yaml" options="linenos=table" lines="20-27">}}

Roles are assigned based on the groups claim:

| Group Claim | Assigned Role | Logged in |
| :---------- | :------------ | :-------- |
| editor      | admin         | Yes       |
| viewer      | readonly      | Yes       |
| (no match)  | (none)        | No        |

## Proof of Concept

This section goes through a setup to run the above OIDC setup in a local Kubernetes cluster using Kind.

### Overview

The main components needed for this proof of concept are:

- [Kind](https://kind.sigs.k8s.io) as a cluster stand-in
- [NGINX Gateway Fabric](https://github.com/nginx/nginx-gateway-fabric) as an ingress controller for http traffic
- [Dex](https://dexidp.io) as a federated OIDC provider
- [GLAuth](https://glauth.github.io) as an authentication backend
- [Grafana](https://grafana.com/grafana/) as an OIDC-capable web application
- [Argo CD](https://argoproj.github.io/cd/) as an OIDC-capable web application

This proof of concept is based on an earlier post about [debugging OIDC logins](https://codereaper.com/blog/2024/debugging-argo-cd-and-oidc-logins/).

### The Kubernetes Cluster

The first two components on the list are Kind and the ingress controller. They are both nothing special in this setup.

Kind is a simple way to have a local cluster for testing purposes which means you can likely test this yourself on your own machine.
Kind brings along the actual kubernetes applications like api server, scheduler, dns server etc.

An ingress controller is required software for a kubernetes cluster to route network traffic behind the outside of the cluster to the inside of the cluster.

These two components enable the cluster to host HTTP applications - _and technically more, but again, this is irrelevant for our set up_.

### Network

We are taking certain shortcuts regarding the network setup like securing it with HTTPS/SSL for a few reasons:

- it is irrelevant for demonstrating the OIDC provider
- large Kubernetes providers, like AKS, GKE, etc. have provider specific guides available
- there are lots of tutorials and guides for securing clusters with [cert-manager](https://cert-manager.io)

Our setup will work regardless of whether you have SSL termination at the ingress controller or at each application - _even though this local setup will use HTTP_.

Notably we are also skipping setting up SSL connections between applications in the network on the inside of the cluster.

### Application Network

The cluster will expose three web applications accessible through the ingress controller
and one application only accessible from the inside of the cluster and only used directly by Dex.

```goat
                   .------.
    .--------------. Kind .----------------.
    |              .------.                |
    |                .---.       .------.  |
    |           +-->| Dex |<--->| GLAuth | |
    |          /     '---'       '------'  |
.---------.   /                            |
| Gateway .<-+         .-------.           |
.---------.   \   +-->| Argo CD |          |
    |          \ /     '-------'           |
    |           +                          |
    |            \     .-------.           |
    |             +-->| Grafana |          |
    |                  '-------'           |
    .--------------------------------------.
```

We could assign a port number to each web application serve them as `http://127.0.0.1:8080`, etc., but [nip.io](https://nip.io) is a better option and allows us to use these addresses instead:

- `http://dex.127.0.0.1.nip.io`
- `http://argocd.127.0.0.1.nip.io`
- `http://grafana.127.0.0.1.nip.io`

_Note there would be issues with OIDC redirection and/or cookies, if we try to use the one application per port approach_.

A nip.io address always resolves to the ip address in its name:

| Prefix            | Dot | Address     | Dot | Suffix   |
| :---------------- | :-- | :---------- | :-- | :------- |
| `anything.i.want` | `.` | `127.0.0.1` | `.` | `nip.io` |

This means everything is served by the localhost which will work fine for your browser - _but inside the cluster using localhost will be an issue we need to tackle_.

### Cluster DNS

The web applications are inside the cluster running on individual [pods](https://kubernetes.io/docs/concepts/workloads/pods/) - _or group of containers_ - which means they each have an IP and therefore `127.0.0.1` and localhost will be their own loopback interface.

This means that if the Dex pod made a request to `http://argocd.127.0.0.1.nip.io`, then Dex would connect to itself.

For a browser making HTTP request to the cluster this is not an issue, but part of the OIDC login flow requires the OIDC-capable application to make requests directly to the OIDC provider.

To solve this issue we are going to make CoreDNS - _the DNS server that came with Kind_ - rewrite the DNS lookup for Dex to the service that points to Dex.

We can do this by updating the `ConfigMap` named `coredns` in the `kube-system` namespace and add the highlighted line:

{{<code language="yaml" source="manifests/coredns.yaml" options="linenos=table,hl_lines=2,lineNoStart=13" lines="13-15">}}

{{<collapsed-code summary="Show the ConfigMap" language="yaml" source="manifests/coredns.yaml" options="linenos=table,hl_lines=14">}}

### Running the proof

The make file will:

- Create a kind cluster
- Configure network workaround
- Configure applications
- Perform OIDC logins
- Display claims from token from Argo CD
- Display user profile from Grafana

{{<collapsed-code summary="Show Makefile" language="make" source="Makefile">}}

#### Output

The final output from a run (which takes a few minutes) looks like:

```sh
Token:
iss: http://dex.127.0.0.1.nip.io
sub: CgVhbGljZRIGZ2xhdXRo
aud: argocd
exp: 1.773689837e+09
iat: 1.773603437e+09
at_hash: TQaEW8Y06l6Ivrd60XUhyw
c_hash: WzVpvw-SA7UV_AoKxLjoSw
email: alice@example.com
email_verified: true
groups:
  - editor
  - admin
name: alice

Session cookie:
88ee2a5587f828d9ae0470415e41729b

User profile:
id: 2
uid: ffg4cr1u6el1cd
email: alice@example.com
name: alice
login: alice@example.com
theme: ""
orgId: 1
isGrafanaAdmin: true
isDisabled: false
isExternal: true
isExternallySynced: true
isGrafanaAdminExternallySynced: true
authLabels:
  - Generic OAuth
updatedAt: "2026-03-15T19:37:18Z"
createdAt: "2026-03-15T19:37:18Z"
avatarUrl: /avatar/c160f8cc69a4f0bf2b0362752353d060
isProvisioned: false
```

The output demonstrates that we can successfully log in using an OIDC login flow for both sample applications.
