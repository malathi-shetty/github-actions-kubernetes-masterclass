# SkillPulse — End-to-End DevOps, GitOps & Kubernetes Platform

SkillPulse is a production-style DevOps platform demonstrating a complete CI/CD + GitOps + Kubernetes workflow using modern cloud-native tooling.

This repository showcases:

- GitHub Actions CI/CD
- Docker Build Pipelines
- Kubernetes Deployments
- Argo Rollouts Canary Deployments
- GitOps Automation
- Security Scanning
- AIOps Reporting
- Prometheus + Grafana Monitoring
- ArgoCD Continuous Delivery
- EC2-based Infrastructure

Built as part of the TrainWithShubham DevOps Masterclass.

---

# Project Goal

The purpose of this project is not just building an application.

The real objective is demonstrating how modern DevOps teams:

- automate deployments
- monitor systems
- manage infrastructure
- perform secure releases
- implement GitOps workflows
- deploy Kubernetes workloads
- visualize platform health

using real-world tooling and automation pipelines.

---

#  Architecture Overview

```text
Developer Push
      │
      ▼
GitHub Actions CI Pipeline
      │
      ├── Detect Services
      ├── Security Scan
      ├── Build Backend
      ├── Build Frontend
      ├── Push Docker Images
      ├── Generate AIOps Report
      ▼
GitOps Update
      │
      ▼
ArgoCD Sync
      │
      ▼
Kubernetes Cluster (EC2)
      │
 ┌────┼─────┐
 ▼    ▼     ▼
Frontend Backend MySQL
      │
      ▼
Prometheus + Grafana Monitoring
````

---

# CI/CD Pipeline Flow

```text
detect-services
        │
        ▼
security-scan
      /     \
     ▼       ▼
 backend   frontend
      \     /
       ▼   ▼
    aiops-report
          │
          ▼
       approval
          │
          ▼
        gitops
          │
          ▼
   deploy-dashboard
```

---

# Platform Access

| Service             | URL / Port           |
| ------------------- | -------------------- |
| SkillPulse Frontend | http://<EC2-IP>:8888 |
| Backend API         | http://<EC2-IP>:8081 |
| ArgoCD UI           | http://<EC2-IP>:8080 |
| Grafana Dashboard   | http://<EC2-IP>:4000 |
| Prometheus          | http://<EC2-IP>:9090 |
| AIOps Dashboard     | http://<EC2-IP>:8090 |

---

# Important Note About Exposure

The current project exposes services temporarily using:

```bash
kubectl port-forward
```

This approach is intended for:

* learning
* demos
* testing
* local development

Production environments should use:

* Ingress Controllers
* Load Balancers
* HTTPS
* Authentication
* Network Policies

---

# Port Forwarding Commands

## Frontend

```bash
kubectl port-forward svc/frontend 8888:80 -n skillpulse-dev
```

OR externally:

```bash
kubectl port-forward --address 0.0.0.0 svc/frontend 8888:80 -n skillpulse-dev
```

---

## Backend

```bash
kubectl port-forward --address 0.0.0.0 svc/backend 8081:8080 -n skillpulse-dev
```

---

## ArgoCD

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

---

## Grafana

```bash
kubectl -n monitoring port-forward svc/monitoring-grafana 4000:80
```

---

## Prometheus

```bash
kubectl -n monitoring port-forward svc/monitoring-kube-prometheus-prometheus 9090:9090
```

---

# Argo Rollouts Canary Deployment

SkillPulse uses Argo Rollouts for progressive delivery and safer production deployments.

Deployment strategy includes:

* Canary rollout
* Incremental traffic shifting
* Zero downtime deployment
* Rollback capability
* Kubernetes-native rollout management

---

## Check Rollout Status

```bash
kubectl argo rollouts get rollout backend -n skillpulse-dev
```

Example:

```text
Status: ✔ Healthy
Strategy: Canary
Step: 5/5
SetWeight: 100
ActualWeight: 100
```

---

# Monitoring Stack

The project includes a complete observability setup using:

* Prometheus
* Grafana
* Kubernetes Metrics
* Pod Monitoring
* Deployment Health Tracking

---

## Monitoring Features

* Real-time pod monitoring
* CPU & memory tracking
* Deployment visibility
* Rollout health monitoring
* Kubernetes cluster metrics
* Service availability tracking

---

# AIOps Dashboard

The project includes a custom AIOps dashboard UI.

Features include:

* Live CI status
* GitHub Actions integration
* GitOps sync visibility
* Canary deployment monitoring
* Security scan visualization
* Real-time refresh dashboard

Dashboard location:

```text
aiops/dashboard/index.html
```

---

# AIOps Reporting

Every CI/CD execution automatically generates deployment reports.

Reports include:

* Deployment metadata
* Docker image versions
* Commit SHA
* Security scan status
* Pipeline execution status
* Deployment timestamps

Reports are:

* uploaded as GitHub Artifacts
* downloadable from pipeline runs
* deployed to the dashboard server

Generated report path:

```text
aiops/reports/report.html
```

---

# Security Features

Integrated security checks include:

* Gitleaks secret scanning
* Trivy filesystem scanning
* Trivy container image scanning
* Dockerfile validation
* GitHub Secrets management

---

#  Tech Stack

| Category       | Technologies         |
| -------------- | -------------------- |
| CI/CD          | GitHub Actions       |
| Containers     | Docker               |
| Orchestration  | Kubernetes           |
| GitOps         | ArgoCD               |
| Rollouts       | Argo Rollouts        |
| Monitoring     | Prometheus + Grafana |
| Backend        | Go + Gin             |
| Frontend       | HTML/CSS/JS + Nginx  |
| Database       | MySQL                |
| Infrastructure | AWS EC2              |

---

# Project Structure

```text
.github/workflows/
├── ci.yml

aiops/
├── dashboard/
│   └── index.html
├── reports/
│   └── report.html

backend/
frontend/
k8s/
mysql/
```

---

# Docker Images

Images are automatically built and pushed using GitHub Actions.

Images:

```text
shettymalathi113/skillpulse-backend
shettymalathi113/skillpulse-frontend
```

Tags:

* latest
* commit SHA

---

# Kubernetes Components

The Kubernetes environment includes:

* Deployments
* Services
* StatefulSets
* ConfigMaps
* Secrets
* Persistent Volumes
* Argo Rollouts
* Monitoring Stack

---

# Backup & Recovery

## Copy CI Logs from EC2

```bash
scp -i /path/to/key.pem -r ubuntu@<EC2-IP>:~/ci-logs /local/path
```

Example:

```bash
scp -i /d/Malathi/pem/tws-ga.pem -r ubuntu@52.37.200.37:~/ci-logs /d/Malathi/pem
```

---

# Kubernetes Troubleshooting

## Get Pods

```bash
kubectl get pods -n skillpulse-dev
```

---

## Get ReplicaSets

```bash
kubectl get rs -n skillpulse-dev
```

---

## Describe ReplicaSets

```bash
kubectl describe rs -n skillpulse-dev
```

---

## Check Rollout Status

```bash
kubectl argo rollouts get rollout backend -n skillpulse-dev
```

---

# Real DevOps Problems Solved

During development, several real-world DevOps issues were solved:

* GitOps merge conflicts
* Kubernetes rollout failures
* Port-forward exposure
* Docker multi-architecture issues
* Image pull failures
* GitHub Actions concurrency conflicts
* Canary deployment debugging
* Artifact generation issues
* CI retry handling
* Kubernetes service exposure
* ReplicaSet debugging
* Deployment rollback analysis

---

# Run Locally

## Clone Repository

```bash
git clone <repo-url>
cd github-actions-kubernetes-masterclass
```

---

## Start Docker Compose

```bash
docker compose up -d
```

---

## Access Frontend

```text
http://localhost
```

---

# Kubernetes Deployment

## Apply Kubernetes Resources

```bash
kubectl apply -f k8s/
```

---

## Verify Pods

```bash
kubectl get pods -n skillpulse-dev
```

---

# GitOps Workflow

The project follows a GitOps-based deployment model.

Flow:

1. Developer pushes code
2. GitHub Actions builds images
3. Images pushed to DockerHub
4. Kubernetes manifests updated
5. ArgoCD syncs cluster state
6. Canary rollout begins
7. Monitoring dashboards update

---

# GitHub Actions Features

The CI/CD pipeline includes:

* Multi-stage workflows
* Parallel backend/frontend builds
* Security scanning
* Artifact generation
* GitOps automation
* Retry handling
* Docker caching
* Manual approval gates
* Dashboard deployment

---

# Observability Features

Included observability components:

* Prometheus metrics
* Grafana dashboards
* Deployment tracking
* Pod health visibility
* Canary rollout monitoring
* AIOps visualization

---

# Future Improvements

Planned enhancements:

* Helm Charts
* Terraform Infrastructure
* Ingress Controller
* HTTPS with cert-manager
* Loki Log Aggregation
* AlertManager Integration
* Slack Notifications
* Multi-environment Deployments
* Real ArgoCD API integration
* Real-time Prometheus dashboard integration

---

# Learning Focus

This repository is designed to help learners understand:

* CI/CD pipelines
* Docker workflows
* Kubernetes deployments
* GitOps concepts
* Canary deployments
* Observability tooling
* DevSecOps workflows
* Cloud-native operations

---

# Credits

Built for the TrainWithShubham community.

Original learning inspiration:
TrainWithShubham DevOps Masterclass

This project evolved through hands-on experimentation, debugging, CI/CD implementation, Kubernetes deployments, GitOps workflows, monitoring integrations, and observability practices.

If this repository helps you learn DevOps or Kubernetes, share it forward and help others grow too.

