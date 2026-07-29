#!/usr/bin/env bash
#
# Skill: run-tests.sh
# Description: Runs the test suite inside the Nix environment, capturing output and enabling Terraform JSON logs.
# Usage: .agent/skills/run-tests.sh [-t <TestName>] [-p <PackageName>] [-o <OutputFile>] [-l <TfLogFile>]

set -euo pipefail

TEST_NAME=""
PACKAGE_NAME=""
OUTPUT_FILE="test_run.log"
TF_LOG_FILE="terraform_json.log"

while getopts "t:p:o:l:" opt; do
  case $opt in
    t) TEST_NAME="$OPTARG" ;;
    p) PACKAGE_NAME="$OPTARG" ;;
    o) OUTPUT_FILE="$OPTARG" ;;
    l) TF_LOG_FILE="$OPTARG" ;;
    *) echo "Usage: $0 [-t <TestName>] [-p <PackageName>] [-o <OutputFile>] [-l <TfLogFile>]" && exit 1 ;;
  esac
done

ARGS=""
if [ -n "$TEST_NAME" ]; then
  ARGS="-t $TEST_NAME"
elif [ -n "$PACKAGE_NAME" ]; then
  ARGS="-p $PACKAGE_NAME"
fi

echo "Running tests in Nix environment..."
echo "Redirecting test output to: $OUTPUT_FILE"
echo "Terraform JSON logs will be written to: $TF_LOG_FILE"

# Prepare clean log files
rm -f "$OUTPUT_FILE" "$TF_LOG_FILE"

# Run tests under Nix development shell with TF_LOG=json
nix develop --ignore-environment \
  --extra-experimental-features nix-command \
  --extra-experimental-features flakes \
  --keep HOME --keep SSH_AUTH_SOCK \
  --keep GPG_SIGNING_KEY \
  --keep NIX_SSL_CERT_FILE \
  --keep NIX_ENV_LOADED \
  --keep TERM \
  --keep AWS_ACCESS_KEY_ID --keep AWS_SECRET_ACCESS_KEY --keep AWS_SESSION_TOKEN --keep AWS_REGION \
  --command bash -c "export TF_LOG=json; export TF_LOG_PATH=\"\$(pwd)/$TF_LOG_FILE\"; ./run_tests.sh $ARGS" > "$OUTPUT_FILE" 2>&1 || true

echo "Test run completed."
