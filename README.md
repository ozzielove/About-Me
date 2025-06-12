# backpack-bm-k8s

Quick start:

1. Install Ubuntu 22.04 nodes and run `cluster-setup/cluster_install.sh init` on the first control node.
2. Join remaining nodes with the kubeadm join command.
3. Install Helm and run `helmfile apply` to deploy apps in namespace `backpack`.
4. Apply production overlays with `kubectl apply -k kustomize/overlays/prod`.
5. Run `scripts/bootstrap_backpack.sh` to seed data.
6. Check status with `kubectl get all -n backpack`.
