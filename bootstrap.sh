#!/bin/bash

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

echo "==============================="
echo "Updating packages"
echo "==============================="
sudo apt update -y

echo "==============================="
echo "Installing Docker"
echo "==============================="
sudo apt install docker.io -y

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
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

chmod +x kubectl

sudo mv kubectl /usr/local/bin/

echo "==============================="
echo "Installing kind"
echo "==============================="
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.29.0/kind-linux-amd64

chmod +x ./kind

sudo mv ./kind /usr/local/bin/kind

echo "==============================="
echo "Versions"
echo "==============================="
docker --version
kubectl version --client
kind --version

echo "==============================="
echo "Creating Kubernetes Cluster"
echo "==============================="
kind create cluster --name three-tier-cluster

echo "==============================="
echo "Cluster Info"
echo "==============================="
kubectl cluster-info

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
