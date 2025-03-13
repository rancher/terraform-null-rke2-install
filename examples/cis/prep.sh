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

# Backup GRUB configuration
if [ -f /etc/default/grub ]; then
  cp /etc/default/grub /etc/default/grub.bak
  echo "Backed up /etc/default/grub to /etc/default/grub.bak"
else
  echo "/etc/default/grub not found. Exiting."
  exit 1
fi

# Check if cgroup v2 is already enabled
if mount | grep -q "cgroup on /sys/fs/cgroup type cgroup"; then
  echo "cgroup v2 already enabled. Exiting."
  exit 0
fi

# Add cgroup v2 kernel parameter to GRUB configuration
if grep -q "systemd.unified_cgroup_hierarchy=1" /etc/default/grub; then
    echo "cgroup v2 parameter already present in GRUB. Skipping."
else
    sed -i 's/GRUB_CMDLINE_LINUX="\(.*\)"/GRUB_CMDLINE_LINUX="\1 systemd.unified_cgroup_hierarchy=1"/g' /etc/default/grub
    echo "Added systemd.unified_cgroup_hierarchy=1 to GRUB_CMDLINE_LINUX"
fi

# Disable IPv6
if grep -q "ipv6.disable=1" /etc/default/grub; then
    echo "IPv6 disable parameter already present. Skipping."
else
    sed -i 's/GRUB_CMDLINE_LINUX="\(.*\)"/GRUB_CMDLINE_LINUX="\1 ipv6.disable=1"/g' /etc/default/grub
    echo "Added ipv6.disable=1 to GRUB_CMDLINE_LINUX"
fi

# Update GRUB configuration
if [ -f /boot/efi/EFI/redhat/grub.cfg ]; then
  grub2-mkconfig -o /boot/efi/EFI/redhat/grub.cfg
  echo "Updated /boot/efi/EFI/redhat/grub.cfg"
elif [ -f /boot/grub2/grub.cfg ]; then
  grub2-mkconfig -o /boot/grub2/grub.cfg
  echo "Updated /boot/grub2/grub.cfg"
else
  echo "GRUB configuration file not found. Please check /boot directory."
  exit 1
fi

# reboot in 2 seconds and exit this script
# this allows us to reboot without Terraform receiving errors
# WARNING: there is a race condition here, the reboot must happen before Terraform reconnects for the next script
( sleep 2 ; reboot ) & 
exit 0
