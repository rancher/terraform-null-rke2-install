#!/bin/sh
set -x
set -e
ROLE="${1}"
REMOTE_PATH="${2}"
RELEASE="${3}"
INSTALL_METHOD="${4}"

if [ "$(systemctl is-active rke2-"${ROLE}".service)" = "active" ]; then
  systemctl stop rke2-"${ROLE}".service
fi

export INSTALL_RKE2_CHANNEL="${RELEASE}"
export INSTALL_RKE2_METHOD="${INSTALL_METHOD}"

if [ "${INSTALL_METHOD}" = "rpm" ]; then 
  export INSTALL_RKE2_ARTIFACT_PATH="";
else
  export INSTALL_RKE2_ARTIFACT_PATH="${REMOTE_PATH}";
fi
if [ ! -f "${REMOTE_PATH}"/install.sh ]; then
  curl -sfL https://get.rke2.io -o "${REMOTE_PATH}"/install.sh
fi

chmod +x "${REMOTE_PATH}"/install.sh
"${REMOTE_PATH}"/install.sh