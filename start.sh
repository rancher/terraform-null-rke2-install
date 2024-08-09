#!/bin/sh
set -e

ROLE="${1}"
SERVICE_NAME="rke2-${ROLE}.service"
TIMEOUT="${2}" # timeout in minutes

# Function to print a message with a timestamp
log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Function to get the last 20 lines of a log file and print with a header
get_last_20_lines() {
  log_path="$1"
  log_name="$2"

  if [ -f "$log_path" ]; then
    log "Last 20 lines of $log_name log:"
    tail -n 20 "$log_path" || true
    log "------------------------"
  else
    log "$log_name log file not found"
    log "------------------------"
  fi
}

# Stop the service if it's already active
if [ "$(systemctl is-active "${SERVICE_NAME}")" = "active" ]; then
  log "Stopping ${SERVICE_NAME}..."
  systemctl stop "${SERVICE_NAME}"
fi

# Reload systemd daemon and enable the service
log "Reloading systemd daemon and enabling ${SERVICE_NAME}..."
systemctl daemon-reload
systemctl enable "${SERVICE_NAME}"

# Start the service in the background
log "Starting ${SERVICE_NAME}..."
systemctl start "${SERVICE_NAME}" &

EXIT=0
max_attempts=$((TIMEOUT * 60 / 10))
attempts=0
interval=10

# Wait for the service to become active or timeout
while [ "$(systemctl is-active "${SERVICE_NAME}")" != "active" ]; do
  log "${SERVICE_NAME} status is \"$(systemctl is-active "${SERVICE_NAME}")\""
  attempts=$((attempts + 1))
  if [ ${attempts} -eq ${max_attempts} ]; then EXIT=1; break; fi
  sleep ${interval}
done

log "${SERVICE_NAME} status is \"$(systemctl is-active "${SERVICE_NAME}")\""

# If the service failed to start, collect logs for troubleshooting
if [ $EXIT -eq 1 ]; then
  log "Timed out attempting to start service:"

  log "status:"
  systemctl status "${SERVICE_NAME}" > status.log 2>&1 || true
  cat status.log || true

  log "last 20 lines of journal:"
  journalctl --lines 20 --unit "${SERVICE_NAME}" > last20.log 2>&1 || true
  cat last20.log || true

  log "first 20 lines of journal:"
  journalctl --reverse --lines +20 --unit "${SERVICE_NAME}" > first20.log 2>&1 || true
  cat first20.log || true

  log "rke2 config files:"
  for file in /etc/rancher/rke2/config.yaml.d/*.yaml; do
    if [ -f "$file" ]; then
      log "File: $file"
      cat "$file" || true
      log "------------------------"
    fi
  done


  # Process logs using the get_last_20_lines function
  get_last_20_lines "/var/lib/rancher/rke2/agent/logs/kubelet.log" "kubelet"
  get_last_20_lines "/var/lib/rancher/rke2/agent/containerd/containerd.log" "containerd"

  log_dir="/var/log/pods"
  kube_apiserver_log=$(find "$log_dir" -type f -name "kube-system_kube-apiserver-*" -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2)
  get_last_20_lines "$kube_apiserver_log" "kube-apiserver"

  etcd_log=$(find "$log_dir" -type f -name "kube-system_etcd-*" -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2)
  get_last_20_lines "$etcd_log" "etcd"
fi

exit $EXIT
