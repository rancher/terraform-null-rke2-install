#!/bin/bash
set -e
set -x

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root" >&2
  exit 1
fi

rpm --import https://download.opensuse.org/repositories/security:SELinux_legacy/SLE_15_SP2/repodata/repomd.xml.key
timeout 5m zypper install -n -y --replacefiles restorecond policycoreutils setools-console
zypper ar -f https://download.opensuse.org/repositories/security:SELinux_legacy/SLE_15_SP2/security:SELinux_legacy.repo
zypper refresh
timeout 5m zypper install -n -y container-selinux
wget https://rpm.rancher.io/public.key -O rancher_public.key
rpm --import rancher_public.key

# reboot in 2 seconds and exit this script
# this allows us to reboot without Terraform receiving errors
# WARNING: there is a race condition here, the reboot must happen before Terraform reconnects for the next script
( sleep 2 ; reboot ) &
exit 0
