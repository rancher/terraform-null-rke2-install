#!/bin/sh
# WARNING: This assumes a linux style OS
set -x
set -e
ROLE="${1}"
REMOTE_PATH="${2}"
RELEASE="${3}"
INSTALL_METHOD="${4}"
CHANNEL="${5}"

if [ "$(systemctl is-active rke2-"${ROLE}".service)" = "active" ]; then
  systemctl stop rke2-"${ROLE}".service
fi
unset INSTALL_RKE2_CHANNEL;
unset INSTALL_RKE2_VERSION;

if [ "${RELEASE}" = "latest" ]; then
  export INSTALL_RKE2_CHANNEL="${RELEASE}"
elif [ "${RELEASE}" = "stable" ]; then
  export INSTALL_RKE2_CHANNEL="${RELEASE}"
else
  export INSTALL_RKE2_VERSION="${RELEASE}"
fi
if [ "" != "${CHANNEL}" ]; then
  if [ "" = "${INSTALL_RKE2_CHANNEL}" ]; then
    export INSTALL_RKE2_CHANNEL="${CHANNEL}"
  fi
fi
export INSTALL_RKE2_METHOD="${INSTALL_METHOD}"
export INSTALL_RKE2_TYPE="${ROLE}"

if [ "${INSTALL_METHOD}" = "rpm" ]; then 
  unset INSTALL_RKE2_ARTIFACT_PATH;
else
  export INSTALL_RKE2_ARTIFACT_PATH="${REMOTE_PATH}";
fi
if [ ! -f "${REMOTE_PATH}"/install.sh ]; then
  curl -vfL https://get.rke2.io -o "${REMOTE_PATH}"/install.sh
fi

chmod +x "${REMOTE_PATH}"/install.sh
echo "running install script..."
"${REMOTE_PATH}"/install.sh
