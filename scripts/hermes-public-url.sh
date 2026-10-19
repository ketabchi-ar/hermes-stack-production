#!/usr/bin/env bash
set -e

GREEN="\033[1;32m"
BLUE="\033[1;34m"
YELLOW="\033[1;33m"
RESET="\033[0m"

USER_HOME="${HOME:-/home/ubuntu}"
CRED_FILE="$USER_HOME/.hermes/credentials.txt"

echo -e "${BLUE}===============================================================${RESET}"
echo -e "${BLUE}   Hermes Stack - Public SSL / HTTPS URLs & Status            ${RESET}"
echo -e "${BLUE}===============================================================${RESET}"
echo ""

# WebUI Tunnel
echo -e "${GREEN}🖥️  Hermes WebUI (Dashboard):${RESET}"
WEBUI_LOG="$USER_HOME/.hermes/cloudflared.log"
if [ -f "$WEBUI_LOG" ]; then
    webui_url=$(grep -oE "https://[a-zA-Z0-9-]+\.trycloudflare\.com" "$WEBUI_LOG" | tail -n 1)
    if [ -n "$webui_url" ]; then
        echo -e "   URL      : ${GREEN}${webui_url}${RESET}"
    else
        echo -e "   URL      : ${YELLOW}Tunnel is initializing... (tail -f $WEBUI_LOG)${RESET}"
    fi
else
    echo -e "   URL      : ${YELLOW}Tunnel log not found at $WEBUI_LOG${RESET}"
fi
echo ""

# 9Router Tunnel
echo -e "${GREEN}🔀 9Router (AI Gateway):${RESET}"
ROUTER_LOG="$USER_HOME/.hermes/cloudflared-9router.log"
if [ -f "$ROUTER_LOG" ]; then
    router_url=$(grep -oE "https://[a-zA-Z0-9-]+\.trycloudflare\.com" "$ROUTER_LOG" | tail -n 1)
    if [ -n "$router_url" ]; then
        echo -e "   URL      : ${GREEN}${router_url}${RESET}"
    else
        echo -e "   URL      : ${YELLOW}Tunnel is initializing... (tail -f $ROUTER_LOG)${RESET}"
    fi
else
    echo -e "   URL      : ${YELLOW}Tunnel log not found at $ROUTER_LOG${RESET}"
fi
echo ""

# Direct IP
echo -e "${GREEN}🌐 Direct Access:${RESET}"
IPV6=$(ip -6 addr show scope global 2>/dev/null | grep -oE "([0-9a-fA-F:]+)/[0-9]+" | head -n 1 | cut -d/ -f1 || true)
if [ -n "$IPV6" ]; then
    echo -e "   WebUI    : http://[${IPV6}]:8787"
    echo -e "   9Router  : http://[${IPV6}]:20128"
    echo -e "   OmniRoute: http://[${IPV6}]:20129"
else
    echo -e "   WebUI    : http://127.0.0.1:8787"
    echo -e "   9Router  : http://127.0.0.1:20128"
    echo -e "   OmniRoute: http://127.0.0.1:20129"
fi
echo ""

if [ -f "$CRED_FILE" ]; then
    echo -e "${YELLOW}Credentials saved locally in: $CRED_FILE${RESET}"
fi
echo -e "${BLUE}===============================================================${RESET}"
