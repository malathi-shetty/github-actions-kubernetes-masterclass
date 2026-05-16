#!/bin/bash
set -e

CLUSTER_NAME="skillpulse"

echo "================================="
echo "SKILLPULSE ZERO-TOUCH BOOTSTRAP"
echo "================================="

# =========================
# APT LOCK HANDLING
# =========================

echo "[INFO] Checking apt lock..."

while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
    echo "[WAIT] apt locked... sleeping"
    sleep 5
done

sudo apt-get update -y

# =========================
# DOCKER INSTALL
# =========================

if ! command -v docker &>/dev/null; then
    echo "[INFO] Installing Docker..."

    curl -fsSL https://get.docker.com | sudo sh
else
    echo "[INFO] Docker already installed"
fi

sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER

# =========================
# DOCKER COMPOSE PLUGIN FIX
# =========================

if ! docker compose version &>/dev/null; then
    echo "[INFO] Installing Docker Compose plugin..."
    sudo apt-get install -y docker-compose-plugin || true
fi

# =========================
# KUBECTL
# =========================

if ! command -v kubectl &>/dev/null; then
    echo "[INFO] Installing kubectl..."

    KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)

    curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
fi

# =========================
# KIND
# =========================

if ! command -v kind &>/dev/null; then
    echo "[INFO] Installing kind..."

    curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.29.0/kind-linux-amd64
    chmod +x ./kind
    sudo mv ./kind /usr/local/bin/kind
fi

# =========================
# VERSION CHECK
# =========================

echo "Docker: $(docker --version)"
echo "kubectl: $(kubectl version --client --short)"
echo "kind: $(kind --version)"

# =========================
# CLUSTER CREATE
# =========================

if kind get clusters | grep -q "$CLUSTER_NAME"; then
    echo "[INFO] Cluster already exists"
else
    echo "[INFO] Creating cluster..."
    kind create cluster --name "$CLUSTER_NAME"
fi

kubectl wait --for=condition=Ready nodes --all --timeout=180s

echo "================================="
echo "BOOTSTRAP COMPLETE"
echo "================================="
