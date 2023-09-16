#!/bin/sh
set -e
set -x
LOCAL_PATH="${1}"
FILE_NAME="${2}"
CONTENT="${3}"

install -d "${LOCAL_PATH}"
echo "${CONTENT}" > "${FILE_NAME}"
chmod 0600 "${FILE_NAME}"
