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
sudo useradd -m -s "/bin/bash" "$userToAdd"
sudo mkdir "/home/$userToAdd/.ssh"
sudo chown "$userToAdd:$userToAdd" "/home/$userToAdd/.ssh"
sudo chmod 700 "/home/$userToAdd/.ssh"
wget "$sshPubKeyUrl"
sudo mv "$sshKeyName" "/home/$userToAdd/.ssh/authorized_keys"
sudo chown "$userToAdd:$userToAdd" "/home/$userToAdd/.ssh/authorized_keys"
sudo chmod 600 "/home/$userToAdd/.ssh/authorized_keys"
cat << EOF | sudo tee -a "/home/$userToAdd/.bashrc"
alias ll='ls -la'
bind 'set bell-style none'
EOF

# Set sudo for $userToAdd
echo "$userToAdd ALL=(ALL:ALL) NOPASSWD:ALL" | sudo EDITOR='tee -a' visudo

# Set system hostname
echo "$nodeHostname" | sudo tee "/etc/hostname"

# Update SSH config
sudo sed -i "s/#Port 22/Port $sshPort/g" "/etc/ssh/sshd_config"
sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/g' "/etc/ssh/sshd_config"
sudo sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/g' "/etc/ssh/sshd_config"
sudo sed -i 's/#PermitEmptyPasswords no/PermitEmptyPasswords no/g' "/etc/ssh/sshd_config"
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
    sudo -u "$userToAdd" git clone https://github.com/Twi1ightSparkle/scripts.git "/home/$userToAdd/scripts"

# Install system updates and required base packages
sudo apt-get -y update
sudo apt-get -y upgrade
sudo apt-get -y dist-upgrade
sudo apt-get -y autoclean
sudo apt-get -y autoremove
sudo apt-get -y install \
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
