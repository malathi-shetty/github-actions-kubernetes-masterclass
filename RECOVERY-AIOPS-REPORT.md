# SkillPulse — CI/CD, Recovery & AIOps Reports

## Project Overview

SkillPulse is a containerized full-stack application deployed using:

* Docker & Docker Compose
* Kubernetes
* GitHub Actions CI/CD
* NGINX frontend reverse proxy
* Golang backend
* MySQL database

---

# Local Recovery Guide

## Clone Repository

```bash
git clone <repo-url>
cd github-actions-kubernetes-masterclass
```

---

## Create Environment File

Create `.env`

```bash
nano .env
```

Paste:

```env
MYSQL_ROOT_PASSWORD=rootpassword123
DB_HOST=db
DB_PORT=3306
DB_USER=skillpulse
DB_PASSWORD=skillpulse123
DB_NAME=skillpulse

APP_PORT=8080
ENVIRONMENT=development

CLUSTER_NAME=skillpulse
K8S_NAMESPACE=skillpulse
```

---

## Start Application

```bash
docker compose down
docker volume prune -f
docker compose up --build
```

---

## Verify Containers

```bash
docker ps
```

Expected containers:

* frontend
* backend
* db

---

## Test Application

### Frontend

```bash
curl http://localhost
```

### Backend API

```bash
curl http://localhost/api/skills
```

---

# Kubernetes Deployment

## Apply Kustomize Overlay

```bash
kubectl apply -k k8s/overlays/prod
```

## Verify Pods

```bash
kubectl get pods -n skillpulse
```

## Verify Services

```bash
kubectl get svc -n skillpulse
```

---

# GitHub Actions CI/CD Pipeline

The project uses GitHub Actions for:

* Docker image build
* Security scanning
* Kubernetes deployment
* AIOps report generation
* Artifact uploads

Workflow location:

```text
.github/workflows/
```

---

# AIOps Reports

The CI pipeline automatically generates:

* Build reports
* Deployment reports
* Kubernetes health reports
* Docker image reports
* Security scan summaries
* Recovery logs

These reports are uploaded as GitHub Actions artifacts.

---

# Auto Download CI Reports

## Download from GitHub Actions UI

1. Open GitHub repository
2. Go to:

```text
Actions → Select Workflow Run
```

3. Scroll to:

```text
Artifacts
```

4. Download:

* aiops-report
* deployment-report
* kubernetes-logs
* docker-build-report

---

# Auto Download Using GitHub CLI

Install GitHub CLI:

```bash
sudo apt install gh -y
```

Authenticate:

```bash
gh auth login
```

List workflow runs:

```bash
gh run list
```

Download artifacts:

```bash
gh run download <RUN_ID>
```

Download to custom directory:

```bash
gh run download <RUN_ID> -D reports/
```

---

# Example GitHub Actions Artifact Upload

```yaml
- name: Upload AIOps Report
  uses: actions/upload-artifact@v4
  with:
    name: aiops-report
    path: reports/
```

---

# Example Auto Recovery Workflow

```yaml
- name: Docker Compose Recovery
  run: |
    docker compose down
    docker volume prune -f
    docker compose up --build -d
```

---

# Useful Debug Commands

## Docker Logs

```bash
docker compose logs backend
docker compose logs frontend
docker compose logs db
```

---

## Kubernetes Logs

```bash
kubectl logs -f deployment/backend -n skillpulse
kubectl logs -f deployment/frontend -n skillpulse
```

---

## Restart Kubernetes Deployment

```bash
kubectl rollout restart deployment backend -n skillpulse
kubectl rollout restart deployment frontend -n skillpulse
```

---

# Save Docker Images

## Export Images

```bash
docker save -o skillpulse-images.tar \
  skillpulse-frontend:local \
  skillpulse-backend:local
```

## Import Images

```bash
docker load -i skillpulse-images.tar
```

---

# Recommended Repository Structure

```text
.github/workflows/
backend/
frontend/
k8s/
mysql/
RECOVERY.md
README.md
.env.example
```

---

# Future Improvements

* Helm charts
* Prometheus monitoring
* Grafana dashboards
* ArgoCD GitOps
* SonarQube integration
* Trivy security scans
* Auto rollback deployment
* AI anomaly detection

---

# Author

SkillPulse DevOps & AIOps CI/CD Project
