#!/bin/bash
# Script to install packages for initial server configuration
# Copyright (C) 2020 John Tambi (jon.tambi@gmail.com)
# Last revised 2021/01/07

# Set hostname
#hostnamectl set-hostname "cka" --static
#hostnamectl set-hostname "Lab - CKA" --pretty

# Update OS Ubuntu 18.04
sudo apt-get update && sudo apt-get install -y apt-transport-https curl net-tools wget vim htop git telnet

# Configure prerequisites Containerd
sudo cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Setup required sysctl params, these persist across reboots.
sudo cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system

# Disable SELINUX
sudo setenforce 0
sudo cp -p /etc/selinux/config /etc/selinux/config.ORI
sudo sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

# (Install containerd)
## Set up the repository
### Install required packages
sudo apt-get update && sudo apt-get install -y containerd

# Configure containerd
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml

#cat systemd-config.text >> containerd-config.toml

# Restart containerd
sudo systemctl enable containerd
sudo systemctl restart containerd

# Installing kubeadm, kubelet and kubectl
sudo curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
sudo apt-get update

# Install kubelet kubeadm kubectl
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

sudo systemctl daemon-reload
sudo systemctl restart kubelet

# Create user ansible
#useradd -s /bin/bash -c "Usuario de despliegue - DevOps" -U devops
#cat << 'EOF' > /etc/sudoers.d/devops
#User_Alias ANSIBLE_AUTOMATION = devops
#ANSIBLE_AUTOMATION ALL=(ALL)      NOPASSWD: ALL
#EOF