#!/bin/bash
#useful commands 
#kubectl delete pods --all  
#k3d cluster delete [clusteName]
#k3d cluster list


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
    curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
    chmod +x /usr/local/bin/argocd
else
    echo "argocd is already installed."
fi

#create cluster
k3d cluster create iot-cluster -p "8888:30007"

# setup env
kubectl create namespace dev
kubectl create namespace argocd

kubectl apply -n argocd -f /vagrant/confs/argocd.yaml

sleep 10
# Function to check if all pods are running
are_all_pods_running() {
    local NOT_RUNNING_PODS=$(kubectl get pods -n argocd --field-selector=status.phase!=Running -o jsonpath='{range .items[*]}{@.metadata.name}')
    if [ -z "$NOT_RUNNING_PODS" ]; then
        return 0  # All pods are running
    else
        echo "The following pods are not running:"
        echo "$NOT_RUNNING_PODS"
        return 1  # Some pods are not running
    fi
}

# Loop until all pods are running
while ! are_all_pods_running; do
    echo "Waiting for all pods to be in Running status..."
    echo "Current pod statuses:"
    kubectl get pods -n argocd
    sleep 10  # Wait for 10 seconds before checking again
done
echo "All pods are now in Running status."
#Port forwarding in Kubernetes allows you to access services running inside your Kubernetes cluster from your local machine. This is particularly useful for accessing services that are not exposed to the internet.
kubectl port-forward --address 0.0.0.0 svc/argocd-server -n argocd 8080:443 &> /dev/null &

#get user credentials
echo  username = admin
echo -n "password to log into argocd ui = " ;
argocd admin initial-password -n argocd
ARGOCD_PASSWORD=$(kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d)
echo $ARGOCD_PASSWORD
argocd login --insecure localhost:8080 --username admin --password $ARGOCD_PASSWORD

sleep 4

# create gitlab namespace
kubectl create namespace gitlab

# install helm package manager for kubernetes applications
if ! command -v helm &> /dev/null
then
    echo "helm is not installed. Installing helm..."
    # Install helm
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
else
    echo "helm is already installed."
fi

# add gitlab to helm repo
helm repo add gitlab https://charts.gitlab.io/

gitlabDomain=localhost

echo "\033[0;34m-----Start installing Gitlab with Helm----- \033[0m"
# run gitlab application
helm install gitlab gitlab/gitlab --namespace gitlab --set global.hosts.domain=$gitlabDomain --set global.hosts.https=false --set certmanager-issuer.email=amghough551@gmail.com
echo "\033[0;32mGitlab installed successfully with Helm\033[0m"

sleep 10

# Loop until the neccessary pods are running
while [ 1 ]
do
    exit=0
    for i in 0 1
    do
        podStatus=$(kubectl get pods -n gitlab -l app='webservice' -o jsonpath="{.items[$i].status.phase}")
        if [ $podStatus = "Running" ];
        then
            exit=1
            break
        fi
    done
    if [ $exit = 1 ];
    then
        echo "\033[0;32mCurrent pod status is $podStatus\033[0m"
        break
    else
        echo "\033[0;34mCurrent pod status is $podStatus\033[0m"
        sudo kubectl get pods -n gitlab
    fi
    sleep 10
done

# get default password
gitlabPassword=$(kubectl get secret -n gitlab gitlab-gitlab-initial-root-password -ojsonpath='{.data.password}' | base64 --decode)

# expose gitlab service
kubectl port-forward --address 0.0.0.0 -n gitlab svc/gitlab-nginx-ingress-controller 443:443 &> /dev/null &
echo "Gitlab has been successfully exposed"

sudo kubectl get secret gitlab-gitlab-tls -n gitlab -o jsonpath="{['data']['tls\.crt']}" | base64 --decode >> /vagrant/cert.pem

argocd cert add-tls --from /vagrant/cert.pem gitlab.localhost

sleep 10

echo "You can Access Argocd in this URL : localhost:8080"
echo "Gitlab username: admin"
echo "Gitlab Password: $ARGOCD_PASSWORD"

echo "You can Access Gitlab in this URL : https://gitlab.$gitlabDomain"
echo "Gitlab username: root"
echo "Gitlab Password: $gitlabPassword"