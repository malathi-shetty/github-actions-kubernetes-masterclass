#!/bin/bash

set -e

CLUSTER_NAME="three-tier-cluster"

echo "================================="
echo "SKILLPULSE ENV SETUP START"
echo "================================="


# =========================
# UPDATE SYSTEM
# =========================

echo "Updating packages"
sudo apt update -y


# =========================
# DOCKER
# =========================

if ! command -v docker &> /dev/null
then
    echo "Installing Docker"
    sudo apt install docker.io -y
else
    echo "Docker already installed"
fi

sudo systemctl start docker
sudo systemctl enable docker

sudo usermod -aG docker $USER

echo "Docker permission set (run: newgrp docker)"


# =========================
# KUBECTL
# =========================

if ! command -v kubectl &> /dev/null
then
    echo "Installing kubectl"
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
else
    echo "kubectl already installed"
fi


# =========================
# KIND
# =========================

if ! command -v kind &> /dev/null
then
    echo "Installing kind"
    curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.29.0/kind-linux-amd64
    chmod +x ./kind
    sudo mv ./kind /usr/local/bin/kind
else
    echo "kind already installed"
fi


# =========================
# VERSIONS
# =========================

echo "Docker:"
docker --version

echo "kubectl:"
kubectl version --client

echo "kind:"
kind --version


# =========================
# CLUSTER SAFE CREATE
# =========================

if kind get clusters | grep -q "$CLUSTER_NAME"
then
    echo "Cluster already exists"
else
    echo "Creating cluster"
    kind create cluster --name "$CLUSTER_NAME"
fi


# =========================
# VERIFY
# =========================

kubectl cluster-info
kubectl get nodes


echo "================================="
echo "SETUP COMPLETE"
echo "================================="
