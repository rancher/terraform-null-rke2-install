#!/usr/bin/env bash
set -euo pipefail

main() {
  local workspace="${GITHUB_WORKSPACE:-$PWD}"

  docker run --rm \
    -v "${workspace}:${workspace}" \
    -w "${workspace}" \
    -e NIX_SSL_CERT_FILE="${NIX_SSL_CERT_FILE:-}" \
    -e SSL_CERT_FILE="${SSL_CERT_FILE:-}" \
    -e CURL_CA_BUNDLE="${CURL_CA_BUNDLE:-}" \
    -e TERM="${TERM:-}" \
    -e SSH_AUTH_SOCK="${SSH_AUTH_SOCK:-}" \
    -e GITHUB_TOKEN="${GITHUB_TOKEN:-}" \
    -e GITHUB_OWNER="${GITHUB_OWNER:-}" \
    -e AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-}" \
    -e AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-}" \
    -e AWS_SESSION_TOKEN="${AWS_SESSION_TOKEN:-}" \
    -e AWS_ROLE="${AWS_ROLE:-}" \
    -e AWS_REGION="${AWS_REGION:-}" \
    -e AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-}" \
    -e IDENTIFIER="${IDENTIFIER:-}" \
    -e ZONE="${ZONE:-}" \
    -e ACME_SERVER_URL="${ACME_SERVER_URL:-}" \
    -e RANCHER_INSECURE="${RANCHER_INSECURE:-}" \
    ghcr.io/rancher/ci-image/nix:20260603-18 \
    bash .github/workflows/scripts/nix-run.sh "$@"
}

main "$@"
