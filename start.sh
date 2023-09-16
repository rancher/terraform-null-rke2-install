#!/bin/sh
set -x
set -e
ROLE="${1}"
SERVICE_NAME="rke2-${ROLE}.service"
if [ "$(systemctl is-active "${SERVICE_NAME}")" = "active" ]; then
 systemctl stop "${SERVICE_NAME}"
fi
systemctl daemon-reload
systemctl enable "${SERVICE_NAME}"
systemctl start "${SERVICE_NAME}"
