
Follow this document to install kubectl on linux machine

https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/?source=post_page-----e845337a956--------------------------------



    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
    echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    kubectl version --client

Install Minikube - https://crishantha.medium.com/running-minikube-on-aws-ec2-e845337a956

    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube
    minikube start
    minikube status

O/p

[ec2-user@ip-172-31-25-174 ~]$ minikube status
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured

[ec2-user@ip-172-31-25-174 ~]$