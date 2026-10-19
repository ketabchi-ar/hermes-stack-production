#!/usr/bin/env bash

BLUE="\033[1;34m"
GREEN="\033[1;32m"
RED="\033[1;31m"
RESET="\033[0m"

echo -e "${BLUE}=== Hermes Stack Service Status (systemd) ===${RESET}"

check_svc() {
    local name="$1"
    local svc="$2"
    local port="$3"
    if systemctl is-active --quiet "$svc"; then
        echo -e "  ${GREEN}● RUNNING${RESET} - $name (Port: $port, Service: $svc)"
    else
        echo -e "  ${RED}○ STOPPED${RESET} - $name (Port: $port, Service: $svc)"
    fi
}

check_svc "Hermes WebUI" hermes-webui 8787
check_svc "9Router (internal)" hermes-9router 20126
check_svc "Nginx (9Router Gateway)" nginx 20128
check_svc "OmniRoute" hermes-omniroute 20129
check_svc "Cloudflare Tunnel (WebUI)" hermes-tunnel "SSL"
check_svc "Cloudflare Tunnel (9Router)" hermes-9router-tunnel "SSL"
