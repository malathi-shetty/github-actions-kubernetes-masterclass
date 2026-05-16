#!/bin/bash

set -e

echo "================================="
echo "Creating project structure"
echo "================================="

# create folders
mkdir -p scripts

echo "================================="
echo "Creating setup.sh"
echo "================================="

cat > scripts/setup.sh << 'EOF'
#!/bin/bash

set -e

CLUSTER_NAME="three-tier-cluster"

echo "==============================="
echo "Updating packages"
echo "==============================="
sudo apt update -y

echo "==============================="
echo "Installing Docker"
echo "==============================="

if ! command -v docker &> /dev/null
then
    sudo apt install docker.io -y
else
    echo "Docker already installed"
fi

echo "==============================="
echo "Starting Docker"
echo "==============================="
sudo systemctl start docker
sudo systemctl enable docker

echo "==============================="
echo "Giving Docker permissions"
echo "==============================="
sudo usermod -aG docker $USER

echo "==============================="
echo "Installing kubectl"
echo "==============================="

if ! command -v kubectl &> /dev/null
then
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

    chmod +x kubectl

    sudo mv kubectl /usr/local/bin/
else
    echo "kubectl already installed"
fi

echo "==============================="
echo "Installing kind"
echo "==============================="

if ! command -v kind &> /dev/null
then
    curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.29.0/kind-linux-amd64

    chmod +x ./kind

    sudo mv ./kind /usr/local/bin/kind
else
    echo "kind already installed"
fi

echo "==============================="
echo "Versions"
echo "==============================="
docker --version
kubectl version --client
kind --version

echo "==============================="
echo "Creating Kubernetes Cluster"
echo "==============================="

if ! kind get clusters | grep -q "$CLUSTER_NAME"
then
    kind create cluster --name $CLUSTER_NAME
else
    echo "Cluster already exists"
fi

echo "==============================="
echo "Cluster Info"
echo "==============================="
kubectl cluster-info

echo "==============================="
echo "Validation"
echo "==============================="
docker ps
kubectl get nodes
kind get clusters

echo "==============================="
echo "IMPORTANT"
echo "==============================="
echo "Run this command if Docker permission fails:"
echo "newgrp docker"

echo "==============================="
echo "Done"
echo "==============================="
EOF

echo "================================="
echo "Making setup.sh executable"
echo "================================="

chmod +x scripts/setup.sh

echo "================================="
echo "Bootstrap completed"
echo "================================="
