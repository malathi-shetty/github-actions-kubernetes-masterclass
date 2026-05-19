# SkillPulse Platform Architecture

## Overview

SkillPulse is deployed on Amazon EKS using GitOps principles with ArgoCD.

The platform contains:

* Frontend application
* Backend API
* MySQL database
* Monitoring stack
* Progressive delivery using Argo Rollouts

---

# Core Components

## Kubernetes Cluster

Platform:

* Amazon EKS

Region:

* us-west-2

Cluster:

* skillpulse-cluster

---

# Namespaces

## skillpulse-dev

Development environment.

## skillpulse-staging

Pre-production validation environment.

## skillpulse-prod

Production environment.

## monitoring

Grafana + Prometheus monitoring stack.

## argocd

GitOps deployment controller.

---

# CI/CD Flow

GitHub Push
→ GitHub Actions
→ Docker Build
→ DockerHub Push
→ ArgoCD detects manifest changes
→ Kubernetes syncs automatically

---

# Deployment Strategy

Backend:

* Argo Rollouts Canary deployment

Frontend:

* Kubernetes Deployment

Database:

* MySQL StatefulSet with Persistent Volume

---

# Monitoring Stack

## Prometheus

Collects:

* cluster metrics
* pod metrics
* node metrics

## Grafana

Visualizes:

* CPU
* memory
* pod health
* Kubernetes dashboards

---

# Storage

MySQL uses:

* PersistentVolumeClaim
* AWS EBS CSI Driver

StorageClass:

* gp2

---

# Networking

Services:

* ClusterIP services internally

Ingress:

* NGINX Ingress for production access

---

# GitOps

ArgoCD continuously syncs:

* manifests
* rollouts
* services
* configmaps
* secrets

Source of truth:
GitHub repository

---

# Disaster Recovery

Recovery sources:

* Git repository
* Kubernetes manifests
* ArgoCD application configs
* Monitoring configs

Cluster can be rebuilt from GitOps manifests.
