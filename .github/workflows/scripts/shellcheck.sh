#!/usr/bin/env bash
set -e

while read -r file; do
  echo "checking $file..."
  shellcheck -x "$file"
done <<<"$(grep -Rl -e '^#!' | grep -v '.terraform'| grep -v '.git')"
