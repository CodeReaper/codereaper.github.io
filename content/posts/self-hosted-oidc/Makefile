cluster := setting-up-oidc

tmp := /tmp/$(cluster)
kubectl := kubectl --context kind-$(cluster)

jar := $(tmp)/cookie.jar
curl := curl --cookie $(jar) --cookie-jar $(jar)

all: clean setup test

verify-deps:
	which docker kind kubectl helm curl yq base64 > /dev/null

clean: verify-deps
	-kind -q delete cluster --name $(cluster)
	-find $(tmp) -delete -mindepth 1
	-find build -not -name .gitignore -delete

setup: verify-deps configure create apply

configure: build/initial.yaml build/cluster-applications.yaml build/dex build/argo-cd build/grafana
	-rm -rf $(tmp)
	-mkdir -p $(tmp)
	helm template dex build/dex -n dex -f values/dex.yaml --create-namespace | yq '.metadata.namespace = "dex"' > $(tmp)/c.0
	helm template argocd build/argo-cd -n argocd -f values/argocd.yaml --create-namespace > $(tmp)/c.1
	helm template grafana build/grafana -n grafana -f values/grafana.yaml --create-namespace > $(tmp)/c.2
	yq 'select(.kind == "CustomResourceDefinition")' $(tmp)/c.* > build/crd.yaml
	yq 'select(.kind and .kind != "CustomResourceDefinition")' $(tmp)/c.* manifests/*.yaml > build/applications.yaml

build/dex:
	helm pull dex --version 0.19.1 --repo https://charts.dexidp.io --destination build --untar

build/argo-cd:
	helm pull argo-cd --version 7.8.15 --repo https://argoproj.github.io/argo-helm --destination build --untar

build/grafana:
	helm pull grafana --version 9.2.10 --repo https://grafana.github.io/helm-charts --destination build --untar

build/initial.yaml:
	-rm -rf $(tmp)
	-mkdir -p $(tmp)
	export ARGOCD=$$(openssl rand -hex 20) GRAFANA=$$(openssl rand -hex 20) API=$$(openssl rand -hex 20) REDIS=$$(openssl rand -hex 20) && \
		kubectl create secret generic --dry-run=client --output yaml --type=Opaque --from-literal "ARGO_CD_CLIENT_SECRET=$$ARGOCD" --from-literal "GRAFANA_CLIENT_SECRET=$$GRAFANA" --namespace dex client-secrets > $(tmp)/a.0 && \
		kubectl create secret generic --dry-run=client --output yaml --type=Opaque --from-literal "CLIENT_SECRET=$$GRAFANA" --namespace grafana client-secret > $(tmp)/a.1 && \
		kubectl create secret generic --dry-run=client --output yaml --type=Opaque --from-literal "admin-user=api" --from-literal "admin-password=$$API" --namespace grafana credentials > $(tmp)/a.2 && \
		kubectl create secret generic --dry-run=client --output yaml --type=Opaque --from-literal "auth=$$REDIS" --namespace argocd argocd-redis > $(tmp)/a.3 && \
		kubectl create secret generic --dry-run=client --output yaml --type=Opaque --from-literal "CLIENT_SECRET=$$ARGOCD" --namespace argocd client-secret | yq '.metadata.labels."app.kubernetes.io/part-of" = "argocd"' > $(tmp)/a.4
	yq $(tmp)/a.* > build/initial.yaml

build/cluster-applications.yaml:
	-rm -rf $(tmp)
	-mkdir -p $(tmp)
	curl -sfL https://raw.githubusercontent.com/kubernetes/ingress-nginx/helm-chart-4.11.2/deploy/static/provider/kind/deploy.yaml > $(tmp)/b.0
	curl -sfL https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.8.0/components.yaml \
		| yq 'with(select(.kind == "Deployment"); .spec.template.spec.containers[0].args += ["--kubelet-insecure-tls"])' > $(tmp)/b.1
	yq $(tmp)/b.* > build/cluster-applications.yaml

create:
	kind -q create cluster --config kind.config --name $(cluster)
	$(kubectl) create namespace ingress-nginx
	$(kubectl) create namespace dex
	$(kubectl) create namespace argocd
	$(kubectl) create namespace grafana
	$(kubectl) apply -f build/crd.yaml
	$(kubectl) apply -f build/cluster-applications.yaml
	$(kubectl) rollout status -n ingress-nginx deployment

apply:
	$(kubectl) apply --server-side --force-conflicts --wait -f build/initial.yaml
	$(kubectl) apply --server-side --force-conflicts -f build/applications.yaml
	$(kubectl) rollout restart -n kube-system deployment/coredns

	$(kubectl) rollout status -n grafana deployment
	$(kubectl) rollout status -n dex deployment
	$(kubectl) rollout status -n argocd statefulset
	$(kubectl) rollout status -n argocd deployment

test: test-argocd test-grafana

test-argocd:
	-mkdir -p $(tmp)
	-rm -f $(jar)
	touch $(jar)
	@echo

	$(curl) -fsLo $(tmp)/login.html http://argo.127.0.0.1.nip.io/auth/login
	grep -o 'action="[^"]*"' < $(tmp)/login.html | cut -d\" -f2 | sed 's/&amp;/\&/g' > $(tmp)/path
	@echo

	$(curl) -fsD $(tmp)/header.log -XPOST -d "login=alice&password=password123" "http://dex.127.0.0.1.nip.io$$(cat $(tmp)/path)"
	grep ^Location $(tmp)/header.log | cut -d' ' -f2 | tr -d '\r' > $(tmp)/endpoint
	@echo

	$(curl) -fso /dev/null "$$(cat $(tmp)/endpoint)"
	@echo

	grep argocd.token $(jar) | cut -f7- | tee $(tmp)/token
	@echo

	@echo Token payload:
	(cut -d. -f2 < $(tmp)/token|tr -d '\n'; echo '===') | base64 -d | yq --input-format json
	@echo

test-grafana:
	-mkdir -p $(tmp)
	-rm -f $(jar)
	touch $(jar)
	@echo

	$(curl) -fsLo $(tmp)/login.html http://grafana.127.0.0.1.nip.io/login/generic_oauth
	grep -o 'action="[^"]*"' < $(tmp)/login.html | cut -d\" -f2 | sed 's/&amp;/\&/g' > $(tmp)/path
	@echo

	$(curl) -fsD $(tmp)/header.log -XPOST -d "login=alice&password=password123" "http://dex.127.0.0.1.nip.io$$(cat $(tmp)/path)"
	grep ^Location $(tmp)/header.log | cut -d' ' -f2 | tr -d '\r' > $(tmp)/endpoint
	@echo

	$(curl) -fso $(tmp)/more "$$(cat $(tmp)/endpoint)"
	@echo

	@echo Session cookie:
	@grep grafana_session $(jar) | grep -v expiry | cut -f7-
	@echo

	@echo User profile:
	$(curl) -fsLo - http://grafana.127.0.0.1.nip.io/api/user | yq --input-format json
	@echo
