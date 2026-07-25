#!/usr/bin/env bash
#===============================================================================
#   Polkit Authentication Agent Fixer for LocalWP & Privilege Dialogs
#   Part of: CachyOS + HyDE System Restorer
#   Repo:    https://github.com/omarahmed321/cachyos-restore
#===============================================================================

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}${BOLD}"
cat << "EOF"
  ==============================================================
       Polkit Authentication Agent & LocalWP Privilege Fixer
  ==============================================================
EOF
echo -e "${NC}"

echo -e "${CYAN}[1/3] Searching for Polkit Authentication Agent on system...${NC}"

AGENT_BIN=""
if [ -f "/usr/lib/polkit-kde-authentication-agent-1" ]; then
    AGENT_BIN="/usr/lib/polkit-kde-authentication-agent-1"
elif [ -f "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1" ]; then
    AGENT_BIN="/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"
elif command -v hyprpolkitagent &>/dev/null; then
    AGENT_BIN="$(which hyprpolkitagent)"
fi

# Install polkit-kde-agent if missing
if [ -z "$AGENT_BIN" ]; then
    echo -e "${YELLOW}[*] Installing polkit-kde-agent via pacman...${NC}"
    sudo pacman -S --noconfirm --needed polkit-kde-agent || true
    if [ -f "/usr/lib/polkit-kde-authentication-agent-1" ]; then
        AGENT_BIN="/usr/lib/polkit-kde-authentication-agent-1"
    fi
fi

if [ -n "$AGENT_BIN" ]; then
    echo -e "${GREEN}[OK] Found Polkit Agent at: $AGENT_BIN${NC}"
else
    echo -e "${RED}[!] Error: Could not locate a valid polkit agent binary.${NC}"
    exit 1
fi

echo -e "\n${CYAN}[2/3] Launching Polkit Authentication Agent in background...${NC}"
pkill -f "$(basename "$AGENT_BIN")" 2>/dev/null || true
"$AGENT_BIN" &>/dev/null &
sleep 1

if pgrep -f "$(basename "$AGENT_BIN")" >/dev/null; then
    echo -e "${GREEN}[OK] Polkit Authentication Agent is running live!${NC}"
else
    echo -e "${YELLOW}[!] Note: Polkit Agent background launch triggered.${NC}"
fi

echo -e "\n${CYAN}[3/3] Registering Polkit Agent in Hyprland userprefs.conf...${NC}"
HYPR_CONF="$HOME/.config/hypr/userprefs.conf"
mkdir -p "$HOME/.config/hypr"
touch "$HYPR_CONF"

if ! grep -q "polkit" "$HYPR_CONF"; then
    cat << EOF >> "$HYPR_CONF"

# Start Polkit Authentication Agent for LocalWP and elevated privileges dialogs
exec-once = $AGENT_BIN
EOF
    echo -e "${GREEN}[OK] Registered exec-once in $HYPR_CONF${NC}"
else
    echo -e "${GREEN}[OK] Polkit agent is already configured in $HYPR_CONF${NC}"
fi

# Copy script to user bin for standalone use
mkdir -p "$HOME/.local/share/bin"
cp "$0" "$HOME/.local/share/bin/fix-polkit-localwp.sh" 2>/dev/null || true
chmod +x "$HOME/.local/share/bin/fix-polkit-localwp.sh" 2>/dev/null || true

echo -e "\n${GREEN}${BOLD}[OK] Polkit Authentication Agent Fixed Successfully!${NC}"
echo -e "${CYAN}[*] You can now start sites in LocalWP without exitCode 127 error.${NC}\n"
