cluster := debugging-argocd
argo := argocd.host
dex := dex.host

argoVersion := 7.4.4
dexVersion := 0.19.1
ingressVersion := 4.11.2

clientId := argo
clientSecret := some-secret-here

tmp := /tmp/$(cluster)
jar := $(tmp)/cookie.jar

kubectl := kubectl --context kind-$(cluster)
curl := curl -sf --resolve $(argo):80:127.0.0.1 --resolve $(dex):80:127.0.0.1 --cookie $(jar) --cookie-jar $(jar)

_ := $(shell mkdir -p $(tmp) ; find $(tmp) -delete -mindepth 1)

verify-deps:
	which docker kind kubectl helm curl jq envsubst base64 > /dev/null

clean: verify-deps
	-kind -q delete cluster --name $(cluster)
	-find $(tmp) -delete -mindepth 1

_setup: verify-deps clean
	ARGO=$(argo) DEX=$(dex) CLIENT_ID=$(clientId) CLIENT_SECRET=$(clientSecret) envsubst '$$ARGO,$$DEX,$$CLIENT_ID,$$CLIENT_SECRET' < values/argocd.yaml > $(tmp)/values-argocd.yaml
	ARGO=$(argo) DEX=$(dex) CLIENT_ID=$(clientId) CLIENT_SECRET=$(clientSecret) envsubst '$$ARGO,$$DEX,$$CLIENT_ID,$$CLIENT_SECRET' < values/dex.yaml > $(tmp)/values-dex.yaml
	ARGO=$(argo) DEX=$(dex) CLIENT_ID=$(clientId) CLIENT_SECRET=$(clientSecret) envsubst '$$ARGO,$$DEX,$$CLIENT_ID,$$CLIENT_SECRET' < manifests/ingress.yaml > $(tmp)/ingress.yaml
	ARGO=$(argo) DEX=$(dex) CLIENT_ID=$(clientId) CLIENT_SECRET=$(clientSecret) envsubst '$$ARGO,$$DEX,$$CLIENT_ID,$$CLIENT_SECRET' < manifests/coredns.yaml > $(tmp)/coredns.yaml
	ARGO=$(argo) DEX=$(dex) CLIENT_ID=$(clientId) CLIENT_SECRET=$(clientSecret) envsubst '$$ARGO,$$DEX,$$CLIENT_ID,$$CLIENT_SECRET' < manifests/dex-secret.yaml > $(tmp)/dex-secret.yaml
	ARGO=$(argo) DEX=$(dex) CLIENT_ID=$(clientId) CLIENT_SECRET=$(clientSecret) envsubst '$$ARGO,$$DEX,$$CLIENT_ID,$$CLIENT_SECRET' < manifests/argocd-secret.yaml > $(tmp)/argocd-secret.yaml

	curl -sfL https://raw.githubusercontent.com/kubernetes/ingress-nginx/helm-chart-$(ingressVersion)/deploy/static/provider/kind/deploy.yaml > $(tmp)/ingress-nginx.yaml
	helm template argocd argo-cd --version $(argoVersion) --repo https://argoproj.github.io/argo-helm -n argocd -f $(tmp)/values-argocd.yaml --create-namespace > $(tmp)/argocd.yaml
	helm template dex dex --version $(dexVersion) --repo https://charts.dexidp.io -n dex -f $(tmp)/values-dex.yaml --create-namespace > $(tmp)/dex.yaml

	kind -q create cluster --config kind.config --name $(cluster)
	@echo

	$(kubectl) create namespace ingress-nginx
	$(kubectl) create namespace dex
	$(kubectl) create namespace argocd
	@echo

	$(kubectl) apply -ningress-nginx -f $(tmp)/ingress-nginx.yaml
	sleep 5 # `kubectl wait` requires the resource to exist
	$(kubectl) wait --namespace ingress-nginx \
		--for=condition=ready pod \
		--selector=app.kubernetes.io/component=controller \
		--timeout=90s
	@echo

	$(kubectl) apply --filename $(tmp)/ingress.yaml
	$(kubectl) apply --filename $(tmp)/coredns.yaml
	$(kubectl) rollout restart -n kube-system deployment/coredns
	@echo

	$(kubectl) apply --filename $(tmp)/dex-secret.yaml
	$(kubectl) apply --filename manifests/dex-service.yaml
	$(kubectl) apply -ndex -f $(tmp)/dex.yaml
	sleep 5 # `kubectl wait` requires the resource to exist
	$(kubectl) wait -n dex \
		--for=condition=Ready pod \
		--selector=app.kubernetes.io/name=dex \
		--timeout=90s
	@echo

working: _setup
	$(kubectl) apply --filename $(tmp)/argocd-secret.yaml
	$(kubectl) apply -nargocd -f $(tmp)/argocd.yaml
	sleep 5 # `kubectl wait` requires the resource to exist
	$(kubectl) wait -n argocd \
		--for=condition=Ready pod \
		--selector=app.kubernetes.io/name=argocd-server \
		--timeout=90s
	@sleep 2
	@echo

broken: _setup
	$(kubectl) apply -nargocd -f $(tmp)/argocd.yaml
	sleep 5 # `kubectl wait` requires the resource to exist
	$(kubectl) wait -n argocd \
		--for=condition=Ready pod \
		--selector=app.kubernetes.io/name=argocd-server \
		--timeout=90s
	$(kubectl) apply --filename $(tmp)/argocd-secret.yaml
	@sleep 2
	@echo

test:
	touch $(jar)
	@echo

	$(curl) -Lo $(tmp)/login.html http://$(argo)/auth/login
	grep -o 'action="[^"]*"' < $(tmp)/login.html | cut -d\" -f2 | sed 's/&amp;/\&/g' > $(tmp)/path
	@echo

	$(curl) -D $(tmp)/header.log -XPOST -d "login=admin@example.com&password=password" "http://$(dex)$$(cat $(tmp)/path)"
	grep ^Location $(tmp)/header.log | cut -d' ' -f2 | tr -d '\r' > $(tmp)/endpoint
	@echo

	$(curl) -o /dev/null "$$(cat $(tmp)/endpoint)"
	@echo

	grep argocd.token $(jar) | cut -f7- | tee $(tmp)/token
	@echo

	@echo Token payload:
	(cut -d. -f2 < $(tmp)/token|tr -d '\n'; echo '===') | base64 -d | jq
	@echo

fix:
	$(kubectl) rollout restart -nargocd deployment
	$(kubectl) rollout restart -nargocd sts

_break:
	@head -c 12 /dev/random | base64 | base64 > $(tmp)/random-secret
break: _break
	$(kubectl) patch -nargocd secret argocd-client-secrets --type='json' -p='[{"op" : "replace" ,"path" : "/data/clientSecret" ,"value" : "$(shell cat $(tmp)/random-secret)"}]'
	$(kubectl) patch -ndex secret dex-client-secrets --type='json' -p='[{"op" : "replace" ,"path" : "/data/CLIENT_SECRET" ,"value" : "$(shell cat $(tmp)/random-secret)"}]'
	$(kubectl) rollout restart -ndex deployment

logs:
	$(kubectl) logs -nargocd -l app.kubernetes.io/name=argocd-server --since=1m
	$(kubectl) logs -ndex -l app.kubernetes.io/name=dex --since=1m
