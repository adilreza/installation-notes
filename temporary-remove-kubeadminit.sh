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

# Reset Kubernetes cluster
echo -e "${GREEN}Resetting Kubernetes cluster...${RESET}"
sudo kubeadm reset -f && log_success "Kubernetes reset completed"

# Remove Kubernetes-related directories
echo -e "${GREEN}Removing Kubernetes-related files and directories...${RESET}"
sudo rm -rf /etc/cni/ && log_success "Removed /etc/cni/"
sudo rm -rf /var/lib/etcd/ && log_success "Removed /var/lib/etcd/"
sudo rm -rf /etc/kubernetes/ && log_success "Removed /etc/kubernetes/"
sudo rm -rf ~/.kube/ && log_success "Removed ~/.kube/"
sudo rm -rf /var/lib/kubelet/* && log_success "Cleared /var/lib/kubelet/"
sudo rm -rf /var/run/kubernetes && log_success "Removed /var/run/kubernetes"

# Restart necessary services
echo -e "${GREEN}Restarting kubelet and containerd services...${RESET}"
sudo systemctl restart kubelet && log_success "kubelet restarted"
sudo systemctl restart containerd && log_success "containerd restarted"

log_success "Kubernetes reset and cleanup completed successfully."
