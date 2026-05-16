#!/bin/bash

set -e

TAG=$1

if [ -z "$TAG" ]; then
  echo "Usage: ./update-image-tag.sh <image-tag>"
  exit 1
fi

echo "Updating Kubernetes manifests with tag: $TAG"

sed -i "s|__IMAGE_TAG__|$TAG|g" k8s/20-backend.yaml
sed -i "s|__IMAGE_TAG__|$TAG|g" k8s/30-frontend.yaml

echo "Done updating manifests"
