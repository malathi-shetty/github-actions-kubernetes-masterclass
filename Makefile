# =========================================
# SKILLPULSE DEVOPS AUTOMATION
# Reduce Time To Market (TTM)
# =========================================

SHELL := /bin/bash

# =========================================
# CONFIGURATION
# =========================================

CLUSTER   ?= skillpulse
NAMESPACE ?= skillpulse

TAG := $(shell git rev-parse --short HEAD)

DOCKERHUB_USERNAME := $(shell cat ~/.docker/config.json | jq -r '.auths | keys[0]' | cut -d'.' -f1)

ifeq ($(DOCKERHUB_USERNAME),null)
$(error Docker not logged in. Run: docker login)
endif

BACKEND_IMAGE  := $(DOCKERHUB_USERNAME)/skillpulse-backend:$(TAG)
FRONTEND_IMAGE := $(DOCKERHUB_USERNAME)/skillpulse-frontend:$(TAG)

# =========================================
# PHONY
# =========================================

.PHONY: setup bootstrap install check build load apply deploy up status logs pods svc nodes restart mysql down clean argocd-up argocd-down argocd-status ingress

# =========================================
# HELP
# =========================================

help:
	@echo "SkillPulse DevOps Automation"
	@echo "make setup"
	@echo "make build"
	@echo "make deploy"
	@echo "make argocd-up"

# =========================================
# SETUP
# =========================================

setup:
	./bootstrap.sh
	./scripts/setup.sh

bootstrap:
	./bootstrap.sh

install:
	./scripts/setup.sh

check:
	docker --version
	kubectl version --client
	kind version

# =========================================
# ARGOCD
# =========================================

argocd-up:
	@echo "🚀 Installing ArgoCD..."
	kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
	kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	@echo "⏳ Waiting for ArgoCD..."
	kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s
	@echo "🔐 Password:"
	kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
	@echo ""
	@echo "kubectl port-forward svc/argocd-server -n argocd 8080:443"

argocd-down:
	kubectl delete namespace argocd

argocd-status:
	kubectl get pods -n argocd

# =========================================
# BUILD
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
# K8S DEPLOY
# =========================================

apply:
	kubectl apply -f k8s/00-namespace.yaml
	kubectl apply -f k8s/10-mysql.yaml
	kubectl apply -f k8s/20-backend.yaml
	kubectl apply -f k8s/30-frontend.yaml

	kubectl rollout status statefulset/mysql -n $(NAMESPACE) --timeout=180s
	kubectl rollout status deployment/backend -n $(NAMESPACE) --timeout=120s
	kubectl rollout status deployment/frontend -n $(NAMESPACE) --timeout=60s

ingress:
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.2/deploy/static/provider/kind/deploy.yaml

# =========================================
# PIPELINES
# =========================================

deploy:
	kind create cluster --name $(CLUSTER) || true
	$(MAKE) build
	$(MAKE) load
	$(MAKE) apply
	$(MAKE) status

up:
	$(MAKE) build
	kind create cluster --name $(CLUSTER)
	$(MAKE) load
	$(MAKE) apply
	$(MAKE) ingress

# =========================================
# STATUS
# =========================================

status:
	kubectl get pods,svc,endpoints -n $(NAMESPACE)

logs:
	kubectl logs -n $(NAMESPACE) -l app --tail=50 -f

pods:
	kubectl get pods -n $(NAMESPACE)

svc:
	kubectl get svc -n $(NAMESPACE)

nodes:
	kubectl get nodes

# =========================================
# OPERATIONS
# =========================================

restart:
	$(MAKE) build
	$(MAKE) load
	kubectl rollout restart deployment/backend deployment/frontend -n $(NAMESPACE)

mysql:
	kubectl exec -it -n $(NAMESPACE) mysql-0 -- mysql -uroot -prootpassword123 skillpulse

# =========================================
# CLEANUP
# =========================================

down:
	kind delete cluster --name $(CLUSTER)

clean:
	kind delete cluster --name $(CLUSTER)
