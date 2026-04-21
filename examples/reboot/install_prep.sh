#!/bin/bash
set -e
set -x

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root" >&2
  exit 1
fi

# Add repositories and install packages in the next snapshot using transactional-update
transactional-update --non-interactive --continue shell <<'EOF'
zypper --gpg-auto-import-keys --non-interactive ar -f https://download.opensuse.org/distribution/leap/15.6/repo/oss/ repo-oss || true
zypper --gpg-auto-import-keys --non-interactive ar -f https://download.opensuse.org/distribution/leap/15.6/repo/non-oss/ repo-non-oss || true
zypper --gpg-auto-import-keys --non-interactive ar -f https://download.opensuse.org/repositories/security:/SELinux_legacy/15.5/security:SELinux_legacy.repo || true
rpm --import https://rpm.rancher.io/public.key || true
zypper --gpg-auto-import-keys --non-interactive refresh
zypper --gpg-auto-import-keys --non-interactive install -y --force-resolution restorecond policycoreutils curl
EOF
