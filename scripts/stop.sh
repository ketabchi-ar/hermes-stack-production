#!/usr/bin/env bash
set -e

echo -e "\033[1;33mStopping Hermes Stack services...\033[0m"
sudo systemctl stop hermes-webui hermes-9router hermes-omniroute hermes-tunnel hermes-9router-tunnel
echo -e "\033[1;32m✔ All Hermes services stopped.\033[0m"
