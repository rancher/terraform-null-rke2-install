#!/bin/bash

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root" >&2
  exit 1
fi

# Detect the OS
if [ -f /etc/os-release ]; then
  cat /etc/os-release
  . /etc/os-release
  OS=$ID
  VERSION=$VERSION_ID
else
  echo "Unsupported OS" >&2
  exit 1
fi

# Function to install and configure SELinux on SUSE
install_selinux_suse() {

  rpm --import https://download.opensuse.org/repositories/security:SELinux_legacy/SLE_15_SP2/repodata/repomd.xml.key

  timeout 5m zypper install -n -y --replacefiles restorecond policycoreutils setools-console

  zypper ar -f https://download.opensuse.org/repositories/security:SELinux_legacy/SLE_15_SP2/security:SELinux_legacy.repo
  zypper refresh
  timeout 5m zypper install -n -y container-selinux
  wget https://rpm.rancher.io/public.key -O rancher_public.key
  rpm --import rancher_public.key
}

# Function to install and configure SELinux on RHEL, Rocky, AlmaLinux, Liberty, and Oracle Linux (for versions 8 and 9)
install_selinux_rhel_rocky_alma_liberty_oracle() {
  echo "Updating the system..."
  dnf update -y
}

# Function to install and configure SELinux on RHEL 7, Liberty 7, and Oracle Linux 7
install_selinux_rhel7_liberty7_oracle7() {
  echo "Updating the system..."
  yum update -y
}

# Main script logic
case "$OS" in
  "sles")
      echo "found supported OS $OS..."
      if [ -n "$(grep '^15.5' <<< $VERSION)" ]; then
        echo "found supported version $VERSION..."
        install_selinux_suse
      fi
    ;;
  "rhel" | "rocky" | "almalinux" | "liberty" | "ol")
      echo "found supported OS $OS..."
      if [ -n "$(grep '^7' <<< $VERSION)" ]; then
        echo "found supported version $VERSION..."
        install_selinux_rhel7_liberty7_oracle7
      elif [ -n "$(grep '^8' <<< $VERSION)" ] || [ -n "$(grep '^9' <<< $VERSION)" ]; then
        echo "found supported version $VERSION..."
        install_selinux_rhel_rocky_alma_liberty_oracle
      else
        echo "Unsupported version: $VERSION" >&2
        exit 1
      fi
    ;;
  *)
    echo "Unsupported OS: $OS" >&2
    exit 1
    ;;
esac

# reboot in 2 seconds and exit this script
# this allows us to reboot without Terraform receiving errors
# WARNING: there is a race condition here, the reboot must happen before Terraform reconnects for the next script
( sleep 2 ; reboot ) &
exit 0
