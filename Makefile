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

# commit-based tag (dynamic)
IMAGE_TAG := $(shell git rev-parse --short HEAD)

# docker username from login
DOCKERHUB_USERNAME := $(shell cat ~/.docker/config.json | jq -r '.auths | keys[0]' | cut -d'.' -f1)

ifeq ($(DOCKERHUB_USERNAME),null)
$(error Docker not logged in. Run: docker login)
endif


BACKEND_IMAGE  := $(DOCKERHUB_USERNAME)/skillpulse-backend:$(IMAGE_TAG)
FRONTEND_IMAGE := $(DOCKERHUB_USERNAME)/skillpulse-frontend:$(IMAGE_TAG)


# =========================================
# PHONY TARGETS (FULL COVERAGE)
# =========================================

.PHONY: \
	setup bootstrap install check \
	help \
	deploy up build load apply \
	status logs mysql \
	restart \
	pods svc nodes \
	down clean


# =========================================
# HELP
# =========================================

help:
	@echo "================================="
	@echo "SkillPulse DevOps Automation"
	@echo "================================="
	@echo ""
	@echo "setup      - full environment setup"
	@echo "bootstrap  - project structure"
	@echo "install    - install tools"
	@echo "check      - verify tools"
	@echo ""
	@echo "build      - build images"
	@echo "load       - load images into kind"
	@echo "apply      - deploy k8s"
	@echo "deploy     - full pipeline"
	@echo ""
	@echo "status     - cluster health"
	@echo "logs       - logs"
	@echo "pods       - pods"
	@echo "svc        - services"
	@echo "nodes      - nodes"
	@echo ""
	@echo "restart    - restart services"
	@echo "mysql      - mysql shell"
	@echo "down       - delete cluster"
	@echo "clean      - cleanup cluster"
	@echo ""


# =========================================
# SETUP / INSTALL
# =========================================

setup:
	@echo "================================="
	@echo "FULL ENV SETUP"
	@echo "================================="
	./bootstrap.sh
	./scripts/setup.sh


bootstrap:
	@echo "================================="
	@echo "BOOTSTRAP PROJECT"
	@echo "================================="
	./bootstrap.sh


install:
	@echo "================================="
	@echo "INSTALL TOOLCHAIN"
	@echo "================================="
	./scripts/setup.sh


check:
	@echo "================================="
	@echo "CHECK TOOLS"
	@echo "================================="
	docker --version
	kubectl version --client
	kind --version


# =========================================
# BUILD PIPELINE
# =========================================

build:
	@echo "================================="
	@echo "BUILD DOCKER IMAGES"
	@echo "================================="
	docker build -t $(BACKEND_IMAGE) ./backend
	docker build -t $(FRONTEND_IMAGE) ./frontend


load:
	@echo "================================="
	@echo "LOAD IMAGES INTO KIND"
	@echo "================================="
	kind load docker-image $(BACKEND_IMAGE) --name $(CLUSTER)
	kind load docker-image $(FRONTEND_IMAGE) --name $(CLUSTER)

ingress:
	@echo "Installing Ingress Controller"
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.2/deploy/static/provider/kind/deploy.yaml


# =========================================
# KUBERNETES DEPLOYMENT
# =========================================

apply:
	@echo "================================="
	@echo "DEPLOY K8S RESOURCES"
	@echo "================================="
	kubectl apply -f k8s/00-namespace.yaml \
	              -f k8s/10-mysql.yaml \
	              -f k8s/20-backend.yaml \
	              -f k8s/30-frontend.yaml

	kubectl rollout status statefulset/mysql -n $(NAMESPACE) --timeout=180s
	kubectl rollout status deployment/backend -n $(NAMESPACE) --timeout=120s
	kubectl rollout status deployment/frontend -n $(NAMESPACE) --timeout=60s

    kubectl apply -f k8s/40-ingress.yaml


# =========================================
# MAIN PIPELINES
# =========================================

deploy:
	@echo "================================="
	@echo "FULL DEPLOY PIPELINE"
	@echo "================================="
	kind create cluster --name $(CLUSTER) || true
	$(MAKE) build
	$(MAKE) load
	$(MAKE) apply
	$(MAKE) status


up:
	@echo "================================="
	@echo "UP STACK"
	@echo "================================="
	$(MAKE) build
	kind create cluster --name $(CLUSTER)
	$(MAKE) load
	$(MAKE) apply
	$(MAKE) ingress

# =========================================
# MONITORING
# =========================================

status:
	@echo "================================="
	@echo "CLUSTER STATUS"
	@echo "================================="
	kubectl get pods,svc,endpoints -n $(NAMESPACE)


logs:
	@echo "================================="
	@echo "STREAM LOGS"
	@echo "================================="
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
	@echo "================================="
	@echo "RESTART SERVICES"
	@echo "================================="
	$(MAKE) build
	$(MAKE) load
	kubectl rollout restart deployment/backend deployment/frontend -n $(NAMESPACE)


mysql:
	@echo "================================="
	@echo "MYSQL SHELL"
	@echo "================================="
	kubectl exec -it -n $(NAMESPACE) mysql-0 -- mysql -u$(DB_USER) -p$(DB_PASSWORD) skillpulse


# =========================================
# CLEANUP
# =========================================

down:
	@echo "================================="
	@echo "DELETE CLUSTER"
	@echo "================================="
	kind delete cluster --name $(CLUSTER)


clean:
	@echo "================================="
	@echo "CLEAN ENV"
	@echo "================================="
	kind delete cluster --name $(CLUSTER)
