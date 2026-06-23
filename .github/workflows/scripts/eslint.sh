#!/usr/bin/env bash
set -e

npm install --no-save eslint @eslint/js globals
eslint .
rm -rf node_modules
