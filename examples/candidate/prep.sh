#!/bin/sh

#https://docs.rke2.io/known_issues
systemctl disable --now firewalld
systemctl stop firewalld

touch /etc/NetworkManager/conf.d/rke2-canal.conf
cat <<EOF > /etc/NetworkManager/conf.d/rke2-canal.conf
[keyfile]
unmanaged-devices=interface-name:cali*;interface-name:flannel*
EOF

touch /etc/NetworkManager/conf.d/global-dns.conf
cat <<EOF > /etc/NetworkManager/conf.d/global-dns.conf
[global-dns-domain-*]
servers=::1,1.1.1.1
EOF

systemctl reload NetworkManager
systemctl stop nm-cloud-setup.service
systemctl disable nm-cloud-setup.service
systemctl stop nm-cloud-setup.timer
systemctl disable nm-cloud-setup.timer

# reboot in 2 seconds and exit this script
# this allows us to reboot without Terraform receiving errors
# WARNING: there is a race condition here, the reboot must happen before Terraform reconnects for the next script
( sleep 2 ; reboot ) & 
exit 0
