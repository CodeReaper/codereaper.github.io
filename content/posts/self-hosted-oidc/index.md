---
title: Set up a self-hosted OIDC provider
date: 2025-06-18T00:00:00+02:00
draft: false
---

Let us go through how you can set up a OIDC provider in a kubernetes cluster. The main components we will use are:

- [Kind](https://kind.sigs.k8s.io) as a cluster stand-in
- [Ingress nginx controller](https://kubernetes.github.io/ingress-nginx/) as a router of http traffic
- [Dex](https://dexidp.io) as a federated OIDC provider
- [GLAuth](https://glauth.github.io) as an authentication backend
- [Grafana](https://grafana.com/grafana/) and [Argo CD](https://argoproj.github.io/cd/) as OIDC-capable web applications

You can skip ahead a little to [The Setup](#the-setup), otherwise the next few sections will explain certain caveats and workarounds related to running the setup as a proof of concept locally.

## The Kubernetes Cluster

The first two components on the list are Kind and the ingress controller. They are both nothing special in this set up.

Kind is a simple way to have a local cluster for testing purposes which means you can likely test this your self on your own machine.
Kind brings along the actual kubernetes applications like api server, scheduler, dns server etc.

The ingress controller is a piece of required software for a kubernetes cluster to route network traffic behind the outside of the cluster to the inside of the cluster.

These two component enables the cluster to host HTTP applications - _and technically more, but again, this is irrelevant for our set up_.

## Network

We are taking certain shortcuts in regards to the network setup like securing it with HTTPS/SSL for a few reasons:

- it is irrelevant for demonstrating the OIDC provider
- it is provided by default by large kubernetes providers, like AKS, GKE, etc.
- there are lots of tutorials and guides for securing clusters with [cert-manager](https://cert-manager.io)

Our set up will work regardless of whether you have SSL termination at the ingress controller or at each application - _even though this local set up will use HTTP_.

Notably we are also skipping setting up SSL connections between applications in the network on the inside of the cluster.

### Application Network

The applications - _that we are going to discuss more in a bit_ - will have three web applications accessible through the ingress controller
and one application only accessible from the inside of the cluster and only used directly by Dex.

```goat
                   .------.
    .--------------. Kind .----------------.
    |              .------.                |
    |                .---.       .------.  |
    |           +-->| Dex |<--->| GLAuth | |
    |          /     '---'       '------'  |
.---------.   /                            |
| Ingress .<-+         .-------.           |
.---------.   \   +-->| Argo CD |          |
    |          \ /     '-------'           |
    |           +                          |
    |            \     .-------.           |
    |             +-->| Grafana |          |
    |                  '-------'           |
    .--------------------------------------.
```

We could assign a port number to each web application serve them them as `http://127.0.0.1:8080`, etc., but [nip.io](https://nip.io) is a better option and allows us to use these addresses instead:

- `http://dex.127.0.0.1.nip.io`
- `http://argocd.127.0.0.1.nip.io`
- `http://grafana.127.0.0.1.nip.io`

_Note there would be issues with OIDC redirection and/or cookies, if we try to use the one application per port approach_.

Basically nip.io address always resolves to the ip address in its name:

| Prefix            | Dot | Address     | Dot | Suffix   |
| ----------------- | --- | ----------- | --- | -------- |
| `anything.i.want` | `.` | `127.0.0.1` | `.` | `nip.io` |

This means everything is served by the localhost which will work fine for your browser - _but inside the cluster using localhost will be an issue we need to tackle_.

### Cluster DNS

The web applications are inside the cluster running on individual [pods](https://kubernetes.io/docs/concepts/workloads/pods/) - _or group of containers_ - which mean they each have an IP and therefore `127.0.0.1` and localhost will be their own loopback interface.

This means that if the Dex pod made a request to `http://argocd.127.0.0.1.nip.io`, then Dex would connect to itself.

For a browser making HTTP request to the cluster this is not an issue, but part of the OIDC login flow requires the OIDC-capable application to make requests directly the OIDC provider.

To solve this issue we are going to make CoreDNS - _the DNS server that came with Kind_ - rewrite the DNS lookup for Dex to the service that points to Dex.

We can do this by updating the `ConfigMap` named `coredns` in the `kube-system` namespace and add the highlighted line:

{{<code language="yaml" source="manifests/coredns.yaml" options="linenos=table,hl_lines=2,lineNoStart=13" lines="13-15">}}

{{<collapsed-code summary="Show the ConfigMap" language="yaml" source="manifests/coredns.yaml" options="linenos=table,hl_lines=14">}}

## The Setup

The authentication backend seems like a good starting point.

### Authentication

Authentication will be handled by GLAuth and we will need a deployment, a service and a secret for its configuration.

The service exposes port `3893` where we will communicate over LDAP.
{{<collapsed-code summary="Show the service manifest" language="yaml" source="manifests/svc-ldap.yaml" options="linenos=table">}}

The deployment is a very locked-down single replica of GLAuth in version 2.4.0.
{{<collapsed-code summary="Show the deployment manifest" language="yaml" source="manifests/deploy-ldap.yaml" options="linenos=table">}}

The secret contains all the configuration of GLAuth which we will need to dive a little deeper into in the next sections.
{{<collapsed-code summary="Show the secret manifest" language="yaml" source="manifests/secret-ldap.yaml" options="linenos=table">}}

#### GLAuth and Groups

You can configure users and groups where a user can be a member of multiple groups, but this does come with some weirdness.

The following example for Alice makes her a member of both the admin group and the editor group.

{{<code language="toml" source="manifests/secret-ldap.yaml" options="linenos=table,lineNoStart=1" lines="37-45,68-71,58-62">}}

Line 4
: This assigns Alice as a member of the admin group

Line 12
: The admin group is number 5003

Line 17
: The editor group is assigned to everyone in the number 5003 group

Note you can only assign a _single_ group to a user.

#### GLAuth and Dex

{{<code language="toml" source="manifests/secret-ldap.yaml" options="linenos=table,lineNoStart=1" lines="18-35">}}

---

As a first step we will generate the secrets we are going to need for passwords and client secrets.

{{<code language="make" source="Makefile" options="linenos=table,hl_lines=12" lines="41,44-49">}}

Line 2
: Generating random values

Line 3
: Generating secret for Dex containing both client secrets

Line 4-5
: Generating secret for Argo CD and Grafana

Line 6
: Generating secret containing the password for our LDAP service account

Line 7
: Combining all the generated secrets into a single `yaml` document

The shared secrets/values are now prepared and tie

### Dex

DEX

- issuer, connectors and staticClients
- claims and groups - expand on ldap groups
- clientSecrets

LDAP

- easy way with straight up secret of config with hashed passwords
  (one for argocd and one for grafana - to discuss connector to client strategy?)

ARGOCD

- Configure connection with dex, including clientSecret
- Show test from old post, including new group claim

GRAFANA

- Configure connection with dex, including clientSecret

See:
{{<code language="yaml" source="values/dex.yaml" options="linenos=table,hl_lines=12" lines="1">}}

{{<collapsed-code summary="Show Makefile" language="make" source="Makefile">}}
