#!/usr/bin/env bash
# ==============================================================================
# Hermes Stack Production Installer & Hardener
# Complete stack with WebUI, 9Router, OmniRoute, Nginx SSL & Cloudflare Tunnels
# Optional: Gemini 3.8 Flash (Medium) via 9Router & Persian localization (hermes-agent-farsi)
# ==============================================================================
set -euo pipefail

RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
CYAN="\033[1;36m"
BOLD="\033[1m"
RESET="\033[0m"

# Default random passwords if not provided
DEFAULT_RANDOM_PASS=$(openssl rand -hex 12 2>/dev/null || date +%s%N | sha256sum | head -c 24)

WEBUI_PASSWORD="${HERMES_WEBUI_PASSWORD:-}"
ROUTER_PASSWORD="${HERMES_ROUTER_PASSWORD:-}"
ROUTER_USER="${HERMES_ROUTER_USER:-admin}"
USER_HOME="${HOME:-/home/ubuntu}"
TARGET_USER="$(whoami)"

# Optional Features (environment variables fallback)
SET_GEMINI_FLASH="${HERMES_SET_GEMINI_FLASH:-${SET_GEMINI_FLASH:-}}"
CUSTOM_DEFAULT_MODEL="${HERMES_DEFAULT_MODEL:-${CUSTOM_DEFAULT_MODEL:-ag/gemini-3.8-flash-medium}}"
INSTALL_FARSI="${HERMES_INSTALL_FARSI:-${INSTALL_FARSI:-}}"
NON_INTERACTIVE="${NON_INTERACTIVE:-false}"

show_help() {
    cat << EOF
Hermes Stack Production Installer

Usage:
  ./install.sh [OPTIONS]

Options:
  --farsi, --persian          نصب بومی‌سازی فارسی و فونت وزیرمتن (hermes-agent-farsi)
  --no-farsi, --no-persian    عدم نصب بومی‌سازی فارسی
  --gemini-flash              تنظیم مدل پیش‌فرض هرمس روی Gemini 3.8 Flash (Medium)
  --no-gemini-flash           عدم تغییر مدل پیش‌فرض
  --model <MODEL_ID>          تعیین مدل پیش‌فرض دلخواه (پیش‌فرض: ag/gemini-3.8-flash-medium)
  --webui-password <PASS>     تعیین رمز عبور وب‌اینترفیس هرمس (WebUI)
  --router-password <PASS>    تعیین رمز عبور ورودی امن 9Router
  --router-user <USER>        نام کاربری ورودی امن 9Router (پیش‌فرض: admin)
  -y, --yes, --non-interactive اجرای خودکار بدون پرسش تعاملی
  -h, --help                  نمایش این راهنما

Environment Variables:
  HERMES_INSTALL_FARSI=true/false
  HERMES_SET_GEMINI_FLASH=true/false
  HERMES_DEFAULT_MODEL="ag/gemini-3.8-flash-medium"
  HERMES_WEBUI_PASSWORD="YourPassword"
  HERMES_ROUTER_PASSWORD="YourPassword"
  HERMES_ROUTER_USER="admin"

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --farsi|--persian)
            INSTALL_FARSI=true
            shift
            ;;
        --no-farsi|--no-persian)
            INSTALL_FARSI=false
            shift
            ;;
        --gemini-flash|--gemini-3.8-flash)
            SET_GEMINI_FLASH=true
            shift
            ;;
        --no-gemini-flash)
            SET_GEMINI_FLASH=false
            shift
            ;;
        --model)
            SET_GEMINI_FLASH=true
            CUSTOM_DEFAULT_MODEL="$2"
            shift 2
            ;;
        --webui-password)
            WEBUI_PASSWORD="$2"
            shift 2
            ;;
        --router-password)
            ROUTER_PASSWORD="$2"
            shift 2
            ;;
        --router-user)
            ROUTER_USER="$2"
            shift 2
            ;;
        -y|--yes|--non-interactive)
            NON_INTERACTIVE=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}خطای آرگومان ناشناخته: $1${RESET}"
            echo "برای مشاهده گزینه‌ها دستور ./install.sh --help را اجرا کنید."
            exit 1
            ;;
    esac
done

echo -e "${BLUE}${BOLD}===================================================================${RESET}"
echo -e "${BLUE}${BOLD}      Hermes Production Stack Installer & Cloudflare Exposer       ${RESET}"
echo -e "${BLUE}${BOLD}===================================================================${RESET}"
echo ""

# Check interactive mode
IS_INTERACTIVE=false
if [ -t 0 ] && [ "${CI:-false}" != "true" ] && [ "$NON_INTERACTIVE" != "true" ]; then
    IS_INTERACTIVE=true
fi

# Interactive Prompts if not specified
if [ "$IS_INTERACTIVE" = true ]; then
    if [ -z "$SET_GEMINI_FLASH" ]; then
        echo -e "${CYAN}🤖 آیا مایلید مدل پیش‌فرض هرمس روی Gemini 3.8 Flash (Medium) از طریق 9Router Antigravity تنظیم شود؟${RESET}"
        read -r -p "تنظیم مدل پیش‌فرض روی Gemini 3.8 Flash (Medium)؟ [Y/n]: " ans_model || true
        case "${ans_model:-Y}" in
            [yY]|[yY][eE][sS]|"") SET_GEMINI_FLASH=true ;;
            *) SET_GEMINI_FLASH=false ;;
        esac
        echo ""
    fi

    if [ -z "$INSTALL_FARSI" ]; then
        echo -e "${CYAN}🇮🇷 آیا مایلید بسته زبان فارسی، راست‌چین و فونت وزیرمتن (hermes-agent-farsi) نصب شود؟${RESET}"
        read -r -p "نصب بومی‌سازی فارسی و فونت وزیرمتن؟ [Y/n]: " ans_farsi || true
        case "${ans_farsi:-Y}" in
            [yY]|[yY][eE][sS]|"") INSTALL_FARSI=true ;;
            *) INSTALL_FARSI=false ;;
        esac
        echo ""
    fi
else
    SET_GEMINI_FLASH="${SET_GEMINI_FLASH:-false}"
    INSTALL_FARSI="${INSTALL_FARSI:-false}"
fi

# Fallback for passwords
WEBUI_PASSWORD="${WEBUI_PASSWORD:-$DEFAULT_RANDOM_PASS}"
ROUTER_PASSWORD="${ROUTER_PASSWORD:-$DEFAULT_RANDOM_PASS}"

TOTAL_STEPS=7
[ "$SET_GEMINI_FLASH" = true ] && TOTAL_STEPS=$((TOTAL_STEPS + 1))
[ "$INSTALL_FARSI" = true ] && TOTAL_STEPS=$((TOTAL_STEPS + 1))
CURRENT_STEP=0

step() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    echo -e "${YELLOW}[${CURRENT_STEP}/${TOTAL_STEPS}] $1${RESET}"
}

# 1. System packages
step "Installing base system dependencies..."
sudo apt-get update -y
sudo apt-get install -y git curl wget openssl python3 python3-pip python3-venv python3-yaml nginx apache2-utils

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
step "Setting up Node.js & uv environments..."
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

# 3. Base Hermes Agent & WebUI components
step "Setting up Hermes Agent & WebUI components..."
# Ensure Hermes Agent core is installed
if ! command -v hermes &>/dev/null && [ ! -d "$USER_HOME/.hermes/hermes-agent" ]; then
    echo -e "${YELLOW}Installing Hermes Agent core...${RESET}"
    curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash || true
fi

# Ensure Hermes WebUI is installed
WEBUI_DIR="$USER_HOME/hermes-webui"
if [ ! -d "$WEBUI_DIR" ]; then
    echo -e "${YELLOW}Installing Hermes WebUI...${RESET}"
    curl -fsSL https://raw.githubusercontent.com/m4tinbeigi-official/hermes-webui-installer/main/install.sh | bash || true
fi

# Install 9router and omniroute globally if not already linked
npm install -g 9router --legacy-peer-deps || true
npm install -g omniroute --legacy-peer-deps || true
sudo ln -sf "$NVM_DIR/versions/node/v22.23.2/bin/9router" /usr/local/bin/9router || true
sudo ln -sf "$NVM_DIR/versions/node/v22.23.2/bin/omniroute" /usr/local/bin/omniroute || true

# 4. Protect Hermes WebUI
step "Securing Hermes WebUI with password authentication..."
if [ -d "$WEBUI_DIR" ]; then
    cat << EOF > "$WEBUI_DIR/.env"
HERMES_WEBUI_HOST="0.0.0.0"
HERMES_WEBUI_PORT="8787"
HERMES_WEBUI_PASSWORD="$WEBUI_PASSWORD"
EOF
    chmod 600 "$WEBUI_DIR/.env"
    chown "$TARGET_USER:$TARGET_USER" "$WEBUI_DIR/.env" 2>/dev/null || true
fi

# 5. Configure Nginx & Basic Auth for 9Router
step "Configuring Nginx reverse proxy and HTTP Basic Auth for 9Router..."
sudo htpasswd -bc /etc/nginx/.htpasswd "$ROUTER_USER" "$ROUTER_PASSWORD"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
sudo cp "$SCRIPT_DIR/nginx/9router.conf" /etc/nginx/sites-available/9router
sudo ln -sf /etc/nginx/sites-available/9router /etc/nginx/sites-enabled/9router
sudo nginx -t
sudo systemctl restart nginx
sudo systemctl enable nginx

# 6. Optional: Configure Default Model (Gemini 3.8 Flash Medium via 9Router)
if [ "$SET_GEMINI_FLASH" = true ]; then
    step "Configuring default model to $CUSTOM_DEFAULT_MODEL via 9Router..."
    mkdir -p "$USER_HOME/.hermes"
    CONFIG_FILE="$USER_HOME/.hermes/config.yaml"

    python3 - << PYEOF
import os

try:
    import yaml
except ImportError:
    yaml = None

config_path = "$CONFIG_FILE"
target_model = "$CUSTOM_DEFAULT_MODEL"
farsi_flag = ($([ "$INSTALL_FARSI" = true ] && echo "True" || echo "False"))

cfg = {}
if yaml and os.path.exists(config_path):
    try:
        with open(config_path, "r", encoding="utf-8") as f:
            cfg = yaml.safe_load(f) or {}
    except Exception:
        cfg = {}

if not isinstance(cfg.get("model"), dict):
    cfg["model"] = {}
cfg["model"]["default"] = target_model
cfg["model"]["provider"] = "custom"
cfg["model"]["base_url"] = "http://127.0.0.1:20128/v1"

if "providers" not in cfg or not isinstance(cfg["providers"], dict):
    cfg["providers"] = {}
cfg["providers"]["antigravity"] = {
    "name": "9Router Antigravity",
    "base_url": "http://127.0.0.1:20128/v1",
    "key_env": "OPENAI_API_KEY",
    "transport": "openai_chat"
}

if "model_aliases" not in cfg or not isinstance(cfg["model_aliases"], dict):
    cfg["model_aliases"] = {}
cfg["model_aliases"]["antigravity"] = {
    "model": target_model,
    "provider": "antigravity",
    "base_url": "http://127.0.0.1:20128/v1"
}
cfg["model_aliases"]["gemini-flash"] = {
    "model": target_model,
    "provider": "antigravity",
    "base_url": "http://127.0.0.1:20128/v1"
}

if not isinstance(cfg.get("agent"), dict):
    cfg["agent"] = {}
cfg["agent"]["reasoning_effort"] = "medium"

if farsi_flag:
    if not isinstance(cfg.get("display"), dict):
        cfg["display"] = {}
    cfg["display"]["language"] = "fa"
    if "plugins" not in cfg or not isinstance(cfg["plugins"], dict):
        cfg["plugins"] = {"enabled": ["hermes-farsi"], "disabled": []}
    else:
        en = cfg["plugins"].get("enabled") or []
        if "hermes-farsi" not in en:
            en.append("hermes-farsi")
            cfg["plugins"]["enabled"] = en

if yaml:
    with open(config_path, "w", encoding="utf-8") as f:
        yaml.dump(cfg, f, default_flow_style=False, allow_unicode=True)
else:
    # Direct YAML template fallback
    with open(config_path, "w", encoding="utf-8") as f:
        f.write(f"""model:
  default: {target_model}
  provider: custom
  base_url: http://127.0.0.1:20128/v1
providers:
  antigravity:
    name: 9Router Antigravity
    base_url: http://127.0.0.1:20128/v1
    key_env: OPENAI_API_KEY
    transport: openai_chat
agent:
  max_turns: 500
  reasoning_effort: medium
model_aliases:
  antigravity:
    model: {target_model}
    provider: antigravity
    base_url: http://127.0.0.1:20128/v1
  gemini-flash:
    model: {target_model}
    provider: antigravity
    base_url: http://127.0.0.1:20128/v1
""" + ("""display:
  language: fa
plugins:
  enabled:
    - hermes-farsi
  disabled: []
""" if farsi_flag else ""))
PYEOF

    chown "$TARGET_USER:$TARGET_USER" "$CONFIG_FILE" 2>/dev/null || true
    echo -e "${GREEN}✔ Default model configured to $CUSTOM_DEFAULT_MODEL!${RESET}"
fi

# 7. Optional: Install Persian Localization (hermes-agent-farsi)
if [ "$INSTALL_FARSI" = true ]; then
    step "Installing Persian localization & Vazirmatn font (hermes-agent-farsi)...${RESET}"
    HERMES_CORE_DIR="$USER_HOME/.hermes/hermes-agent"
    [ ! -d "$HERMES_CORE_DIR" ] && [ -d "$USER_HOME/hermes-agent" ] && HERMES_CORE_DIR="$USER_HOME/hermes-agent"

    if [ -d "$HERMES_CORE_DIR" ]; then
        echo -e "Applying Persian localization patch to $HERMES_CORE_DIR..."
        bash <(curl -fsSL https://raw.githubusercontent.com/m4tinbeigi-official/hermes-agent-farsi/main/install.sh) "$HERMES_CORE_DIR" || true
    fi

    # Also install as Hermes plugin if CLI is present
    if command -v hermes &>/dev/null; then
        hermes plugins install m4tinbeigi-official/hermes-agent-farsi || true
        hermes config set display.language fa || true
    fi

    echo -e "${GREEN}✔ Persian localization (Vazirmatn & RTL) installed successfully!${RESET}"
fi

# 8. Install Systemd Services
step "Installing and enabling all systemd units (auto-boot)..."
mkdir -p "$USER_HOME/.hermes"

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
Default Model        : $([ "$SET_GEMINI_FLASH" = true ] && echo "$CUSTOM_DEFAULT_MODEL (via 9Router)" || echo "Default (Upstream)")
Persian Localization : $([ "$INSTALL_FARSI" = true ] && echo "Enabled (Vazirmatn & RTL)" || echo "Disabled")
===================================================
EOF
chmod 600 "$USER_HOME/.hermes/credentials.txt"
chown "$TARGET_USER:$TARGET_USER" "$USER_HOME/.hermes/credentials.txt" 2>/dev/null || true

# Update internal 9Router Dashboard password
echo -e "${YELLOW}Syncing internal 9Router dashboard credentials...${RESET}"
sleep 5
TOKEN=$(curl -s -X POST http://127.0.0.1:20126/api/auth/login \
    -H "Content-Type: application/json" \
    -d '{"password":"123456"}' -i 2>/dev/null | grep -oE "auth_token=[^;]+" | cut -d= -f2 || true)

if [ -n "$TOKEN" ]; then
    curl -s -X PATCH http://127.0.0.1:20126/api/settings \
        -H "Content-Type: application/json" \
        -b "auth_token=$TOKEN" \
        -d "{\"currentPassword\":\"123456\",\"newPassword\":\"$ROUTER_PASSWORD\"}" >/dev/null 2>&1 || true
fi

echo ""
echo -e "${GREEN}${BOLD}✔ Installation & Configuration completed successfully!${RESET}"
echo ""
/usr/local/bin/hermes-public-url || true
