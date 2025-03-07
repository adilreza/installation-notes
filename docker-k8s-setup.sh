#!/bin/bash
set -e  # Exit immediately if a command exits with a non-zero status

# Define colors
GREEN="\e[32m"
RED="\e[31m"
RESET="\e[0m"

log_success() {
    echo -e "${GREEN}[SUCCESS] $1${RESET}"
}

log_error() {
    echo -e "${RED}[ERROR] $1${RESET}"
    exit 1
}

# Disable SELinux temporarily and permanently
sudo setenforce 0 && log_success "SELinux set to permissive temporarily"
sudo sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/sysconfig/selinux && log_success "SELinux set to permissive permanently"

# Open necessary firewall ports
sudo firewall-cmd --permanent --add-port={6443,2379,2380,10250,10251,10252,10257,10259,179}/tcp && log_success "Added TCP ports to firewall"
sudo firewall-cmd --permanent --add-port=4789/udp && log_success "Added UDP port to firewall"
sudo firewall-cmd --reload && log_success "Firewall reloaded"

# Add Docker repository
sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo && log_success "Docker CE repository added"

# Configure Docker repo manually
cat <<EOF | sudo tee /etc/yum.repos.d/docker-ce.repo
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://download.docker.com/linux/centos/9/x86_64/stable/
enabled=1
gpgcheck=1
gpgkey=https://download.docker.com/linux/centos/gpg
EOF
log_success "Docker CE repository configured"

# Install containerd
sudo dnf install containerd.io -y && log_success "containerd installed"

# Configure containerd
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null 2>&1
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml && log_success "Configured containerd to use SystemdCgroup"

# Load necessary kernel modules
sudo tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF
sudo modprobe overlay && sudo modprobe br_netfilter && log_success "Kernel modules loaded"

# Configure sysctl parameters
sudo tee -a /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sudo sysctl --system && log_success "Sysctl parameters updated"

# Add Kubernetes repository
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF
log_success "Kubernetes repository added"

# Install Kubernetes tools
sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes && log_success "Kubernetes components installed"

# Check versions
kubeadm version && log_success "kubeadm version checked"
kubectl version --client && log_success "kubectl version checked"

log_success "Script execution completed successfully"
