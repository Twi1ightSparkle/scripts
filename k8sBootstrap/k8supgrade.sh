#!/bin/bash

newVersion="1.28.1-1.1"

baseVersion="${newVersion%-*}"

read -rp "Is this the main controlplane [y/N]? " isCp

# https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/
sudo apt-mark unhold kubeadm
sudo apt-get update
sudo apt-get install -y --allow-downgrades kubeadm="$newVersion"
sudo apt-mark hold kubeadm
kubeadm version

cat << EOF


Verify that the installed kubeadmin version is $baseVersion
Press enter to continue
EOF
read -r

if [ "$isCp" == "y" ] || [ "$isCp" == "Y" ]; then
    sudo kubeadm upgrade plan
    echo -e "\n\n\n\nPress enter to apply the update if this looks good"
    read -r
    sudo kubeadm upgrade apply "v$baseVersion"
else 
    sudo kubeadm upgrade node
fi


cat << EOF


If you have more than one control plane / worker, drain this node with
kubectl drain $(hostname) --ignore-daemonsets
Press enter to continue when done
EOF
read -r
    
sudo apt-mark unhold kubelet kubectl
sudo apt-get install -y --allow-downgrades kubelet="$newVersion" kubectl="$newVersion"
sudo apt-mark hold kubelet kubectl
sudo systemctl daemon-reload
sudo systemctl restart kubelet

cat << EOF


If you have more than one control plane / worker, uncordon this node with
kubectl uncordon $(hostname)

If you have other updates to apply to this system, do that and reboot if needed before undordoning
EOF
