#!/bin/bash
set -e
set -x

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root" >&2
  exit 1
fi

rpm --import https://download.opensuse.org/repositories/security:/SELinux_legacy/15.5/repodata/repomd.xml.key || true
zypper ar -f https://download.opensuse.org/repositories/security:/SELinux_legacy/15.5/security:SELinux_legacy.repo || true
rpm --import https://rpm.rancher.io/public.key || true

zypper refresh
# zypper update --no-confirm
timeout 5m zypper install -n -y restorecond policycoreutils setools-console
