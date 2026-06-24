#!/usr/bin/env bash
set -e
terraform fmt -check -recursive -diff
tflint --recursive
