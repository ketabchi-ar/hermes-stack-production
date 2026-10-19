#!/usr/bin/env bash
set -e

echo -e "\033[1;34mStarting Hermes Stack services...\033[0m"
sudo systemctl start hermes-webui hermes-9router hermes-omniroute hermes-tunnel hermes-9router-tunnel nginx
echo -e "\033[1;32m✔ All services started.\033[0m"
$(dirname "$0")/status.sh
