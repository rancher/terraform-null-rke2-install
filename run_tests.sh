#!/bin/bash

rerun_failed=false
specific_test=""
specific_package=""

while getopts ":r:t:p:" opt; do
  case $opt in
    r) rerun_failed=true ;;
    t) specific_test="$OPTARG" ;;
    p) specific_package="$OPTARG" ;;
    \?) echo "Invalid option -$OPTARG" >&2 && exit 1 ;;
  esac
done

run_tests() {
  local rerun=$1
  REPO_ROOT="$(git rev-parse --show-toplevel)"
  cd "$REPO_ROOT" || exit 1

  # Find the tests directory
  TEST_DIR=""
  if [ -d "tests" ]; then
    TEST_DIR="tests"
  elif [ -d "test/tests" ]; then
    TEST_DIR="test/tests"
  else
    echo "Error: Unable to find tests directory" >&2
    exit 1
  fi

  echo "" > "/tmp/${IDENTIFIER}_test.log"
  rm -f "/tmp/${IDENTIFIER}_failed_tests.txt"
  cat <<'EOF'> "/tmp/${IDENTIFIER}_test-processor"
echo "Passed: "
export PASS="$(jq -r '. | select(.Action == "pass") | select(.Test != null).Test' "/tmp/${IDENTIFIER}_test.log")"
echo $PASS | tr ' ' '\n'
echo " "
echo "Failed: "
export FAIL="$(jq -r '. | select(.Action == "fail") | select(.Test != null).Test' "/tmp/${IDENTIFIER}_test.log")"
echo $FAIL | tr ' ' '\n'
echo " "
if [ -n "$FAIL" ]; then
  echo $FAIL > "/tmp/${IDENTIFIER}_failed_tests.txt"
  exit 1
fi
exit 0
EOF
  chmod +x "/tmp/${IDENTIFIER}_test-processor"
  export NO_COLOR=1
  echo "starting tests..."
  cd "$TEST_DIR" || return 1;

  local rerun_flag=""
  if [ "$rerun" = true ] && [ -f "/tmp/${IDENTIFIER}_failed_tests.txt" ]; then
    # shellcheck disable=SC2002
    rerun_flag="-run=$(cat "/tmp/${IDENTIFIER}_failed_tests.txt" | tr '\n' '|')"
  fi

  local specific_test_flag=""
  if [ -n "$specific_test" ]; then
    specific_test_flag="-run=$specific_test"
  fi

  local package_pattern=""
  if [ -n "$specific_package" ]; then
    package_pattern="$specific_package"
  else
    package_pattern="..."
  fi
  # shellcheck disable=SC2086
  gotestsum \
    --format=standard-verbose \
    --jsonfile "/tmp/${IDENTIFIER}_test.log" \
    --post-run-command "sh /tmp/${IDENTIFIER}_test-processor" \
    --packages "$REPO_ROOT/$TEST_DIR/$package_pattern" \
    -- \
    -parallel=2 \
    -count=1 \
    -failfast=1 \
    -timeout=300m \
    $rerun_flag \
    $specific_test_flag

  return $?
}

if [ -z "$IDENTIFIER" ]; then
  IDENTIFIER="$(echo a-$RANDOM-d | base64 | tr -d '=')"
  export IDENTIFIER
fi
echo "id is: $IDENTIFIER..."
if [ -z "$GITHUB_TOKEN" ]; then echo "GITHUB_TOKEN isn't set"; else echo "GITHUB_TOKEN is set"; fi
if [ -z "$GITHUB_OWNER" ]; then echo "GITHUB_OWNER isn't set"; else echo "GITHUB_OWNER is set"; fi
if [ -z "$ZONE" ]; then echo "ZONE isn't set"; else echo "ZONE is set"; fi

# Run tests initially
run_tests false

# Check if we need to rerun failed tests
if [ "$rerun_failed" = true ] && [ -f "/tmp/${IDENTIFIER}_failed_tests.txt" ]; then
  echo "Rerunning failed tests..."
  run_tests true
fi

echo "Clearing leftovers with Id $IDENTIFIER in $AWS_REGION..."
sleep 60

if [ -n "$IDENTIFIER" ]; then
  attempts=0
  # shellcheck disable=SC2143
  while [ -n "$(leftovers -d --iaas=aws --aws-region="$AWS_REGION" --filter="Id:$IDENTIFIER" | grep -v 'AccessDenied')" ] && [ $attempts -lt 3 ]; do
    leftovers --iaas=aws --aws-region="$AWS_REGION" --filter="Id:$IDENTIFIER" --no-confirm | grep -v 'AccessDenied' || true
    sleep 10
    attempts=$((attempts + 1))
  done

  if [ $attempts -eq 3 ]; then
    echo "Warning: Failed to clear all resources after 3 attempts."
  fi

  attempts=0
  # shellcheck disable=SC2143
  while [ -n "$(leftovers -d --iaas=aws --aws-region="$AWS_REGION" --type="ec2-key-pair" --filter="tf-$IDENTIFIER" | grep -v 'AccessDenied')" ] && [ $attempts -lt 3 ]; do
    leftovers --iaas=aws --aws-region="$AWS_REGION" --type="ec2-key-pair" --filter="tf-$IDENTIFIER" --no-confirm | grep -v 'AccessDenied' || true
    sleep 10
    attempts=$((attempts + 1))
  done

  if [ $attempts -eq 3 ]; then
    echo "Warning: Failed to clear all EC2 key pairs after 3 attempts."
  fi
fi

if [ -f "/tmp/${IDENTIFIER}_failed_tests.txt" ]; then
  echo "done, test failed"
  exit 1
else
  echo "done, test passed"
  exit 0
fi
