#!/bin/bash

# Exit if any of the intermediate steps fail
set -e

FILE=""
# Extract "file" and "url" argument from the input into URL and FILE shell variables.
# jq will ensure that the values are properly quoted and escaped for consumption by the shell.

eval "$(jq -r '@sh "FILE=\(.file) URL=\(.url)"')"

CHECKSUM="$FILE"

if [ ! -z "$FILE" ]; then
  if [ -f "$FILE" ]; then
    CHECKSUM=$(md5sum $FILE | awk '{ print $1 }')
  else
    CHECKSUM="file not found"
  fi
fi

# Download the file if URL given and file doesn't exist
if [ ! -z "$URL" ]; then
  if [ "$CHECKSUM" = "file not found" ]; then
    wget -q -O $FILE $URL
    CHECKSUM=$(md5sum $FILE | awk '{ print $1 }')
  fi
fi

# Safely produce a JSON object containing the result value,
#  jq will ensure that the value is properly quoted and escaped to produce a valid JSON string.
jq -n --arg checksum "$CHECKSUM" '{"checksum":$checksum}'