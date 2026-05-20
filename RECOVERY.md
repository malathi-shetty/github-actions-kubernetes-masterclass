# SkillPulse Recovery Guide

## Clone Project

```bash
git clone <repo-url>
cd github-actions-kubernetes-masterclass
```

---

## Create .env

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

---

## Test Frontend

```bash
curl http://localhost
```

---

## Test Backend API

```bash
curl http://localhost/api/skills
```

---

## Open Browser

```text
http://<EC2-PUBLIC-IP>
```
