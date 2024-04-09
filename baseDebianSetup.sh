#!/bin/bash

# Ensure script is only ran once to prevent duplicated stuff
if test -f "/var/baseDebianSetupScriptHasBeenRun"; then
    echo "Script has already been ran on this system. Exiting"
    exit 1
fi
sudo touch "/var/baseDebianSetupScriptHasBeenRun"

read -rp "System FQDN: " nodeHostname
read -rp "User to add: " userToAdd
read -rp "SSH public key URL: " sshPubKeyUrl
read -rp "SSH port: " sshPort

sshKeyName="${sshPubKeyUrl##*/}"
sshKeyBase="${sshKeyName%.*}"

# Add user $userToAdd and set up SSH
sudo useradd --create-home --shell "/bin/bash" "$userToAdd"
sudo mkdir "/home/$userToAdd/.ssh"
sudo chown "$userToAdd:$userToAdd" "/home/$userToAdd/.ssh"
sudo chmod 700 "/home/$userToAdd/.ssh"
wget "$sshPubKeyUrl"
sudo mv "$sshKeyName" "/home/$userToAdd/.ssh/authorized_keys"
sudo chown "$userToAdd:$userToAdd" "/home/$userToAdd/.ssh/authorized_keys"
sudo chmod 600 "/home/$userToAdd/.ssh/authorized_keys"
cat << EOF | sudo tee --append "/home/$userToAdd/.bashrc"

alias ll='ls -la'
bind 'set bell-style none'

if hash kubectl 2>/dev/null; then
    source <(kubectl completion bash)
    alias k=kubectl
    complete -o default -F __start_kubectl k
fi
EOF

# Set sudo for $userToAdd
echo "$userToAdd ALL=(ALL:ALL) NOPASSWD:ALL" | sudo EDITOR='tee --append' visudo

# Set system hostname
echo "$nodeHostname" | sudo tee "/etc/hostname"
sudo sed --in-place --regexp-extended "s#^(127\.0\.0\.1.+)#\1 ${nodeHostname}#g" "/etc/hosts"

# Update SSH config
sudo sed --in-place "s/#Port 22/Port $sshPort/g" "/etc/ssh/sshd_config"
sudo sed --in-place 's/#PermitRootLogin prohibit-password/PermitRootLogin no/g' "/etc/ssh/sshd_config"
sudo sed --in-place 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/g' "/etc/ssh/sshd_config"
sudo sed --in-place 's/#PermitEmptyPasswords no/PermitEmptyPasswords no/g' "/etc/ssh/sshd_config"
sudo systemctl restart ssh
sudo systemctl restart sshd

cat << EOF



SSH config updated, test SSH with "ssh -i ~/.ssh/$sshKeyBase -p $sshPort $userToAdd@$nodeHostname".
Remember to test sudo.
Press enter to continue when successful
EOF
read -r

# Disable ssh for root and admin
sudo rm "/root/.ssh/authorized_keys"
sudo rm "/home/admin/.ssh/authorized_keys"

# Clone this script repo to $userToAdd's home directory
[[ ! -d "/home/$userToAdd/scripts" ]] &&
    sudo --user "$userToAdd" git clone https://github.com/Twi1ightSparkle/scripts.git "/home/$userToAdd/scripts"

# Install system updates and required base packages
sudo apt-get --assume-yes update
sudo apt-get --assume-yes upgrade
sudo apt-get --assume-yes dist-upgrade
sudo apt-get --assume-yes autoclean
sudo apt-get --assume-yes autoremove
sudo apt-get --assume-yes install \
    git \
    htop \
    rsync \
    tmux \
    vim

# Reboot system to apply updates and hostname
cat << EOF



Base system config completed.
Press enter to reboot system
EOF
read -r
sudo systemctl reboot
