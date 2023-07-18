#!/bin/bash
set -e

FILE=""

# Extract "file" and "url" argument from the input into URL and FILE shell variables
# jq will ensure that the values are properly quoted and escaped for consumption by the shell
eval "$(jq -r '@sh "FILE=\(.file) URL=\(.url)"')"

NAME="$FILE"

if [ ! -z "$FILE" ]; then
  if [ -f "$FILE" ]; then
    NAME="$FILE"
  else
    NAME="file not found"
  fi
fi

# Download the file if URL given and file doesn't exist
if [ ! -z "$URL" ]; then
  if [ "$NAME" = "file not found" ]; then
    wget -q -O "$FILE" "$URL"
    NAME="$FILE"
  fi
else
  exit 1
fi

# jq will ensure that the value is properly quoted and escaped to produce a valid JSON string
jq -n --arg name "$NAME" '{"name":$name}'
