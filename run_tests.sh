#!/bin/bash

rerun_failed=false
specific_test=""
specific_package=""
cleanup_id=""
slow_mode=false
dirty_mode=false
speed=6

while getopts ":rsdt:p:c:n:" opt; do
  case $opt in
    r) rerun_failed=true ;;
    t) specific_test="$OPTARG" ;;
    p) specific_package="$OPTARG" ;;
    c) cleanup_id="$OPTARG" ;;
    d) dirty_mode=true ;;
    s) slow_mode=true ;;
    n) speed="$OPTARG" ;;
    \?) cat <<EOT >&2 && exit 1 ;;
Invalid option -$OPTARG, valid options are
  -r to re-run failed tests
  -s to run tests in slow mode (one at a time to avoid AWS rate limiting)
  -c to run clean up only with the given id (eg. abc123)
  -d to skip cleanup (dirty mode)
  -t to specify a specific test (eg. TestBase)
  -p to specify a specific test package (eg. one)
  -n to specify the speed (number of tests/packages to run in parallel)
Only one of -c, -t, or -p can be used at a time.
EOT
  esac
done

if [ "$slow_mode" = true ]; then
  echo "Running in slow mode: tests will be run one at a time to avoid AWS rate limiting."
else
  echo "Running in normal mode: tests will be run with speed $speed."
fi

if [ "$rerun_failed" = true ]; then
  echo "Rerun failed tests is enabled."
else
  echo "Rerun failed tests is disabled."
fi

if [ -n "$specific_test" ]; then
  echo "Specific test to run: $specific_test"
else
  echo "No specific test to run."
fi

if [ -n "$specific_package" ]; then
  echo "Specific package to run: $specific_package"
else
  echo "No specific package to run."
fi

if [ -n "$cleanup_id" ]; then
  echo "Cleanup only mode enabled with id: $cleanup_id"
fi

count=0
[ -n "$cleanup_id" ] && count=$((count + 1))
[ -n "$specific_test" ] && count=$((count + 1))
[ -n "$specific_package" ] && count=$((count + 1))
if [ "$count" -gt 1 ]; then
  echo "Error: Only one of -c, -t, or -p can be used at a time." >&2
  exit 1
fi

if [ "$dirty_mode" = true ]; then
  echo "Running in dirty mode: skipping cleanup."
else
  echo "Running in normal mode: cleanup will try to remove all resources matching ID."
fi

if [ -n "$cleanup_id" ]; then
  export IDENTIFIER="$cleanup_id"
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Find the tests directory
TEST_DIR=""
for dir in "test" "tests" "test/tests"; do
  if [ -d "$dir" ]; then
    TEST_DIR="$dir"
    break
  fi
done

if [ -z "$TEST_DIR" ]; then
  echo "Error: Unable to find tests directory" >&2
  exit 1
fi

run_tests() {
  local rerun=$1
  local slow_mode=$2
  cd "$REPO_ROOT" || exit 1

  echo "" > "/tmp/${IDENTIFIER}_test.log"
  rm -f "/tmp/${IDENTIFIER}_failed_tests.txt"

  cat <<'EOF'> "/tmp/${IDENTIFIER}_test-processor"
echo "Passed: "
export PASS="$(jq -r '. | select(.Action == "pass") | select(.Test != null).Test' "/tmp/${IDENTIFIER}_test.log")"
echo "$PASS" | tr ' ' '\n'
echo " "
echo "Failed: "
export FAIL="$(jq -r '. | select(.Action == "fail") | select(.Test != null).Test' "/tmp/${IDENTIFIER}_test.log")"
echo "$FAIL" | tr ' ' '\n'
echo " "
if [ -n "$FAIL" ]; then
  echo "$FAIL" > "/tmp/${IDENTIFIER}_failed_tests.txt"
  exit 1
fi
exit 0
EOF
  chmod +x "/tmp/${IDENTIFIER}_test-processor"
  export NO_COLOR=1
  echo "starting tests..."
  cd "$TEST_DIR" || return 1

  local rerun_flag=""
  if [ "$rerun" = true ] && [ -f "/tmp/${IDENTIFIER}_failed_tests.txt" ]; then
    rerun_flag="-run=$(cat "/tmp/${IDENTIFIER}_failed_tests.txt" | tr '\n' '|')"
  fi

  local specific_test_flag=""
  if [ -n "$specific_test" ]; then
    specific_test_flag="-run=$specific_test"
  fi

  local package_pattern="..."
  if [ -n "$specific_package" ]; then
    package_pattern="$specific_package"
  fi

  local args=(
    --format=standard-verbose
    --jsonfile "/tmp/${IDENTIFIER}_test.log"
    --post-run-command "sh /tmp/${IDENTIFIER}_test-processor"
    --packages "$REPO_ROOT/$TEST_DIR/$package_pattern"
    --
    -count=1
    -timeout=300m
    -failfast
  )

  local current_speed=$speed
  if [ "$slow_mode" = true ]; then
    echo "Running in slow mode..."
    current_speed=1
  fi

  # We need both -p and -parallel, as -p sets the number of packages to test in parallel,
  #  and -parallel sets the number of tests to run in parallel.
  # By setting both to 1, we ensure that tests are run sequentially, which can help avoid AWS rate limiting issues.
  args+=("-p=$current_speed" "-parallel=$current_speed")

  if [ -n "$rerun_flag" ]; then args+=("$rerun_flag"); fi
  if [ -n "$specific_test_flag" ]; then args+=("$specific_test_flag"); fi

  echo "Running command: gotestsum ${args[*]}"
  gotestsum "${args[@]}"

  return $?
}

if [ -z "$IDENTIFIER" ]; then
  IDENTIFIER="$(echo "a-$RANDOM-d" | base64 | tr -d '=')"
  export IDENTIFIER
fi
echo "id is: $IDENTIFIER..."
if [ -z "$GITHUB_TOKEN" ]; then echo "GITHUB_TOKEN isn't set"; else echo "GITHUB_TOKEN is set"; fi
if [ -z "$GITHUB_OWNER" ]; then echo "GITHUB_OWNER isn't set"; else echo "GITHUB_OWNER is set"; fi
if [ -z "$ZONE" ]; then echo "ZONE isn't set"; else echo "ZONE is set"; fi

if [ "$dirty_mode" = true ]; then
  echo "Running in dirty mode, skipping cleanup..."
else
  trap 'echo "Starting cleanup..."; [ -n "$GLOBAL_TF_PLUGIN_CACHE" ] && chmod -R u+w "$GLOBAL_TF_PLUGIN_CACHE" 2>/dev/null || true; rm -rf "$GLOBAL_TF_PLUGIN_CACHE" 2>/dev/null || true; bash "$REPO_ROOT/cleanup.sh" "$IDENTIFIER"' EXIT
fi

if [ -z "$cleanup_id" ]; then

  D="$(pwd)"

  echo "tidying..."
  cd "$REPO_ROOT/$TEST_DIR" || exit
  if ! go mod tidy; then C=$?; echo "failed to tidy, exit code $C"; exit $C; fi

  echo "formatting tests..."
  gofmt -s -w -e .
  echo "done formatting"

  echo "checking tests for compile errors..."
  while IFS= read -r file; do
    echo "found $file";
    if ! go test -c "$file" -o "${file}.test"; then C=$?; echo "failed to compile $file, exit code $C"; exit $C; fi
    rm -rf "${file}.test"
  done <<< "$(find "$REPO_ROOT/$TEST_DIR" -not \( -path "$REPO_ROOT/$TEST_DIR/data" -prune \) -name '*.go')"
  echo "compile checks passed..."

  echo "checking tests for go lint errors..."
  if ! golangci-lint run; then echo "lint failed..."; exit 1; fi
  echo "lint errors complete"

  cd "$D" || exit

  echo "checking terraform configs for errors..."
  if ! tflint --recursive; then C=$?; echo "tflint failed, exit code $C"; exit $C; fi
  echo "terraform configs valid..."

  echo "priming terraform plugin cache..."
  export GLOBAL_TF_PLUGIN_CACHE="/tmp/${IDENTIFIER}_tf_plugin_cache"
  mkdir -p "$GLOBAL_TF_PLUGIN_CACHE"
  export TF_PLUGIN_CACHE_DIR="$GLOBAL_TF_PLUGIN_CACHE"
  while IFS= read -r dir; do
    pushd "$dir" || exit

    needs_mirror=false

    (terraform get > /dev/null 2>&1 || true)
    providers=$(terraform providers | grep provider | awk -F'provider' '{print $2}' | awk -F'[' '{print $2}' | awk -F']' '{print $1}' | sort | uniq || true)

    for p in $providers; do
      if [ "$p" = "terraform.io/builtin/terraform" ]; then
        continue
      fi
      if [ ! -d "$GLOBAL_TF_PLUGIN_CACHE/$p" ]; then
        echo "Global cache doesn't have provider: $p"
        needs_mirror=true
        break
      fi
    done

    if $needs_mirror; then
      echo "  running 'terraform providers mirror $GLOBAL_TF_PLUGIN_CACHE' in $dir..."
      (terraform providers mirror "$GLOBAL_TF_PLUGIN_CACHE" > /dev/null 2>&1 || true)
    fi
    rm -rf .terraform

    popd || exit
  done <<< "$(find "$REPO_ROOT/examples" -name 'main.tf' -not -path '*/.terraform/*' -exec dirname {} \; | sort -u)"
  unset TF_PLUGIN_CACHE_DIR

  # Run tests initially
  run_tests false "$slow_mode"
  sleep 60

  # Check if we need to rerun failed tests
  if [ "$rerun_failed" = true ] && [ -f "/tmp/${IDENTIFIER}_failed_tests.txt" ]; then
    echo "Rerunning failed tests..."
    run_tests true "$slow_mode"
    sleep 60
  fi
fi


if [ -n "$cleanup_id" ]; then
  # cleanup only mode
  exit 0
fi

if [ -f "/tmp/${IDENTIFIER}_failed_tests.txt" ]; then
  echo "done, test failed"
  exit 1
else
  echo "done, test passed"
  exit 0
fi
