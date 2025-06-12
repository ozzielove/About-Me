#!/bin/sh
# Idempotent setup of kubeadm-based Kubernetes cluster with GPU workers
set -e

if command -v kubeadm >/dev/null 2>&1; then
  echo "kubeadm already installed"
else
  apt-get update
  apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
  if [ ! -f /usr/share/keyrings/kubernetes-archive-keyring.gpg ]; then
    curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg \
      https://packages.cloud.google.com/apt/doc/apt-key.gpg
    echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
  fi
  apt-get update
  apt-get install -y kubelet kubeadm kubectl containerd
  apt-mark hold kubelet kubeadm kubectl
  mkdir -p /etc/containerd
  containerd config default > /etc/containerd/config.toml
  systemctl enable --now containerd
fi

# NVIDIA drivers and toolkit
if ! dpkg -l | grep -q nvidia-container-toolkit; then
  distribution=$(source /etc/os-release && echo $ID$VERSION_ID)
  curl -s -L https://nvidia.github.io/libnvidia-container/gpgkey | apt-key add -
  curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list > /etc/apt/sources.list.d/nvidia-container-toolkit.list
  apt-get update
  apt-get install -y nvidia-driver-535 nvidia-container-toolkit
  nvidia-ctk runtime configure --runtime=containerd
  systemctl restart containerd
fi

if [ "$1" = "init" ]; then
  kubeadm init --pod-network-cidr=10.244.0.0/16 --service-cidr=10.96.0.0/12 || true
  mkdir -p $HOME/.kube
  cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  chown $(id -u):$(id -g) $HOME/.kube/config
  kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/v0.22.0/manifests/kube-flannel.yml
  kubectl create namespace metallb-system || true
  kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.10/config/manifests/metallb-native.yaml
  cat <<EOF_MB | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default-pool
  namespace: metallb-system
spec:
  addresses:
  - 10.0.0.80-10.0.0.99
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: default
  namespace: metallb-system
EOF_MB
fi

exit 0
