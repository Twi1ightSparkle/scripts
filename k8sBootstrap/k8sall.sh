#!/bin/bash

k8sVersion="v1.28"
cniVersion="v1.3.0"

# Forwarding IPv4 and letting iptables see bridged traffic
# https://kubernetes.io/docs/setup/production-environment/container-runtimes/
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system

lsmod | grep br_netfilter
lsmod | grep overlay
cat << EOF



Verify that the "br_netfilter" and "overlay" modules are loaded.
Press enter to continue if successful.
EOF
read -r

# Install containerd
# https://github.com/containerd/containerd/blob/main/docs/getting-started.md
# https://docs.docker.com/engine/install/debian/
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get -y remove $pkg; done
sudo apt-get -y update
sudo apt-get -y install ca-certificates curl gnupg
sudo install -m 0755 -d "/etc/apt/keyrings"
curl -fsSL "https://download.docker.com/linux/debian/gpg" | sudo gpg --dearmor -o "/etc/apt/keyrings/docker.gpg"
sudo chmod a+r "/etc/apt/keyrings/docker.gpg"
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get -y update
sudo apt-get -y install containerd.io
sudo systemctl daemon-reload
sudo systemctl enable --now containerd
wget "https://github.com/containernetworking/plugins/releases/download/$cniVersion/cni-plugins-linux-amd64-$cniVersion.tgz"
sudo mkdir -p "/opt/cni/bin"
sudo tar Cxzvf "/opt/cni/bin" "cni-plugins-linux-amd64-$cniVersion.tgz"

# Configuring the systemd cgroup driver
# https://kubernetes.io/docs/setup/production-environment/container-runtimes/#containerd-systemd
sudo containerd config default | sudo tee "/etc/containerd/config.toml"
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

if ! grep "disabled_plugins = \[\]" "/etc/containerd/config.toml"; then
cat << EOF



"cri" might be included in "disabled_plugins" in /etc/containerd/config.toml
Remove "cri" from that array.
Press enter to continue when done.
EOF
read -r
fi

sudo systemctl restart containerd

# Install k8s
sudo apt-get -y update
sudo apt-get install -y apt-transport-https ca-certificates curl
curl -fsSL https://pkgs.k8s.io/core:/stable:/$k8sVersion/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/$k8sVersion/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get -y update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# Add Flannel config
sudo mkdir -p "/run/flannel"
cat <<EOF | sudo tee "/run/flannel/subnet.env"
FLANNEL_NETWORK=10.244.0.0/16
FLANNEL_SUBNET=10.244.0.1/24
FLANNEL_MTU=8951
FLANNEL_IPMASQ=true
EOF
