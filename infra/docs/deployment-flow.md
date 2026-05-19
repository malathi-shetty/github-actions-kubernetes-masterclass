# SkillPulse Deployment Flow

# Developer Workflow

1. Developer pushes code to GitHub
2. GitHub Actions pipeline starts
3. Docker image is built
4. Image pushed to DockerHub
5. Kubernetes manifests updated
6. ArgoCD detects Git changes
7. ArgoCD syncs cluster state
8. Argo Rollouts performs canary deployment
9. Prometheus monitors deployment
10. Grafana visualizes metrics

---

# Detailed Flow

Developer
↓
GitHub Repository
↓
GitHub Actions CI/CD
↓
DockerHub Image Registry
↓
ArgoCD GitOps Sync
↓
Amazon EKS Cluster
↓
Namespaces:

* dev
* staging
* prod
  ↓
  Application Deployments

---

# Backend Deployment

Deployment Type:

* Argo Rollouts Canary

Steps:

* 20% traffic
* pause
* 50% traffic
* pause
* 100% rollout

---

# Frontend Deployment

Deployment Type:

* Standard Kubernetes Deployment

---

# Database Deployment

Deployment Type:

* StatefulSet

Features:

* Persistent storage
* Stable network identity
* EBS-backed PVC

---

# Monitoring Flow

Prometheus:

* scrapes cluster metrics
* stores time-series metrics

Grafana:

* dashboards
* visualization
* alert monitoring

---

# GitOps Principle

Git repository is the source of truth.

Any cluster drift:
→ ArgoCD corrects automatically

---

# Recovery Flow

If cluster fails:

1. Recreate EKS cluster
2. Install ArgoCD
3. Apply applications
4. ArgoCD restores workloads automatically

---

# Future Improvements

Planned:

* HTTPS with cert-manager
* Loki logging
* Tempo tracing
* HPA autoscaling
* Terraform infrastructure
* AI-driven anomaly detection


# Deployment Flow

## CI/CD Pipeline

1. Developer pushes code to GitHub
2. GitHub Actions builds Docker image
3. Docker image pushed to DockerHub
4. ArgoCD detects Git changes
5. Kubernetes deployment updates automatically
6. Argo Rollouts performs canary deployment
7. Prometheus monitors metrics
8. Grafana displays dashboards

## Rollback

Rollback possible using:
- Argo Rollouts
- Git revert
- ArgoCD sync

## Monitoring

Metrics:
- CPU
- Memory
- Pod health
- Rollout status
- Node metrics

## Recovery

Cluster can be recreated from:
- GitHub repo
- ArgoCD applications
- Kubernetes manifests
