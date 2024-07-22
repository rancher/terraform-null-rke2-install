#!/bin/sh
set -x
set -e

export FILE="${1}"
export REMOTE_PATH="${2}"
export IP="${3}"
export SSH_USER="${4}"

if [ "" != "$(grep ':' <<< ${IP})" ]; then
  # ipv6
  scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "${SSH_USER}"@\["${IP}"\]:"${REMOTE_PATH}" "${FILE}"
else
  # ipv4
  scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "${SSH_USER}"@"${IP}":"${REMOTE_PATH}" "${FILE}"
fi

sed -i "s/127.0.0.1/${IP}/g" "${FILE}" || sed -i '' "s/127.0.0.1/${IP}/g" "${FILE}"
