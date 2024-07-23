
run_tests() {
  echo "" > /tmp/test.log
  if [ -d "./tests" ]; then
    cd tests
  fi
  if [ -d "./test" ]; then
    cd test
  fi
  cat <<'EOF'> /tmp/test-processor
echo "Passed: "
jq -r '. | select(.Action == "pass") | select(.Test != null).Test' /tmp/test.log
echo " "
echo "Failed: "
jq -r '. | select(.Action == "fail") | select(.Test != null).Test' /tmp/test.log
echo " "
EOF
  chmod +x /tmp/test-processor

  gotestsum \
    --format=standard-verbose \
    --jsonfile /tmp/test.log \
    --post-run-command "bash /tmp/test-processor" \
    -- \
    -parallel=8 \
    -timeout=80m \
    "$@"
}

run_tests "$@"
