---
title: Set up a self-hosted OIDC provider
date: 2025-06-18T00:00:00+02:00
draft: false
---

groups in grafana?
ingresses?
share txt lessons?


Easy! On your computer or laptop, we just need to install the tooling and use ~2GB RAM and a bit of cpu for the duration of this demo

Sketch the components?

SSL
- kind cluster with 443 port
- openssl create self-signed certificate (marble of nip.io)
- cert-manager with generated cert
- explain the cert-manager how it should be used
- ingress controller
- avoid coredns rewrite?

LDAP
- https://github.com/bitnami-labs/sealed-secrets for the hard way with sidecar assembly of config
- easy way with straight up secret of config with hashed passwords
(one for argocd and one for grafana - to discuss connector to client strategy?)

DEX
- issuer, connectors and staticClients
- claims and groups - expand on ldap groups
- clientSecrets
- bindPW in a secret?

ARGOCD
- Configure connection with dex, including clientSecret
- Show test from old post, including new group claim
- avoid requestedIDTokenClaims?

GRAFANA
- Configure connection with dex, including clientSecret

See:
{{<code language="yaml" source="values/dex.yaml" options="linenos=table,hl_lines=12">}}
