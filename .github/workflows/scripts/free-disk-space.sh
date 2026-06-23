#!/usr/bin/env bash
set -e

echo "Disk space before cleanup:"
df -h
sudo rm -rf /usr/local/.ghcup
sudo rm -rf /opt/hostedtoolcache/CodeQL
sudo rm -rf /usr/local/lib/android/sdk/ndk
sudo rm -rf /usr/share/dotnet
sudo rm -rf /opt/ghc
sudo rm -rf /usr/local/share/boost
sudo apt-get clean
echo "Disk space after cleanup:"
df -h
