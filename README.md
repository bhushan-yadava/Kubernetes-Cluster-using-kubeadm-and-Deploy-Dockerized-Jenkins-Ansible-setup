🚀 Kubernetes Cluster with Jenkins + Ansible (via kubeadm)


This project demonstrates how to manually create a Kubernetes cluster using kubeadm, and then deploy a Dockerized Jenkins + Ansible setup on top of the cluster to automate deployments across nodes.


It’s a practical DevOps setup where Jenkins pipelines can trigger Ansible playbooks to configure or deploy workloads onto your cluster nodes.

📌 Project Structure
k8s-jenkins-ansible/
│── Dockerfile.ansible              # Custom Ansible container image
│── entrypoint.sh                   # Entrypoint for Ansible container
│── manifests/                      # Kubernetes manifests
│   ├── jenkins-pvc.yaml            # Persistent volume claim for Jenkins
│   ├── jenkins-deploy.yaml         # Jenkins deployment + service
│   ├── ansible-inventory-configmap.yaml  # Ansible inventory as ConfigMap
│   ├── ansible-deploy.yaml         # Ansible controller pod deployment
│   └── ansible-job.yaml            # K8s Job template for running playbooks
│── playbooks/
│   └── site.yml                    # Sample Ansible playbook
│── README.md                       # Documentation


⚙️ 1. Prerequisites

Linux machines / VMs with:

2+ CPUs, 4GB RAM (minimum per node)

Ubuntu 20.04+ (tested) or other Linux distro

kubeadm, kubelet, kubectl installed

containerd or Docker runtime

kubectl configured on control-plane node

VS Code with:

Kubernetes extension

Docker extension

YAML extension

🏗️ 2. Setup Kubernetes Cluster (via kubeadm)
On all nodes:
# Disable swap
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# Enable bridge traffic
sudo modprobe br_netfilter
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables  = 1
EOF
sudo sysctl --system

Install runtime + kubeadm + kubelet + kubectl:
# containerd
sudo apt update && sudo apt install -y containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo systemctl restart containerd

# kubeadm, kubelet, kubectl
sudo apt update && sudo apt install -y apt-transport-https ca-certificates curl
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

On control-plane node:
sudo kubeadm init --pod-network-cidr=192.168.0.0/16

# Configure kubectl for your user
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

Install Calico CNI:
kubectl apply -f https://docs.tigera.io/manifests/calico.yaml

On worker nodes:

Run the kubeadm join ... command printed by kubeadm init.



🐳 3. Jenkins Deployment

Create namespace:

kubectl create namespace devops-tools


Apply manifests:

kubectl apply -f manifests/jenkins-pvc.yaml
kubectl apply -f manifests/jenkins-deploy.yaml


Access Jenkins:

kubectl -n devops-tools get svc jenkins


Open in browser → http://<nodeIP>:30080



⚡ 4. Ansible Controller Deployment

Build Ansible image:
docker build -t myregistry.local/ansible-controller:latest -f Dockerfile.ansible .
docker push myregistry.local/ansible-controller:latest

Create SSH key Secret:
ssh-keygen -t rsa -b 4096 -f ansible_id_rsa -N ""
kubectl create secret generic ansible-ssh-key \
  --from-file=id_rsa=./ansible_id_rsa \
  -n devops-tools

Apply inventory & Ansible controller:
kubectl apply -f manifests/ansible-inventory-configmap.yaml
kubectl apply -f manifests/ansible-deploy.yaml



🔄 5. Jenkins + Ansible Integration

Jenkins pipelines can trigger Ansible Jobs on Kubernetes:

Option 1: Jenkins applies a Job manifest (kubectl apply -f ansible-job.yaml).

Option 2: Jenkins execs into the running Ansible pod:

kubectl exec -n devops-tools deploy/ansible-controller -- \
  ansible-playbook -i /etc/ansible/hosts.ini /ansible/playbooks/site.yml

📊 6. Architecture Workflow

kubeadm provisions cluster (control-plane + worker nodes).

Calico provides pod networking.

Jenkins runs inside Kubernetes (with persistent storage).

Ansible controller pod runs inside Kubernetes with SSH keys + inventory.

Jenkins pipeline triggers Ansible → SSH into nodes → run playbooks.

🔒 8. Security Notes

Store SSH keys in Kubernetes Secrets.

Restrict Jenkins ServiceAccount permissions (RBAC).

Rotate SSH keys regularly.

Use a private registry for Ansible image if possible.

✅ 9. Verification

Check nodes:

kubectl get nodes


Check pods:

kubectl get pods -n devops-tools


Test Ansible connectivity:

kubectl exec -it -n devops-tools deploy/ansible-controller -- \
  ansible all -m ping -i /etc/ansible/hosts.ini

📚 References

Kubernetes: kubeadm Installation Guide

Project Calico CNI

Jenkins Docker Image

Ansible Documentation
