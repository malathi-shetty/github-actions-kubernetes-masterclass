# SkillPulse Kubernetes Platform Recovery Guide

## Cluster Info

Cluster Name:
skillpulse-cluster

Region:
us-west-2

Current Context:
arn:aws:eks:us-west-2:699938055664:cluster/skillpulse-cluster

## GitHub Repo

https://github.com/malathi-shetty/github-actions-kubernetes-masterclass

## Installed Components

* Kubernetes (EKS)
* ArgoCD
* Argo Rollouts
* Prometheus
* Grafana
* MySQL StatefulSet
* Frontend Deployment
* Backend Rollout
* Multi-environment namespaces:

  * skillpulse-dev
  * skillpulse-staging
  * skillpulse-prod

## Recovery Steps

1. Recreate EKS cluster
2. Install ArgoCD
3. Install Monitoring stack
4. Apply ArgoCD applications
5. ArgoCD auto-sync restores apps
