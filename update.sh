#!/bin/bash

# Remember to convert to linux format. In vim on the webserver, do
# :set ff=unix
# :wq

if [[ $EUID -ne 0 ]]; then
	echo "This script must be run as root"
	exit 1
fi

apt update
apt list --upgradable

read -p "Okay? Continue? [y/N] " go
if [[ $go != "y" && $go != "Y" ]]; then
	exit 0
fi

apt -y upgrade
apt -y dist-upgrade
apt -y autoclean
apt -y autoremove

if [ -f /var/run/reboot-required ]; then
	read -p "Reboot required, do it now? [y/N] " boot
	if [[ $boot != "y" && $boot != "Y" ]]; then
		exit 0
	else
		reboot
	fi
else
	echo "Reboot not required."
fi