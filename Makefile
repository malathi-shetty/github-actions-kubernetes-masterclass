# =========================================
# SKILLPULSE DEVOPS AUTOMATION
# GitOps + ArgoCD + Kubernetes + CI/CD
# =========================================

SHELL := /bin/bash

# =========================================
# CONFIGURATION
# =========================================

CLUSTER   ?= skillpulse
NAMESPACE ?= skillpulse

TAG := $(shell git rev-parse --short HEAD)

DOCKERHUB_USERNAME ?=
ifeq ($(DOCKERHUB_USERNAME),)
$(error DOCKERHUB_USERNAME is not set. export DOCKERHUB_USERNAME=yourname)
endif

BACKEND_IMAGE  := $(DOCKERHUB_USERNAME)/skillpulse-backend:$(TAG)
FRONTEND_IMAGE := $(DOCKERHUB_USERNAME)/skillpulse-frontend:$(TAG)

# =========================================
# PHONY TARGETS
# =========================================

.PHONY: setup bootstrap install check \
        build load push \
        argocd-up argocd-down argocd-status argocd-ui argocd-app \
        ingress-controller ingress-apply \
        gitops-init gitops-status \
        status logs pods svc nodes \
        restart mysql \
        down clean

# =========================================
# HELP
# =========================================

help:
	@echo "================================="
	@echo "SkillPulse DevOps Automation"
	@echo "================================="
	@echo "make setup"
	@echo "make build"
	@echo "make gitops-init"
	@echo "make gitops-status"

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
# BUILD & PUSH
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
# ARGOCD (GITOPS CORE)
# =========================================

argocd-up:
	@echo "Installing ArgoCD..."
	kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
	kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
	@echo "ArgoCD Admin Password:"
	kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
	@echo ""

argocd-down:
	kubectl delete namespace argocd

argocd-status:
	kubectl get pods -n argocd
	kubectl get svc -n argocd
	kubectl get pods -n argocd -o wide

argocd-ui:
	@echo "Open: https://localhost:8080"
	kubectl port-forward svc/argocd-server -n argocd 8080:443

argocd-app:
	kubectl apply -f k8s/argocd/application.yaml

# =========================================
# INGRESS (CLEAR SEPARATION)
# =========================================

ingress-controller:
	@echo "Installing NGINX Ingress Controller..."
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.2/deploy/static/provider/kind/deploy.yaml

ingress-apply:
	@echo "Applying application ingress..."
	kubectl apply -f k8s/ingress.yaml

# =========================================
# GITOPS FLOW
# =========================================

gitops-init:
	@echo "================================="
	@echo "BOOTSTRAPPING GITOPS STACK"
	@echo "================================="
	$(MAKE) argocd-up
	$(MAKE) argocd-app
	$(MAKE) ingress-controller
	$(MAKE) ingress-apply
	$(MAKE) argocd-status

gitops-status:
	@echo "Checking ArgoCD applications..."
	kubectl get applications -n argocd || true
	@echo ""
	@echo "Cluster status:"
	kubectl get pods -n $(NAMESPACE)

# =========================================
# DEBUG / MONITORING
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

cluster-debug:
	@echo "Nodes:"
	kubectl get nodes
	@echo ""
	@echo "Details:"
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
# CLEANUP
# =========================================

down:
	kind delete cluster --name $(CLUSTER)

clean:
	kind delete cluster --name $(CLUSTER)
