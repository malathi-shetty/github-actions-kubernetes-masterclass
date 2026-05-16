# =========================================
# SKILLPULSE DEVOPS PLATFORM (GITOPS)
# =========================================

SHELL := /bin/bash

# =========================================
# VARIABLES
# =========================================

CLUSTER ?= skillpulse

NAMESPACE ?= skillpulse
MONITORING_NAMESPACE ?= monitoring

DOCKERHUB_USERNAME ?= shettymalathi113

TAG := $(shell git rev-parse --short HEAD)

BACKEND_IMAGE  := $(DOCKERHUB_USERNAME)/skillpulse-backend:$(TAG)
FRONTEND_IMAGE := $(DOCKERHUB_USERNAME)/skillpulse-frontend:$(TAG)

# =========================================
# PHONY
# =========================================

.PHONY: help up down restart clean \
	build-k8s push load deploy destroy \
	argocd-up argocd-bootstrap gitops-init \
	monitoring-install monitoring-delete \
	status pods svc ingress nodes \
	logs backend-logs frontend-logs mysql-logs \
	restart-backend restart-frontend \
	argocd-password grafana-password \
	argocd-port-forward grafana-port-forward \
	cluster-info clean-k8s

# =========================================
# HELP
# =========================================

help:
	@echo ""
	@echo "========== SKILLPULSE DEVOPS =========="
	@echo ""
	@echo "Local Development:"
	@echo "  make up"
	@echo "  make down"
	@echo "  make restart"
	@echo ""
	@echo "Docker:"
	@echo "  make build-k8s"
	@echo "  make push"
	@echo ""
	@echo "Kubernetes:"
	@echo "  make deploy"
	@echo "  make destroy"
	@echo "  make status"
	@echo "  make pods"
	@echo "  make svc"
	@echo "  make ingress"
	@echo ""
	@echo "ArgoCD:"
	@echo "  make argocd-up"
	@echo "  make gitops-init"
	@echo "  make argocd-port-forward"
	@echo "  make argocd-password"
	@echo ""
	@echo "Monitoring:"
	@echo "  make monitoring-install"
	@echo "  make monitoring-delete"
	@echo "  make grafana-port-forward"
	@echo "  make grafana-password"
	@echo ""
	@echo "Logs:"
	@echo "  make backend-logs"
	@echo "  make frontend-logs"
	@echo "  make mysql-logs"
	@echo ""
	@echo "Restart:"
	@echo "  make restart-backend"
	@echo "  make restart-frontend"
	@echo ""
	@echo "Cleanup:"
	@echo "  make clean"
	@echo "  make clean-k8s"
	@echo ""

# =========================================
# LOCAL DEVELOPMENT
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
# KIND CLUSTER
# =========================================

cluster-create:
	kind create cluster --name $(CLUSTER) || true

cluster-info:
	kubectl cluster-info

clean-k8s:
	kind delete cluster --name $(CLUSTER)

# =========================================
# DOCKER BUILD
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
# KUBERNETES DEPLOYMENT
# =========================================

deploy:
	$(MAKE) cluster-create
	kubectl create namespace $(NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -
	$(MAKE) build-k8s
	$(MAKE) load
	kubectl apply -f k8s/
	@echo ""
	@echo "SkillPulse deployed successfully"
	@echo "ArgoCD auto-sync enabled"
	@echo ""

destroy:
	kubectl delete -f k8s/ --ignore-not-found=true

# =========================================
# ARGOCD
# =========================================

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

argocd-port-forward:
	kubectl port-forward svc/argocd-server \
	-n argocd 8080:443

argocd-password:
	@echo ""
	@echo "ArgoCD Admin Password:"
	@kubectl get secret argocd-initial-admin-secret \
	-n argocd \
	-o jsonpath="{.data.password}" | base64 --decode
	@echo ""


# =========================================
# HELM
# =========================================

helm-install:
	@if ! command -v helm >/dev/null 2>&1; then \
		echo "Installing Helm..."; \
		curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash; \
	else \
		echo "Helm already installed"; \
	fi

helm-version:
	helm version

# =========================================
# MONITORING (PROMETHEUS + GRAFANA)
# =========================================

monitoring-install: helm-install
	helm repo add prometheus-community \
	https://prometheus-community.github.io/helm-charts || true

	helm repo update

	kubectl create namespace $(MONITORING_NAMESPACE) \
	--dry-run=client -o yaml | kubectl apply -f -

	helm upgrade --install monitoring \
	prometheus-community/kube-prometheus-stack \
	-n $(MONITORING_NAMESPACE)

monitoring-delete:
	helm uninstall monitoring -n $(MONITORING_NAMESPACE)

grafana-port-forward:
	kubectl port-forward svc/monitoring-grafana \
	3000:80 -n $(MONITORING_NAMESPACE)

grafana-password:
	@echo ""
	@echo "Grafana Admin Password:"
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
# ROLLING RESTARTS
# =========================================

restart-backend:
	kubectl rollout restart deployment/backend -n $(NAMESPACE)

restart-frontend:
	kubectl rollout restart deployment/frontend -n $(NAMESPACE)
