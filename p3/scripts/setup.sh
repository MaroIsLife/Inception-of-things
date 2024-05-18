#!/bin/bash
# Check if Docker is installed
if ! command -v docker &> /dev/null
then
    echo "Docker is not installed. Installing Docker..."
    # Install Docker
    # Step 1
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    # Step 2
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose
else
    echo "Docker is already installed."
fi

# Check if k3d is installed
if ! command -v k3d &> /dev/null
then
    echo "k3d is not installed. Installing k3d..."
    # Install k3d
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
else
    echo "k3d is already installed."
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null
then
    echo "kubectl is not installed. Installing kubectl..."
    # Install kubectl
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x ./kubectl
    sudo mv ./kubectl /usr/local/bin/kubectl
else
    echo "kubectl is already installed."
fi
# check if argocd is installed
if ! command -v argocd &> /dev/null
then
    echo "argocd is not installed. Installing argocd..."
    # Install argocd
     brew install argocd
else
    echo "argocd is already installed."
fi


# setup env
kubectl create namespace dev
kubectl create namespace argocd

# set context to argocd namespace  so we don't need to specify (-n argocd everytime) it will work directly in the argocd namespace
kubectl config set-context --current --namespace=argocd
kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml


#Port forwarding in Kubernetes allows you to access services running inside your Kubernetes cluster from your local machine. This is particularly useful for accessing services that are not exposed to the internet.
kubectl port-forward svc/argocd-server  8080:443



#get user credentials
echo username = admin
echo password to log into argocd ui = ; argocd admin initial-password  

#deplpy app with argocd
argocd app create guestbook --repo https://github.com/elhadjaoui/InceptionOfThings.git --path manifests --dest-server https://kubernetes.default.svc --dest-namespace dev