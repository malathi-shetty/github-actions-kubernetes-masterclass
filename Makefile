# =========================================
# SKILLPULSE DEVOPS (LEVEL 2 GITOPS)
# =========================================

SHELL := /bin/bash

CLUSTER   ?= skillpulse
NAMESPACE ?= skillpulse

TAG := $(shell git rev-parse --short HEAD)

DOCKERHUB_USERNAME ?= shettymalathi113

BACKEND_IMAGE  := $(DOCKERHUB_USERNAME)/skillpulse-backend:$(TAG)
FRONTEND_IMAGE := $(DOCKERHUB_USERNAME)/skillpulse-frontend:$(TAG)

.PHONY: up down restart clean build build-k8s load push deploy \
        argocd-up argocd-bootstrap gitops-init \
        status pods svc logs clean-k8s

# =========================
# LOCAL DEV
# =========================

up:
	docker compose up -d --build

down:
	docker compose down

restart: down up

clean:
	docker compose down -v --remove-orphans
	docker system prune -f

# =========================
# BUILD
# =========================

build-k8s:
	docker build -t $(BACKEND_IMAGE) ./backend
	docker build -t $(FRONTEND_IMAGE) ./frontend

load:
	kind load docker-image $(BACKEND_IMAGE) --name $(CLUSTER)
	kind load docker-image $(FRONTEND_IMAGE) --name $(CLUSTER)

push:
	docker push $(BACKEND_IMAGE)
	docker push $(FRONTEND_IMAGE)

# =========================
# GITOPS DEPLOY (NO MANUAL PATCHING)
# =========================

deploy:
	kind create cluster --name $(CLUSTER) || true
	$(MAKE) build-k8s
	$(MAKE) load
	kubectl apply -f k8s/
	@echo "GitOps Ready (ArgoCD will sync automatically)"

# =========================
# ARGOCD
# =========================

argocd-up:
	kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
	kubectl apply -n argocd \
	-f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

argocd-bootstrap:
	kubectl apply -f k8s/argocd/project.yaml
	kubectl apply -f k8s/argocd/application.yaml

gitops-init:
	$(MAKE) argocd-up
	$(MAKE) argocd-bootstrap

# =========================
# STATUS
# =========================

status:
	kubectl get pods,svc -n $(NAMESPACE)

pods:
	kubectl get pods -n $(NAMESPACE)

svc:
	kubectl get svc -n $(NAMESPACE)

logs:
	kubectl logs -n $(NAMESPACE) -l app --tail=100 -f

# =========================
# CLEAN
# =========================

clean-k8s:
	kind delete cluster --name $(CLUSTER)
