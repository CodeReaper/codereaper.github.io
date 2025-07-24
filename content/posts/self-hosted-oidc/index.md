---
title: Set up a self-hosted OIDC provider
date: 2025-06-18T00:00:00+02:00
draft: false
---

Let us go through how you can set up a OIDC provider in a kubernetes cluster. The main components we will use are:

- [Kind](https://kind.sigs.k8s.io) as a cluster stand-in
- [Ingress nginx controller](https://kubernetes.github.io/ingress-nginx/) as router of http traffic
- [Dex](https://dexidp.io) as a federated OIDC provider
- [GLAuth](https://glauth.github.io) as an authentication backend
- [Grafana](https://grafana.com/grafana/) and [Argo CD](https://argoproj.github.io/cd/) as OIDC-capable web applications

You can skip ahead to [The Setup](#the-setup) and review it yourself, otherwise the next few sections will explain how each item is configured to work with the other items.

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

Basically nip.io address always resolves to the ip address in its name:

| Prefix | Dot | Address | Dot | Suffix |
|---|---|---|---|---|
|`anything.i.want`|`.`|`127.0.0.1`|`.`|`nip.io`|

This means everything is served by the localhost which will work fine for your browser - _but inside the cluster using localhost will be an issue we need to tackle_.

### Cluster DNS

The web applications are inside the cluster running on individual [pods](https://kubernetes.io/docs/concepts/workloads/pods/) - _or group of containers_ - which mean they each have an IP and therefore `127.0.0.1` and localhost will be their own loopback interface.

This means that if the Dex pod made a request to `http://argocd.127.0.0.1.nip.io`, then Dex would connect to itself.

For a browser making HTTP request to the cluster this is not an issue, but part of the OIDC login flow requires the OIDC-capable application to make requests directly the OIDC provider.

To solve this issue we are going to make CoreDNS - _the DNS server that came with Kind_ - rewrite the DNS lookup for Dex to the service that points to Dex.

We can do this by updating the `ConfigMap` named `coredns` in the `kube-system` namespace and add the highlighted line:

{{<code language="yaml" source="manifests/coredns.yaml" options="linenos=table,hl_lines=2,lineNoStart=13" lines="13-15">}}

{{<collapsed-code summary="Show ConfigMap" language="yaml" source="manifests/coredns.yaml" options="linenos=table,hl_lines=14">}}

## Set Up the OIDC Provider

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

## The Setup

{{<collapsed-code summary="Show Makefile" language="make" source="Makefile">}}
