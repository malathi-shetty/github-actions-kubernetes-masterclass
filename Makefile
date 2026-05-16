# =========================================
# SKILLPULSE DEVOPS AUTOMATION
# Reduce Time To Market (TTM)
# =========================================

SHELL := /bin/bash


# =========================================
# ENVIRONMENT CONFIGURATION
# =========================================

CLUSTER           ?= skillpulse
NAMESPACE         ?= skillpulse

BACKEND_IMAGE     ?= trainwithshubham/skillpulse-backend:latest
FRONTEND_IMAGE    ?= trainwithshubham/skillpulse-frontend:latest


# =========================================
# PHONY TARGETS
# =========================================

.PHONY: \
	setup \
	bootstrap \
	install \
	check \
	help \
	deploy \
	up \
	build \
	load \
	apply \
	down \
	status \
	logs \
	mysql \
	restart \
	pods \
	svc \
	nodes \
	clean


# =========================================
# HELP MENU
# =========================================

help:
	@echo "================================="
	@echo "SkillPulse DevOps Automation"
	@echo "================================="
	@echo
	@echo "make setup      - Full environment setup"
	@echo "make bootstrap  - Create project structure"
	@echo "make install    - Install Docker, kubectl, kind"
	@echo "make check      - Verify installed tools"
	@echo
	@echo "make build      - Build Docker images"
	@echo "make load       - Load images into kind cluster"
	@echo "make apply      - Deploy Kubernetes manifests"
	@echo "make deploy     - Complete deployment pipeline"
	@echo
	@echo "make status     - Check cluster resources"
	@echo "make logs       - Stream application logs"
	@echo "make pods       - View running pods"
	@echo "make svc        - View services"
	@echo "make nodes      - View cluster nodes"
	@echo
	@echo "make restart    - Restart deployments"
	@echo "make mysql      - Open MySQL shell"
	@echo "make down       - Delete kind cluster"
	@echo "make clean      - Cleanup Kubernetes environment"
	@echo


# =========================================
# ENVIRONMENT AUTOMATION
# =========================================

setup:
	@echo "================================="
	@echo "Starting Full Environment Setup"
	@echo "================================="

	./bootstrap.sh
	./scripts/setup.sh

	@echo
	@echo "Environment setup completed"
	@echo


bootstrap:
	@echo "================================="
	@echo "Bootstrapping Project Structure"
	@echo "================================="

	./bootstrap.sh

	@echo
	@echo "Bootstrap completed"
	@echo


install:
	@echo "================================="
	@echo "Installing DevOps Toolchain"
	@echo "================================="

	./scripts/setup.sh

	@echo
	@echo "Installation completed"
	@echo


check:
	@echo "================================="
	@echo "Checking Installed Tools"
	@echo "================================="

	docker --version
	kubectl version --client
	kind --version

	@echo
	@echo "Tool validation completed"
	@echo


# =========================================
# KUBERNETES DEPLOYMENT PIPELINE
# =========================================

deploy:
	@echo "================================="
	@echo "Starting Full Deployment Pipeline"
	@echo "================================="

	kind create cluster --config k8s/kind-config.yaml --name $(CLUSTER) || true

	$(MAKE) build
	$(MAKE) load
	$(MAKE) apply
	$(MAKE) status

	@echo
	@echo "SkillPulse deployment completed"
	@echo


up:
	@echo "================================="
	@echo "Launching Complete Application Stack"
	@echo "================================="

	$(MAKE) build

	kind create cluster \
		--config k8s/kind-config.yaml \
		--name $(CLUSTER)

	$(MAKE) load
	$(MAKE) apply

	@echo
	@echo "SkillPulse is live at:"
	@echo "http://localhost:8888"
	@echo


# =========================================
# DOCKER IMAGE OPERATIONS
# =========================================

build:
	@echo "================================="
	@echo "Building Docker Images"
	@echo "================================="

	docker build -t $(BACKEND_IMAGE) ./backend
	docker build -t $(FRONTEND_IMAGE) ./frontend

	@echo
	@echo "Docker image build completed"
	@echo


load:
	@echo "================================="
	@echo "Loading Images Into kind Cluster"
	@echo "================================="

	kind load docker-image $(BACKEND_IMAGE) --name $(CLUSTER)
	kind load docker-image $(FRONTEND_IMAGE) --name $(CLUSTER)

	@echo
	@echo "Docker images loaded into cluster"
	@echo


# =========================================
# KUBERNETES RESOURCE DEPLOYMENT
# =========================================

apply:
	@echo "================================="
	@echo "Deploying Kubernetes Resources"
	@echo "================================="

	kubectl apply -f k8s/00-namespace.yaml \
	              -f k8s/10-mysql.yaml \
	              -f k8s/20-backend.yaml \
	              -f k8s/30-frontend.yaml

	@echo
	@echo "Waiting for rollout completion..."
	@echo

	kubectl rollout status statefulset/mysql   -n $(NAMESPACE) --timeout=180s
	kubectl rollout status deployment/backend  -n $(NAMESPACE) --timeout=120s
	kubectl rollout status deployment/frontend -n $(NAMESPACE) --timeout=60s

	@echo
	@echo "Kubernetes deployment completed"
	@echo


# =========================================
# CLUSTER MANAGEMENT
# =========================================

down:
	@echo "================================="
	@echo "Deleting kind Cluster"
	@echo "================================="

	kind delete cluster --name $(CLUSTER)

	@echo
	@echo "Cluster deletion completed"
	@echo


clean:
	@echo "================================="
	@echo "Cleaning Kubernetes Environment"
	@echo "================================="

	kind delete cluster --name $(CLUSTER)

	@echo
	@echo "Environment cleanup completed"
	@echo


# =========================================
# MONITORING AND OBSERVABILITY
# =========================================

status:
	@echo "================================="
	@echo "Checking Cluster Health"
	@echo "================================="

	kubectl get pods,svc,endpoints -n $(NAMESPACE)

	@echo
	@echo "Cluster status check completed"
	@echo


logs:
	@echo "================================="
	@echo "Streaming Application Logs"
	@echo "================================="

	kubectl logs \
		-n $(NAMESPACE) \
		-l 'app in (mysql,backend,frontend)' \
		--all-containers \
		--tail=50 \
		-f \
		--max-log-requests=10


pods:
	@echo "================================="
	@echo "Viewing Kubernetes Pods"
	@echo "================================="

	kubectl get pods -n $(NAMESPACE)


svc:
	@echo "================================="
	@echo "Viewing Kubernetes Services"
	@echo "================================="

	kubectl get svc -n $(NAMESPACE)


nodes:
	@echo "================================="
	@echo "Viewing Cluster Nodes"
	@echo "================================="

	kubectl get nodes


# =========================================
# APPLICATION OPERATIONS
# =========================================

restart:
	@echo "================================="
	@echo "Restarting Application Deployments"
	@echo "================================="

	$(MAKE) build
	$(MAKE) load

	kubectl rollout restart \
		deployment/backend \
		deployment/frontend \
		-n $(NAMESPACE)

	kubectl rollout status deployment/backend  -n $(NAMESPACE) --timeout=120s
	kubectl rollout status deployment/frontend -n $(NAMESPACE) --timeout=60s

	@echo
	@echo "Application restart completed"
	@echo


mysql:
	@echo "================================="
	@echo "Opening MySQL Shell"
	@echo "================================="

	kubectl exec -it \
		-n $(NAMESPACE) \
		mysql-0 \
		-- mysql -uskillpulse -pskillpulse123 skillpulse
