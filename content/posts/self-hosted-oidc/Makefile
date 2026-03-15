cluster := setting-up-oidc

tmp := /tmp/$(cluster)
kubectl := kubectl --context kind-$(cluster)

jar := $(tmp)/cookie.jar
curl := curl --cookie $(jar) --cookie-jar $(jar)

all: clean setup test

verify-deps:
	which docker kind kubectl helm curl yq base64 sha256 > /dev/null

clean: verify-deps
	-kind -q delete cluster --name $(cluster)
	-find $(tmp) -delete -mindepth 1
	-find build -not -name .gitignore -delete

setup: verify-deps configure create apply settle

configure: build/secrets.yaml build/argocd-secrets.yaml build/dex build/argo-cd build/grafana build/nginx-gateway-fabric
	-rm -rf $(tmp)
	-mkdir -p $(tmp)
	helm template dex build/dex -n dex -f values/dex.yaml --create-namespace | yq '.metadata.namespace = "dex"' > $(tmp)/c.0
	helm template argocd build/argo-cd -n argocd -f values/argocd.yaml --create-namespace > $(tmp)/c.1
	helm template grafana build/grafana -n grafana -f values/grafana.yaml --create-namespace > $(tmp)/c.2
	helm template ngf build/nginx-gateway-fabric -n nginx-gateway -f values/nginx.yaml --create-namespace > $(tmp)/c.3
	curl -fsL https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.5.1/standard-install.yaml > $(tmp)/c.4
	yq 'select(.kind == "CustomResourceDefinition")' $(tmp)/c.* build/nginx-gateway-fabric/crds/*.yaml > build/crd.yaml
	yq 'select(.kind and .kind != "CustomResourceDefinition")' $(tmp)/c.* manifests/*.yaml | \
	sed s/is-replaced-with-ldap-hash/$$(yq '. | select(.metadata.name == "ldap") | .data.LDAP_PASSWORD' build/secrets.yaml | base64 -d | sha256)/ \
	> build/applications.yaml

build/dex:
	helm pull dex --version 0.24.0 --repo https://charts.dexidp.io --destination build --untar

build/argo-cd:
	helm pull argo-cd --version 9.4.10 --repo https://argoproj.github.io/argo-helm --destination build --untar

build/grafana:
	helm pull grafana --version 11.3.2 --repo https://grafana-community.github.io/helm-charts --destination build --untar

build/nginx-gateway-fabric:
	helm pull --version 2.4.2 oci://ghcr.io/nginx/charts/nginx-gateway-fabric --destination build --untar

build/secrets.yaml:
	-rm -rf $(tmp)
	-mkdir -p $(tmp)
	export ARGOCD=$$(openssl rand -hex 20) GRAFANA=$$(openssl rand -hex 20) LDAP=$$(openssl rand -hex 20) && \
		kubectl create secret generic --dry-run=client --output yaml --type=Opaque --from-literal "ARGO_CD_CLIENT_SECRET=$$ARGOCD" --from-literal "GRAFANA_CLIENT_SECRET=$$GRAFANA" --namespace dex client-secrets > $(tmp)/a.0 && \
		kubectl create secret generic --dry-run=client --output yaml --type=Opaque --from-literal "CLIENT_SECRET=$$GRAFANA" --namespace grafana client-secret > $(tmp)/a.1 && \
		kubectl create secret generic --dry-run=client --output yaml --type=Opaque --from-literal "CLIENT_SECRET=$$ARGOCD" --from-literal "server.secretkey=$$(openssl rand -base64 32)" --namespace argocd argocd-secret | yq '.metadata.labels."app.kubernetes.io/part-of" = "argocd"' > $(tmp)/a.4 && \
		kubectl create secret generic --dry-run=client --output yaml --type=Opaque --from-literal "LDAP_PASSWORD=$$LDAP" --namespace dex ldap > $(tmp)/a.5 && \
	yq $(tmp)/a.* > build/secrets.yaml

build/argocd-secrets.yaml:
	-rm -rf $(tmp)
	-mkdir -p $(tmp)
	export API=$$(openssl rand -hex 20) REDIS=$$(openssl rand -hex 20) && \
		kubectl create secret generic --dry-run=client --output yaml --type=Opaque --from-literal "admin-user=api" --from-literal "admin-password=$$API" --namespace grafana credentials > $(tmp)/a.2 && \
		kubectl create secret generic --dry-run=client --output yaml --type=Opaque --from-literal "auth=$$REDIS" --namespace argocd argocd-redis > $(tmp)/a.3 && \
	yq $(tmp)/a.* > build/argocd-secrets.yaml

create:
	kind -q create cluster --config kind.config --name $(cluster)
	$(kubectl) create namespace nginx-gateway
	$(kubectl) create namespace dex
	$(kubectl) create namespace argocd
	$(kubectl) create namespace grafana
	$(kubectl) create namespace auth
	$(kubectl) apply --server-side -f build/crd.yaml
	$(kubectl) rollout status -n nginx-gateway deployment

apply:
	$(kubectl) apply --server-side --force-conflicts --wait -f build/secrets.yaml
	$(kubectl) apply --server-side --force-conflicts --wait -f build/argocd-secrets.yaml
	$(kubectl) apply --server-side --force-conflicts -f build/applications.yaml
	$(kubectl) rollout restart -n kube-system deployment/coredns

	$(kubectl) rollout status -n grafana deployment
	$(kubectl) rollout status -n dex deployment
	$(kubectl) rollout status -n argocd statefulset
	$(kubectl) rollout status -n argocd deployment

test: test-argocd test-grafana

test-argocd:
	-@mkdir -p $(tmp)
	-@rm -f $(jar)
	@touch $(jar)

	@$(curl) -fsLo $(tmp)/login.html http://argo.127.0.0.1.nip.io/auth/login
	@grep -o 'action="[^"]*"' < $(tmp)/login.html | cut -d\" -f2 | sed 's/&amp;/\&/g' > $(tmp)/path

	@$(curl) -fsD $(tmp)/header.log -XPOST -d "login=alice&password=password123" "http://dex.127.0.0.1.nip.io$$(cat $(tmp)/path)"
	@grep ^Location $(tmp)/header.log | cut -d' ' -f2 | tr -d '\r' > $(tmp)/endpoint

	@$(curl) -fso /dev/null "$$(cat $(tmp)/endpoint)"

	@grep argocd.token $(jar) | cut -f7- > $(tmp)/token

	@echo Token:
	@(cut -d. -f2 < $(tmp)/token|tr -d '\n'; echo '===') | base64 -d | yq --input-format json
	@echo

test-grafana:
	-@mkdir -p $(tmp)
	-@rm -f $(jar)
	@touch $(jar)

	@$(curl) -fsLo $(tmp)/login.html http://grafana.127.0.0.1.nip.io/login/generic_oauth
	@grep -o 'action="[^"]*"' < $(tmp)/login.html | cut -d\" -f2 | sed 's/&amp;/\&/g' > $(tmp)/path

	@$(curl) -fsD $(tmp)/header.log -XPOST -d "login=alice&password=password123" "http://dex.127.0.0.1.nip.io$$(cat $(tmp)/path)"
	@grep ^Location $(tmp)/header.log | cut -d' ' -f2 | tr -d '\r' > $(tmp)/endpoint

	@$(curl) -fso $(tmp)/more "$$(cat $(tmp)/endpoint)"

	@echo Session cookie:
	@grep grafana_session $(jar) | grep -v expiry | cut -f7-
	@echo

	@echo User profile:
	@$(curl) -fsLo - http://grafana.127.0.0.1.nip.io/api/user | yq --input-format json
	@echo

settle:
	@sleep 20
