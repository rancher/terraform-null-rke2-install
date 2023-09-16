#!/bin/sh
set -x
set -e
REMOTE_PATH="${1}"
install -d "${REMOTE_PATH}"
cd "${REMOTE_PATH}"
install -d /etc/rancher/rke2/config.yaml.d
find ./ -name '*.yaml' -exec cp -prv '{}' '/etc/rancher/rke2/config.yaml.d/' ';'
ls -lah /etc/rancher/rke2/config.yaml.d
