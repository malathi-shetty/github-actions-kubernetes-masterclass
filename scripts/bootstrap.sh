#!/bin/bash

kind create cluster --config k8s/kind-config.yaml

kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

kubectl create namespace skillpulse-prod
kubectl apply -k k8s/overlays/dev

echo "Cluster ready"
