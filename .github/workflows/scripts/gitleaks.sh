#!/usr/bin/env bash
set -e
gitleaks detect --no-banner -v --no-git
gitleaks detect --no-banner -v
