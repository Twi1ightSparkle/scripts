#!/bin/bash

if [[ $EUID -eq 0 ]]; then
	echo "This script must NOT be run as root"
	exit 1
fi

# Debian
if hash apt-get &>/dev/null; then
	sudo apt-get update
	sudo apt list --upgradable
	read -rp "Okay? Continue? [y/N] " go
	if [[ $go != "y" && $go != "Y" ]]; then
		exit 0
	fi
	sudo apt-get --yes upgrade
	sudo apt-get --yes dist-upgrade
	sudo apt-get --yes autoclean
	sudo apt-get --yes autoremove
fi

# Fedora
if hash dnf &>/dev/null; then
	sudo dnf upgrade --refresh
fi

# Flatpak
if hash flatpak &>/dev/null; then
	sudo flatpak update
fi

# Rust
if hash rustup &>/dev/null; then
	rustup update
fi

# Cargo
if hash cargo &>/dev/null; then
	if ! cargo install-update --all; then
		cargo install cargo-update
		cargo install-update --all 2>/dev/null
	fi
fi

# Kubectl krew
if hash kubectl krew &>/dev/null; then
	kubectl krew update
	kubectl krew upgrade
fi

# Check if reboot is required
if hash needs-restarting &>/dev/null; then
	needs-restarting --reboothint
elif [ -f /var/run/reboot-required ]; then
	read -rp "Reboot required, do it now? [y/N] " boot
	if [[ $boot != "y" && $boot != "Y" ]]; then
		exit 0
	else
		sudo systemctl reboot
	fi
else
	echo "Reboot not required."
fi
