#!/bin/sh
set -x
set -eu

check_ssh_agent() {
  if [ -z "${SSH_AUTH_SOCK:-}" ]; then
    echo "Warning: SSH_AUTH_SOCK is not set. We will rely on default SSH keys (e.g., ~/.ssh/id_ed25519)." >&2
  elif ! ssh-add -l >/dev/null 2>&1; then
    echo "Error: ssh-agent is running but no keys are loaded. Please run 'ssh-add' to load your private key." >&2
    exit 1
  else
    echo "ssh-agent is running and has keys loaded:" >&2
    ssh-add -l >&2
  fi
}

FILE="${1}"
REMOTE_PATH="${2}"
IP="${3}"
SSH_USER="${4}"

check_ssh_agent

AGENT_OPTS=""
if [ -n "${SSH_AUTH_SOCK:-}" ]; then
  # Explicitly setting IdentityAgent forces OpenSSH to use the socket, bypassing
  # edge cases where macOS subshells or scp might otherwise drop the environment.
  AGENT_OPTS="-o IdentityAgent=${SSH_AUTH_SOCK}"
fi

case "${IP}" in
  *:*)
    # ipv6
    # shellcheck disable=SC2086 # AGENT_OPTS must word-split to pass correctly
    scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${AGENT_OPTS} "${SSH_USER}"@\["${IP}"\]:"${REMOTE_PATH}" "${FILE}"
    ;;
  *)
    # ipv4
    # shellcheck disable=SC2086
    scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${AGENT_OPTS} "${SSH_USER}"@"${IP}":"${REMOTE_PATH}" "${FILE}"
    ;;
esac

sed "s/127.0.0.1/${IP}/g" "${FILE}" > "${FILE}.tmp" && mv -f "${FILE}.tmp" "${FILE}"
sed "s/::1/${IP}/g" "${FILE}" > "${FILE}.tmp" && mv -f "${FILE}.tmp" "${FILE}"
chmod 0600 "${FILE}"
