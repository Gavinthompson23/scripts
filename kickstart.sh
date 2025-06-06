#!/bin/bash
# System language
#lang en_US.UTF-8

# Keyboard layouts
#keyboard us

# System timezone
#timezone PT --utc

# Shutdown after installation
#shutdown

# Use text mode install and CDROM installation media
#text
#cdrom

# This command is required when performing an unattended installation on a system with previously
# initialized disks.
#zerombr

# Automatically creates partitions required by your hardware platform, eg /boot/efi or biosboot
#reqpart

# Network information
#network --hostname=localhost.localdomain
# note: do not set any other network options. dhcp is the default anyway, and setting them here disregards the ip and nameserver settings on the kernel command line
# network --bootproto=dhcp --device=link --activate --onboot=on

# Do not configure the X Window System
#skipx

# Disable the Setup Agent on first boot
#firstboot --disable

# State of SELinux on the installed system
#selinux --enforcing

# Firewalling should be done later on by the admin. Required for the cloud
#firewall --disable

# System services
#services --disabled="kdump" --enabled="NetworkManager,sshd"

# Disable kdump by default, frees up some memory
#%addon com_redhat_kdump --disable
#%end

#%include /tmp/dynamic.ks


#%packages
#@core
sudo apt install docker.io
#%end

#%post
curl -sSL https://raw.githubusercontent.com/bitnami/containers/main/bitnami/wordpress/docker-compose.yml > docker-compose.yml
docker-compose up -d
sudo systemctl enable docker
sudo systemctl start docker
#%end
