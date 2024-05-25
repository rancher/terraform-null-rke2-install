
run_tests() {
  echo "" > /tmp/test.log
  if [ -d "./tests" ]; then
    cd tests
  fi
  cat <<'EOF'> /tmp/test-processor
echo "Passed: "
cat /tmp/test.log | jq -r '. | select(.Action == "pass") | select(.Test != null).Test'
echo " "
echo "Failed: "
FAILED_TESTS="$(jq -r '. | select(.Action == "fail") | select(.Test != null).Test' /tmp/test.log)"
for TEST in $FAILED_TESTS; do
  echo "$TEST"
  grep $TEST /tmp/test.log | grep '        \\t' | jq '.Output' | sed 's/\\t\|\\n\|\\\|"        //g'; done
  echo " "
done
echo " "
EOF
  chmod +x /tmp/test-processor

  gotestsum \
    --format=standard-verbose \
    --jsonfile /tmp/test.log \
    --post-run-command "bash /tmp/test-processor" \
    -- \
    -parallel=10 \
    -timeout=80m \
    "${1}"
}

run_tests
