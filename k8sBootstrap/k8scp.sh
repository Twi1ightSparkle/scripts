#!/bin/bash

read -rp "Controlplane endpoint: " cpEndpoint


# bash setup
cat << EOF | tee -a "$HOME/.bashrc"
source <(kubectl completion bash)
alias k='kubectl '
EOF

# Init cluster
# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#initializing-your-control-plane-node
# Do not edit the CDIR.
# or if you do, edit /run/flannel/subnet.env on all your nodes
# and download the Flannel manifest and edit, then apply manually
sudo kubeadm init \
    --pod-network-cidr=10.244.0.0/16 \
    --control-plane-endpoint "$cpEndpoint"
mkdir -p "$HOME/.kube"
sudo cp -i "/etc/kubernetes/admin.conf" "$HOME/.kube/config"
sudo chown "$(id -u):$(id -g)" "$HOME/.kube/config"
kubectl get nodes

# https://github.com/flannel-io/flannel
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

joinCmd="$(kubeadm token create --print-join-command)"

cat << EOF


Cluster created. Use "kubectl get nodes" to check the status of this node.
When it is ready, join other control planes with
sudo $joinCmd --control-plane

And workers with
sudo $joinCmd

Scroll up to see additional output from the cluster create operation.

Copy the Kube config to your machine with:
rsync --rsh ssh $USER@$(hostname):$HOME/.kube/config \$HOME/.kube/config-bootstrap
echo "alias kboot='kubectl --kubeconfig=\$HOME/.kube/config-bootstrap '" >> \$HOME/.zshrc
EOF
