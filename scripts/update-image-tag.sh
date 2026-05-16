#!/bin/bash
set -e

TAG=$1

if [ -z "$TAG" ]; then
  echo "Usage: ./update-image-tag.sh <tag>"
  exit 1
fi

echo "[INFO] Updating Kubernetes manifests with tag: $TAG"

find k8s -type f -name "*.yaml" -exec sed -i "s|__TAG__|$TAG|g" {} +

git add k8s
git commit -m "update image tag to $TAG"
git push

echo "[SUCCESS] GitOps commit pushed"
