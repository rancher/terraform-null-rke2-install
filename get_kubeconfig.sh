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

main() {
  local file="${1}"
  local remote_path="${2}"
  local ip="${3}"
  local ssh_user="${4}"

  check_ssh_agent

  local agent_opts=""
  if [ -n "${SSH_AUTH_SOCK:-}" ]; then
    # Explicitly setting IdentityAgent forces OpenSSH to use the socket, bypassing
    # edge cases where macOS subshells or scp might otherwise drop the environment.
    agent_opts="-o IdentityAgent=${SSH_AUTH_SOCK}"
  fi

  case "${ip}" in
    *:*)
      # ipv6
      # shellcheck disable=SC2086 # agent_opts must word-split to pass correctly
      scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${agent_opts} "${ssh_user}"@\["${ip}"\]:"${remote_path}" "${file}"
      ;;
    *)
      # ipv4
      # shellcheck disable=SC2086
      scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${agent_opts} "${ssh_user}"@"${ip}":"${remote_path}" "${file}"
      ;;
  esac

  sed "s/127.0.0.1/${ip}/g" "${file}" > "${file}.tmp" && mv -f "${file}.tmp" "${file}"
  sed "s/::1/${ip}/g" "${file}" > "${file}.tmp" && mv -f "${file}.tmp" "${file}"
  chmod 0600 "${file}"
}

main "$@"
