#!/bin/bash
set -e

CLUSTER_NAME="three-tier-cluster"

echo "================================="
echo "SKILLPULSE ENV SETUP START"
echo "================================="

# =========================
# WAIT FOR APT LOCK (CRITICAL FIX)
# =========================

echo "[INFO] Checking system package lock..."

while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
    echo "[WAIT] apt is locked (unattended-upgrades running)... waiting 5s"
    sleep 5
done

echo "[INFO] apt is free, continuing..."

# =========================
# SYSTEM UPDATE
# =========================

sudo apt update -y

# =========================
# DOCKER INSTALL (OFFICIAL)
# =========================

if ! command -v docker &> /dev/null; then
    echo "[INFO] Installing Docker..."

    sudo apt-get update
    sudo apt-get install -y ca-certificates curl gnupg

    sudo install -m 0755 -d /etc/apt/keyrings

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
        sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo $VERSION_CODENAME) stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

else
    echo "[INFO] Docker already installed"
fi

sudo systemctl enable docker
sudo systemctl start docker

sudo usermod -aG docker $USER
echo "[WARN] Run 'newgrp docker' OR re-login for Docker permissions"

# =========================
# VERIFY DOCKER COMPOSE (SAFE CHECK)
# =========================

if docker compose version &> /dev/null; then
    echo "[INFO] Docker Compose already available"
else
    echo "[INFO] Installing Docker Compose plugin..."
    sudo apt-get update
    sudo apt-get install -y docker-compose-plugin
fi

# =========================
# KUBECTL INSTALL
# =========================

if ! command -v kubectl &> /dev/null; then
    echo "[INFO] Installing kubectl"

    KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)

    curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
else
    echo "[INFO] kubectl already installed"
fi

# =========================
# KIND INSTALL
# =========================

if ! command -v kind &> /dev/null; then
    echo "[INFO] Installing kind"

    curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.29.0/kind-linux-amd64
    chmod +x ./kind
    sudo mv ./kind /usr/local/bin/kind
else
    echo "[INFO] kind already installed"
fi

# =========================
# VERIFY TOOLS
# =========================

echo ""
echo "========================="
echo "VERSIONS"
echo "========================="

docker --version
kubectl version --client
kind --version

# =========================
# CREATE KIND CLUSTER (SAFE)
# =========================

if kind get clusters | grep -q "$CLUSTER_NAME"; then
    echo "[INFO] Cluster already exists: $CLUSTER_NAME"
else
    echo "[INFO] Creating cluster: $CLUSTER_NAME"
    kind create cluster --name "$CLUSTER_NAME"
fi

# =========================
# WAIT FOR CLUSTER READY
# =========================

echo "[INFO] Waiting for Kubernetes nodes..."

kubectl wait --for=condition=Ready nodes --all --timeout=180s

# =========================
# FINAL STATUS
# =========================

echo ""
echo "========================="
echo "CLUSTER STATUS"
echo "========================="

kubectl cluster-info
kubectl get nodes

echo "================================="
echo "SETUP COMPLETE SUCCESSFULLY"
echo "================================="
