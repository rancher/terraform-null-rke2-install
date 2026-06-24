#!/usr/bin/env bash
set -e

PR_NUMBER="$1"

echo "Checking if commits in PR $PR_NUMBER are signed..."

# Fetch commits for the PR
# gh api automatically replaces :owner and :repo with the repository context of the current directory
COMMITS="$(gh api "/repos/:owner/:repo/pulls/$PR_NUMBER/commits?per_page=100")"

ALL_SIGNED=true

while read -r commit; do
  if [ -z "$commit" ]; then
    continue
  fi
  
  sha="$(echo "$commit" | jq -r '.sha')"
  verified="$(echo "$commit" | jq -r '.commit.verification.verified')"
  reason="$(echo "$commit" | jq -r '.commit.verification.reason')"

  if [ "$verified" != "true" ]; then
    echo "...Commit $sha is not signed. Reason: $reason"
    ALL_SIGNED=false
  else
    echo "...Commit $sha is signed."
  fi
done <<<"$(echo "$COMMITS" | jq -c '.[]?')"

if [ "$ALL_SIGNED" != "true" ]; then
  echo "Error: One or more commits are not signed. Please ensure all commits are signed."
  exit 1
fi

echo "All commits are signed."
