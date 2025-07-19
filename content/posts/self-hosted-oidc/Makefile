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

setup: verify-deps assemble create apply

assemble:
	-rm -rf $(tmp)
	-mkdir -p $(tmp)

	export ARGOCD=$$(openssl rand -hex 20) GRAFANA=$$(openssl rand -hex 20) REDIS=$$(openssl rand -hex 20) && \
		kubectl create secret generic --dry-run=client --output yaml --type=Opaque --from-literal "ARGO_CD_CLIENT_SECRET=$$ARGOCD" --from-literal "GRAFANA_CLIENT_SECRET=$$GRAFANA" --namespace dex client-secrets \
			> $(tmp)/initial.yaml && \
			printf -- '---\n' >> $(tmp)/initial.yaml && \
		kubectl create secret generic --dry-run=client --output yaml --type=Opaque --from-literal "CLIENT_SECRET=$$GRAFANA" --namespace grafana client-secret \
			>> $(tmp)/initial.yaml && \
			printf -- '---\n' >> $(tmp)/initial.yaml && \
		kubectl create secret generic --dry-run=client --output yaml --type=Opaque --from-literal "auth=$$REDIS" --namespace argocd argocd-redis \
			>> $(tmp)/initial.yaml && \
			printf -- '---\n' >> $(tmp)/initial.yaml && \
		kubectl create secret generic --dry-run=client --output yaml --type=Opaque --from-literal "CLIENT_SECRET=$$ARGOCD" --namespace argocd client-secret | yq '.metadata.labels."app.kubernetes.io/part-of" = "argocd"' \
			>> $(tmp)/initial.yaml

	curl -sfL https://raw.githubusercontent.com/kubernetes/ingress-nginx/helm-chart-4.11.2/deploy/static/provider/kind/deploy.yaml > $(tmp)/applications-part-1.yaml

	helm template argocd argo-cd --version 7.8.15 --repo https://argoproj.github.io/argo-helm -n argocd -f values/argocd.yaml --create-namespace >> $(tmp)/base.yaml
	printf -- '---\n' >> $(tmp)/base.yaml

	helm template dex dex --version 0.19.1 --repo https://charts.dexidp.io -n dex -f values/dex.yaml --create-namespace | yq '.metadata.namespace = "dex"' >> $(tmp)/base.yaml
	printf -- '---\n' >> $(tmp)/base.yaml

	helm template grafana grafana --version 9.2.10 --repo https://grafana.github.io/helm-charts -n grafana -f values/grafana.yaml --create-namespace >> $(tmp)/base.yaml

	yq 'select(.kind == "CustomResourceDefinition")' < $(tmp)/base.yaml > $(tmp)/crd.yaml
	yq 'select(.kind and .kind != "CustomResourceDefinition")' < $(tmp)/base.yaml > $(tmp)/applications.yaml

	rm $(tmp)/base.yaml

	find manifests -type f -iname "*.yaml" -exec sh -c "printf -- '\n---\n' >> $(tmp)/applications.yaml && cat {} >> $(tmp)/applications.yaml" \;
	mv $(tmp)/applications.yaml $(tmp)/applications-part-2.yaml

create:
	kind -q create cluster --config kind.config --name $(cluster)
	$(kubectl) create namespace ingress-nginx
	$(kubectl) create namespace dex
	$(kubectl) create namespace argocd
	$(kubectl) create namespace grafana
	$(kubectl) apply -f $(tmp)/initial.yaml
	$(kubectl) apply -f $(tmp)/crd.yaml
	$(kubectl) apply -f $(tmp)/applications-part-1.yaml
	$(kubectl) rollout status -n ingress-nginx deployment

apply:
	$(kubectl) apply --server-side --force-conflicts -f $(tmp)/applications-part-2.yaml
	@sleep 5
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
	$(curl) -fsLo - http://grafana.127.0.0.1.nip.io/api/user | yq $(tmp)/profile --input-format json
	@echo
