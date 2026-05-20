# =========================================
# SKILLPULSE DEVOPS PLATFORM (GITOPS)
# =========================================

SHELL := /bin/bash

# =========================================
# VARIABLES
# =========================================

CLUSTER              ?= skillpulse
NAMESPACE            ?= skillpulse-prod
MONITORING_NAMESPACE ?= monitoring

DOCKERHUB_USERNAME   ?= shettymalathi113

TAG := $(shell git rev-parse --short HEAD)

BACKEND_IMAGE  := $(DOCKERHUB_USERNAME)/skillpulse-backend:$(TAG)
FRONTEND_IMAGE := $(DOCKERHUB_USERNAME)/skillpulse-frontend:$(TAG)

# =========================================
# PHONY
# =========================================

.PHONY: help up down restart clean \
	cluster-up cluster-down cluster-info \
	bootstrap-argocd gitops-init \
	build-k8s push load \
	deploy destroy \
	argocd-up argocd-bootstrap \
	helm-install helm-version \
	monitoring-install monitoring-delete \
	status pods svc ingress nodes \
	logs backend-logs frontend-logs mysql-logs \
	restart-backend restart-frontend \
	argocd-port-forward argocd-password \
	grafana-port-forward grafana-password \
	metrics-install metrics-status top-pods top-nodes

# =========================================
# HELP
# =========================================

help:
	@echo ""
	@echo "========== SKILLPULSE DEVOPS =========="
	@echo ""
	@echo "LOCAL:"
	@echo "  make up"
	@echo "  make down"
	@echo "  make restart"
	@echo ""
	@echo "BOOTSTRAP (ONE TIME ONLY):"
	@echo "  make cluster-up"
	@echo "  make bootstrap-argocd"
	@echo ""
	@echo "GITOPS RULE:"
	@echo "  👉 ONLY use git push for deployment"
	@echo ""

# =========================================
# LOCAL DEV
# =========================================

up:
	docker compose up -d --build

down:
	docker compose down

restart: down up

clean:
	docker compose down -v --remove-orphans
	docker system prune -f

# =========================================
# KIND CLUSTER (BOOTSTRAP ONLY)
# =========================================

cluster-up:
	kind create cluster --name $(CLUSTER) || true
	kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
	kubectl create namespace $(NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -

cluster-down:
	kind delete cluster --name $(CLUSTER)

cluster-info:
	kubectl cluster-info

# =========================================
# ARGOCD
# =========================================

argocd-up:
	kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
	kubectl apply -n argocd \
		-f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

argocd-bootstrap:
	kubectl apply -f k8s/argocd/application.yaml

gitops-init:
	$(MAKE) argocd-up
	$(MAKE) argocd-bootstrap

argocd-port-forward:
	kubectl port-forward svc/argocd-server -n argocd 8080:443

argocd-password:
	@kubectl get secret argocd-initial-admin-secret \
		-n argocd \
		-o jsonpath="{.data.password}" | base64 --decode
	@echo ""

# =========================================
# DOCKER
# =========================================

build-k8s:
	docker build -t $(BACKEND_IMAGE) ./backend
	docker build -t $(FRONTEND_IMAGE) ./frontend

push:
	docker push $(BACKEND_IMAGE)
	docker push $(FRONTEND_IMAGE)

load:
	kind load docker-image $(BACKEND_IMAGE) --name $(CLUSTER)
	kind load docker-image $(FRONTEND_IMAGE) --name $(CLUSTER)

# =========================================
# KUBERNETES (GITOPS SAFE)
# =========================================

deploy:
	@echo "❌ GitOps enabled"
	@echo "👉 DO NOT deploy manually"
	@echo "👉 Use: git push (ArgoCD handles everything)"

destroy:
	kubectl delete -f k8s/ --ignore-not-found=true

# =========================================
# HELM
# =========================================

helm-install:
	@if ! command -v helm >/dev/null 2>&1; then \
		curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash; \
	else \
		echo "Helm already installed"; \
	fi

helm-version:
	helm version

# =========================================
# MONITORING
# =========================================

monitoring-install: helm-install
	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || true
	helm repo update

	kubectl create namespace $(MONITORING_NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -

	helm upgrade --install monitoring \
		prometheus-community/kube-prometheus-stack \
		-n $(MONITORING_NAMESPACE)

monitoring-delete:
	helm uninstall monitoring -n $(MONITORING_NAMESPACE)

grafana-port-forward:
	kubectl port-forward --address 0.0.0.0 svc/monitoring-grafana 3000:80 -n $(MONITORING_NAMESPACE)

grafana-password:
	@kubectl get secret monitoring-grafana \
		-n $(MONITORING_NAMESPACE) \
		-o jsonpath="{.data.admin-password}" | base64 --decode
	@echo ""

# =========================================
# STATUS
# =========================================

status:
	kubectl get all -n $(NAMESPACE)

pods:
	kubectl get pods -n $(NAMESPACE)

svc:
	kubectl get svc -n $(NAMESPACE)

ingress:
	kubectl get ingress -n $(NAMESPACE)

nodes:
	kubectl get nodes

# =========================================
# LOGS
# =========================================

logs:
	kubectl logs -n $(NAMESPACE) -l app --tail=100 -f

backend-logs:
	kubectl logs deployment/backend -n $(NAMESPACE) --tail=100 -f

frontend-logs:
	kubectl logs deployment/frontend -n $(NAMESPACE) --tail=100 -f

mysql-logs:
	kubectl logs statefulset/mysql -n $(NAMESPACE) --tail=100 -f

# =========================================
# RESTARTS
# =========================================

restart-backend:
	kubectl rollout restart deployment/backend -n $(NAMESPACE)

restart-frontend:
	kubectl rollout restart deployment/frontend -n $(NAMESPACE)

# =========================================
# METRICS
# =========================================

metrics-install:
	kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

metrics-status:
	kubectl get pods -n kube-system | grep metrics

top-pods:
	kubectl top pods -A

top-nodes:
	kubectl top nodes
