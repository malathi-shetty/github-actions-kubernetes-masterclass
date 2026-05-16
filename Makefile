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
# PHONY TARGETS
# =========================================

.PHONY: setup bootstrap install check build load push \
        apply deploy up status logs pods svc nodes restart mysql \
        down clean \
        argocd-up argocd-down argocd-status argocd-ui ingress gitops-sync

# =========================================
# HELP
# =========================================

help:
	@echo "================================="
	@echo "SkillPulse DevOps Automation"
	@echo "================================="
	@echo "make setup"
	@echo "make build"
	@echo "make deploy"
	@echo "make argocd-up"
	@echo "make gitops-sync"

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
	@echo "Installing ArgoCD..."
	kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
	kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	@echo "Waiting for ArgoCD pods..."
	kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
	@echo "ArgoCD Admin Password:"
	kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
	@echo ""

argocd-down:
	@echo "Deleting ArgoCD namespace..."
	kubectl delete namespace argocd

argocd-status:
	@echo "ArgoCD Status"
	kubectl get pods -n argocd
	kubectl get svc -n argocd
	kubectl get pods -n argocd -o wide

argocd-ui:
	@echo "Starting ArgoCD UI..."
	@echo "Open: https://localhost:8080"
	kubectl port-forward svc/argocd-server -n argocd 8080:443

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
# K8S DEPLOY (LEGACY - NOT USED IN GITOPS)
# =========================================

apply:
	@echo "Direct kubectl apply disabled in GitOps mode"

gitops-sync:
	@echo "================================="
	@echo "GITOPS MODE ACTIVE (ARGOCD)"
	@echo "================================="
	@echo "✔ CI builds image"
	@echo "✔ Pushes to DockerHub"
	@echo "✔ Updates Kubernetes manifests in Git"
	@echo "✔ ArgoCD auto-deploys changes"
	@echo ""
	@echo "No kubectl apply required"
	@echo "TTM reduced via automation pipeline"

# =========================================
# PIPELINES
# =========================================

deploy:
	kind create cluster --name $(CLUSTER) || true
	$(MAKE) build
	$(MAKE) load
	$(MAKE) status

up:
	$(MAKE) build
	kind create cluster --name $(CLUSTER)
	$(MAKE) load
	$(MAKE) ingress

# =========================================
# STATUS / DEBUG
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

# DEBUG (as you requested)
cluster-debug:
	@echo "Cluster Nodes"
	kubectl get nodes
	@echo ""
	@echo "Node Details"
	kubectl describe node

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
# INGRESS
# =========================================

ingress:
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.2/deploy/static/provider/kind/deploy.yaml

# =========================================
# CLEANUP
# =========================================

down:
	kind delete cluster --name $(CLUSTER)

clean:
	kind delete cluster --name $(CLUSTER)
