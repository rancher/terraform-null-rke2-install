#!/bin/sh
set -x
set -eu

file="${1}"
remote_path="${2}"
ip="${3}"
ssh_user="${4}"

case "${ip}" in
  *:*)
    # ipv6
    scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "${ssh_user}"@\["${ip}"\]:"${remote_path}" "${file}"
    ;;
  *)
    # ipv4
    scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "${ssh_user}"@"${ip}":"${remote_path}" "${file}"
    ;;
esac

sed "s/127.0.0.1/${ip}/g" "${file}" > "${file}.tmp" && mv -f "${file}.tmp" "${file}"
sed "s/::1/${ip}/g" "${file}" > "${file}.tmp" && mv -f "${file}.tmp" "${file}"
chmod 0600 "${file}"
