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

APP_NAME=skillpulse

# =========================================
# LOCAL DEV (DOCKER COMPOSE)
# =========================================

.PHONY: up down restart clean logs logs-k8s build build-k8s load push deploy \
        ingress-install ingress-status ingress-apply ingress-low-resource \
        argocd-up argocd-bootstrap gitops-init \
        status pods svc nodes cluster-debug mysql

up:
	docker compose up -d --build || docker-compose up -d --build

down:
	docker compose down || docker-compose down

restart: down up

clean:
	docker compose down -v --remove-orphans || docker-compose down -v --remove-orphans
	docker system prune -f

# =========================================
# DOCKER BUILD (LOCAL IMAGE)
# =========================================

build:
	docker build -t $(APP_NAME) .

# =========================================
# K8S BUILD + PUSH
# =========================================

build-k8s:
	docker build -t $(BACKEND_IMAGE) ./backend
	docker build -t $(FRONTEND_IMAGE) ./frontend

load:
	kind load docker-image $(BACKEND_IMAGE) --name $(CLUSTER)
	kind load docker-image $(FRONTEND_IMAGE) --name $(CLUSTER)

push:
	docker push $(BACKEND_IMAGE)
	docker push $(FRONTEND_IMAGE)

# =========================================
# DEPLOY (KIND LOCAL CLUSTER)
# =========================================

deploy:
	kind create cluster --name $(CLUSTER) || true
	$(MAKE) build-k8s
	$(MAKE) load
	kubectl apply -f k8s/
	@echo "Cluster ready with tag $(TAG)"

# =========================================
# INGRESS
# =========================================

ingress-install:
	@echo "Labeling KIND node..."
	kubectl label node $(CLUSTER)-control-plane ingress-ready=true --overwrite

	@echo "Installing ingress-nginx..."
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.2/deploy/static/provider/kind/deploy.yaml

	kubectl wait --namespace ingress-nginx \
		--for=condition=ready pod \
		--selector=app.kubernetes.io/component=controller \
		--timeout=180s

ingress-low-resource:
	kubectl patch deployment ingress-nginx-controller \
		-n ingress-nginx \
		--type=json \
		-p='[{"op":"replace","path":"/spec/template/spec/containers/0/resources","value":{"requests":{"cpu":"50m","memory":"90Mi"},"limits":{"memory":"200Mi"}}}]'

	kubectl rollout restart deployment ingress-nginx-controller -n ingress-nginx

ingress-status:
	kubectl get pods -n ingress-nginx
	kubectl get svc -n ingress-nginx

ingress-apply:
	kubectl apply -f k8s/40-ingress.yaml

# =========================================
# ARGOCD (GITOPS)
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

gitops-init:
	$(MAKE) ingress-install
	$(MAKE) ingress-low-resource
	$(MAKE) argocd-up
	$(MAKE) argocd-bootstrap
	$(MAKE) ingress-apply

# =========================================
# STATUS / DEBUG
# =========================================

status:
	kubectl get pods,svc -n $(NAMESPACE)

pods:
	kubectl get pods -n $(NAMESPACE)

svc:
	kubectl get svc -n $(NAMESPACE)

nodes:
	kubectl get nodes

cluster-debug:
	kubectl get nodes
	kubectl describe node

logs:
	kubectl logs -n $(NAMESPACE) -l app --tail=50 -f

logs-k8s:
	kubectl logs -n $(NAMESPACE) -l app --tail=100 -f

# =========================================
# OPERATIONS
# =========================================

restart:
	kubectl rollout restart deployment/backend deployment/frontend -n $(NAMESPACE)

mysql:
	kubectl exec -it -n $(NAMESPACE) mysql-0 -- \
		mysql -uroot -prootpassword123 skillpulse

# =========================================
# CLEANUP (K8S)
# =========================================

clean-k8s:
	kind delete cluster --name $(CLUSTER)
