#!/bin/sh
# This is run after install, but before the rke2 service is started for the first time

#https://docs.rke2.io/known_issues
systemctl disable --now firewalld
systemctl stop firewalld

touch /etc/NetworkManager/conf.d/rke2-canal.conf
cat <<EOF > /etc/NetworkManager/conf.d/rke2-canal.conf
[keyfile]
unmanaged-devices=interface-name:cali*;interface-name:flannel*
EOF

systemctl reload NetworkManager
systemctl stop nm-cloud-setup.service
systemctl disable nm-cloud-setup.service
systemctl stop nm-cloud-setup.timer
systemctl disable nm-cloud-setup.timer

CIS_CONF=$(find / -type f -path '*/share/rke2/rke2-cis-sysctl.conf' 2>/dev/null)
cp -f "${CIS_CONF}" /etc/sysctl.d/60-rke2-cis.conf
systemctl restart systemd-sysctl
useradd -r -c "etcd user" -s /sbin/nologin -M etcd -U

# reboot in 2 seconds and exit this script
# this allows us to reboot without Terraform receiving errors
# WARNING: there is a race condition here, the reboot must happen before Terraform reconnects for the next script
( sleep 2 ; reboot ) & 
exit 0
