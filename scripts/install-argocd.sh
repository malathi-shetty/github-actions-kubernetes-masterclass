#!/bin/bash

set -e

echo "🚀 Installing ArgoCD..."

# Step 1: Create namespace
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# Step 2: Install ArgoCD
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "⏳ Waiting for ArgoCD pods to be ready..."

kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s

echo "🔐 Fetching ArgoCD admin password..."

kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d

echo ""
echo "✅ ArgoCD installed successfully!"
echo "👉 To access UI run:"
echo "kubectl port-forward svc/argocd-server -n argocd 8080:443"
