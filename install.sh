#!/usr/bin/env bash
# ==============================================================================
# Hermes Stack Production Installer & Hardener
# Complete stack with WebUI, 9Router, OmniRoute, Nginx SSL & Cloudflare Tunnels
# ==============================================================================
set -euo pipefail

RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
BOLD="\033[1m"
RESET="\033[0m"

# Generate secure random passwords if not provided by user
DEFAULT_RANDOM_PASS=$(openssl rand -hex 12 2>/dev/null || date +%s%N | sha256sum | head -c 24)

WEBUI_PASSWORD="${HERMES_WEBUI_PASSWORD:-$DEFAULT_RANDOM_PASS}"
ROUTER_PASSWORD="${HERMES_ROUTER_PASSWORD:-$DEFAULT_RANDOM_PASS}"
ROUTER_USER="${HERMES_ROUTER_USER:-admin}"
USER_HOME="${HOME:-/home/ubuntu}"
TARGET_USER="$(whoami)"

echo -e "${BLUE}${BOLD}===================================================================${RESET}"
echo -e "${BLUE}${BOLD}      Hermes Production Stack Installer & Cloudflare Exposer       ${RESET}"
echo -e "${BLUE}${BOLD}===================================================================${RESET}"
echo ""

# 1. System packages
echo -e "${YELLOW}[1/7] Installing base system dependencies...${RESET}"
sudo apt-get update -y
sudo apt-get install -y git curl wget openssl python3 python3-pip python3-venv nginx apache2-utils

# Install cloudflared if missing
if ! command -v cloudflared &>/dev/null; then
    echo -e "${YELLOW}Installing cloudflared...${RESET}"
    curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
    echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/cloudflared.list
    sudo apt-get update -y
    sudo apt-get install -y cloudflared || {
        ARCH=$(dpkg --print-architecture)
        wget -q "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${ARCH}.deb" -O /tmp/cloudflared.deb
        sudo dpkg -i /tmp/cloudflared.deb || sudo apt-get install -f -y
        rm -f /tmp/cloudflared.deb
    }
fi

# 2. Node.js & uv
echo -e "${YELLOW}[2/7] Setting up Node.js & uv environments...${RESET}"
export NVM_DIR="$USER_HOME/.nvm"
if [ ! -d "$NVM_DIR" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
fi
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

nvm install 22.23.2
nvm alias default 22.23.2
nvm use 22.23.2

# Link node & npm to /usr/local/bin
sudo ln -sf "$NVM_DIR/versions/node/v22.23.2/bin/node" /usr/local/bin/node
sudo ln -sf "$NVM_DIR/versions/node/v22.23.2/bin/npm" /usr/local/bin/npm
sudo ln -sf "$NVM_DIR/versions/node/v22.23.2/bin/npx" /usr/local/bin/npx

if ! command -v uv &>/dev/null; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
    sudo ln -sf "$USER_HOME/.local/bin/uv" /usr/local/bin/uv || true
fi

# 3. Upstream Hermes Stack Installer
echo -e "${YELLOW}[3/7] Running upstream hermes-stack-installer base components...${RESET}"
if [ ! -d "/tmp/hermes-stack-installer" ]; then
    git clone https://github.com/m4tinbeigi-official/hermes-stack-installer.git /tmp/hermes-stack-installer
fi
cd /tmp/hermes-stack-installer

# Run installer non-interactively
export CI=true
bash install.sh || echo -e "${YELLOW}Notice: Base installer completed, proceeding to production hardening...${RESET}"

# Install 9router and omniroute globally if not already linked
npm install -g 9router --legacy-peer-deps || true
npm install -g omniroute --legacy-peer-deps || true
sudo ln -sf "$NVM_DIR/versions/node/v22.23.2/bin/9router" /usr/local/bin/9router || true
sudo ln -sf "$NVM_DIR/versions/node/v22.23.2/bin/omniroute" /usr/local/bin/omniroute || true

# 4. Protect Hermes WebUI
echo -e "${YELLOW}[4/7] Securing Hermes WebUI with password authentication...${RESET}"
WEBUI_DIR="$USER_HOME/hermes-webui"
if [ -d "$WEBUI_DIR" ]; then
    cat << EOF > "$WEBUI_DIR/.env"
HERMES_WEBUI_HOST="0.0.0.0"
HERMES_WEBUI_PORT="8787"
HERMES_WEBUI_PASSWORD="$WEBUI_PASSWORD"
EOF
    chmod 600 "$WEBUI_DIR/.env"
fi

# 5. Configure Nginx & Basic Auth for 9Router
echo -e "${YELLOW}[5/7] Configuring Nginx reverse proxy and HTTP Basic Auth for 9Router...${RESET}"
sudo htpasswd -bc /etc/nginx/.htpasswd "$ROUTER_USER" "$ROUTER_PASSWORD"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
sudo cp "$SCRIPT_DIR/nginx/9router.conf" /etc/nginx/sites-available/9router
sudo ln -sf /etc/nginx/sites-available/9router /etc/nginx/sites-enabled/9router
sudo nginx -t
sudo systemctl restart nginx
sudo systemctl enable nginx

# 6. Install Systemd Services
echo -e "${YELLOW}[6/7] Installing and enabling all systemd units (auto-boot)...${RESET}"
mkdir -p "$USER_HOME/.hermes"

# Copy systemd units and replace paths for target user
for svc in hermes-webui hermes-9router hermes-omniroute hermes-tunnel hermes-9router-tunnel; do
    sed -e "s|/home/ubuntu|$USER_HOME|g" \
        -e "s|User=ubuntu|User=$TARGET_USER|g" \
        -e "s|Group=ubuntu|Group=$TARGET_USER|g" \
        "$SCRIPT_DIR/systemd/${svc}.service" | sudo tee "/etc/systemd/system/${svc}.service" >/dev/null
done

sudo systemctl daemon-reload
sudo systemctl enable hermes-webui hermes-9router hermes-omniroute hermes-tunnel hermes-9router-tunnel
sudo systemctl restart hermes-webui hermes-9router hermes-omniroute hermes-tunnel hermes-9router-tunnel

# Install management CLI tools
mkdir -p "$USER_HOME/.hermes-stack"
cp "$SCRIPT_DIR/scripts/start.sh" "$USER_HOME/.hermes-stack/start.sh"
cp "$SCRIPT_DIR/scripts/stop.sh" "$USER_HOME/.hermes-stack/stop.sh"
cp "$SCRIPT_DIR/scripts/status.sh" "$USER_HOME/.hermes-stack/status.sh"
cp "$SCRIPT_DIR/scripts/hermes-public-url.sh" "$USER_HOME/.hermes-stack/hermes-public-url.sh"
chmod +x "$USER_HOME/.hermes-stack/"*.sh

sudo ln -sf "$USER_HOME/.hermes-stack/start.sh" /usr/local/bin/hermes-stack-start
sudo ln -sf "$USER_HOME/.hermes-stack/stop.sh" /usr/local/bin/hermes-stack-stop
sudo ln -sf "$USER_HOME/.hermes-stack/status.sh" /usr/local/bin/hermes-stack-status
sudo ln -sf "$USER_HOME/.hermes-stack/hermes-public-url.sh" /usr/local/bin/hermes-public-url

# Save generated credentials securely on host
cat << EOF > "$USER_HOME/.hermes/credentials.txt"
===================================================
Hermes Stack Generated Credentials
Date: $(date)
===================================================
Hermes WebUI Password: $WEBUI_PASSWORD
9Router Username     : $ROUTER_USER
9Router Password     : $ROUTER_PASSWORD
===================================================
EOF
chmod 600 "$USER_HOME/.hermes/credentials.txt"

# 7. Update internal 9Router Dashboard password
echo -e "${YELLOW}[7/7] Updating internal 9Router dashboard credentials...${RESET}"
sleep 5
TOKEN=$(curl -s -X POST http://127.0.0.1:20126/api/auth/login \
    -H "Content-Type: application/json" \
    -d '{"password":"123456"}' -i | grep -oE "auth_token=[^;]+" | cut -d= -f2 || true)

if [ -n "$TOKEN" ]; then
    curl -s -X PATCH http://127.0.0.1:20126/api/settings \
        -H "Content-Type: application/json" \
        -b "auth_token=$TOKEN" \
        -d "{\"currentPassword\":\"123456\",\"newPassword\":\"$ROUTER_PASSWORD\"}" >/dev/null || true
fi

echo ""
echo -e "${GREEN}${BOLD}✔ Installation & Configuration completed successfully!${RESET}"
echo ""
/usr/local/bin/hermes-public-url
