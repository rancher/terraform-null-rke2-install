#!/bin/sh
set -x
set -e
REMOTE_PATH="${1}"
install -d "${REMOTE_PATH}"
cd "${REMOTE_PATH}"
sudo install -d /etc/rancher/rke2/config.yaml.d
sudo find ./ -name '*.yaml' -exec cp -prv '{}' '/etc/rancher/rke2/config.yaml.d/' ';'
sudo ls -lah /etc/rancher/rke2/config.yaml.d
