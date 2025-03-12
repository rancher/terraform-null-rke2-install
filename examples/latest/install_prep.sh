#!/bin/bash
set -e
set -x

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root" >&2
  exit 1
fi
zypper --gpg-auto-import-keys --non-interactive ar -f https://download.opensuse.org/distribution/leap/15.6/repo/oss/ repo-oss || true
zypper --gpg-auto-import-keys --non-interactive ar -f https://download.opensuse.org/distribution/leap/15.6/repo/non-oss/ repo-non-oss || true
zypper --gpg-auto-import-keys --non-interactive ar -f https://download.opensuse.org/repositories/security:/SELinux_legacy/15.5/security:SELinux_legacy.repo || true
rpm --import https://rpm.rancher.io/public.key || true

timeout 10m zypper --gpg-auto-import-keys --non-interactive refresh
timeout 5m zypper --gpg-auto-import-keys --non-interactive install -n -y --force restorecond policycoreutils curl
