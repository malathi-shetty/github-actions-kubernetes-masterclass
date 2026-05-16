# =========================================
# SKILLPULSE DEVOPS AUTOMATION
# =========================================

SHELL := /bin/bash

CLUSTER   ?= skillpulse
NAMESPACE ?= skillpulse

TAG := $(shell git rev-parse --short HEAD)

DOCKERHUB_USERNAME ?= shettymalathi113

BACKEND_IMAGE  := $(DOCKERHUB_USERNAME)/skillpulse-backend:$(TAG)
FRONTEND_IMAGE := $(DOCKERHUB_USERNAME)/skillpulse-frontend:$(TAG)

.PHONY: build load push deploy up status logs pods svc nodes restart mysql \
        ingress-install ingress-status ingress-apply ingress-low-resource \
        argocd-up argocd-bootstrap gitops-init clean cluster-debug

# =========================================
# HELP
# =========================================

help:
	@echo "make build"
	@echo "make deploy"
	@echo "make ingress-install"
	@echo "make ingress-apply"
	@echo "make argocd-up"
	@echo "make argocd-bootstrap"

# =========================================
# BUILD / IMAGE
# =========================================

build:
	docker build -t $(BACKEND_IMAGE) ./backend
	docker build -t $(FRONTEND_IMAGE) ./frontend

load:
	kind load docker-image $(BACKEND_IMAGE) --name $(CLUSTER)
	kind load docker-image $(FRONTEND_IMAGE) --name $(CLUSTER)

push:
	docker push $(BACKEND_IMAGE)
	docker push $(FRONTEND_IMAGE)

# =========================================
# DEPLOY (LOCAL TEST ONLY)
# =========================================

deploy:
	kind create cluster --name $(CLUSTER) || true
	$(MAKE) build
	$(MAKE) load
	@echo "Cluster ready"

# =========================================
# INGRESS
# =========================================

# =========================================
# INGRESS
# =========================================

ingress-install:
	@echo "Labeling KIND control-plane node for ingress..."
	kubectl label node $(CLUSTER)-control-plane ingress-ready=true --overwrite

	@echo "Installing ingress-nginx..."
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.2/deploy/static/provider/kind/deploy.yaml

# =========================================
# OPTIONAL:
# Reduce ingress-nginx resource usage
# Useful for tiny EC2 instances
# =========================================

ingress-low-resource:
	kubectl patch deployment ingress-nginx-controller \
		-n ingress-nginx \
		--type='json' \
		-p='[
			{
				"op":"replace",
				"path":"/spec/template/spec/containers/0/resources",
				"value":{
					"requests":{
						"cpu":"50m",
						"memory":"90Mi"
					},
					"limits":{
						"memory":"200Mi"
					}
				}
			}
		]'

	@echo "Waiting for ingress controller..."
	kubectl wait --namespace ingress-nginx \
		--for=condition=ready pod \
		--selector=app.kubernetes.io/component=controller \
		--timeout=180s

ingress-status:
	kubectl get pods -n ingress-nginx
	kubectl get svc -n ingress-nginx

ingress-apply:
	kubectl apply -f k8s/40-ingress.yaml

# =========================================
# ARGOCD
# =========================================

argocd-up:
	kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

	kubectl apply --server-side -n argocd \
		-f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

	kubectl wait \
		--for=condition=Ready \
		pod \
		-l app.kubernetes.io/name=argocd-server \
		-n argocd \
		--timeout=300s

argocd-bootstrap:
	kubectl apply -f k8s/argocd/project.yaml
	kubectl apply -f k8s/argocd/application.yaml

# =========================================
# FULL GITOPS BOOTSTRAP
# =========================================

gitops-init:
	$(MAKE) argocd-up
	$(MAKE) ingress-install
	$(MAKE) ingress-apply
	$(MAKE) argocd-bootstrap
	$(MAKE) ingress-low-resource

# =========================================
# STATUS
# =========================================

status:
	kubectl get pods,svc -n $(NAMESPACE)

logs:
	kubectl logs -n $(NAMESPACE) -l app --tail=50 -f

pods:
	kubectl get pods -n $(NAMESPACE)

svc:
	kubectl get svc -n $(NAMESPACE)

nodes:
	kubectl get nodes

cluster-debug:
	kubectl get nodes
	kubectl describe node

# =========================================
# OPERATIONS
# =========================================

restart:
	kubectl rollout restart deployment/backend deployment/frontend -n $(NAMESPACE)

mysql:
	kubectl exec -it -n $(NAMESPACE) mysql-0 -- \
		mysql -uroot -prootpassword123 skillpulse

# =========================================
# CLEANUP
# =========================================

clean:
	kind delete cluster --name $(CLUSTER)
