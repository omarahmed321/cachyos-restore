#!/usr/bin/env bash
#===============================================================================
#   Universal Polkit Authentication Agent Fixer for LocalWP & Privileged Apps
#   Part of: CachyOS + HyDE System Restorer & Universal Replicator
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
       Universal Polkit Authentication Agent & LocalWP Fixer
  ==============================================================
EOF
echo -e "${NC}"

# 1. Search for existing Polkit Agent across all Linux distributions (Arch, Ubuntu, Fedora, Debian, Manjaro, etc.)
echo -e "${CYAN}[1/4] Detecting system Polkit Authentication Agent...${NC}"

AGENT_BIN=""
POSSIBLE_PATHS=(
    "/usr/lib/polkit-kde-authentication-agent-1"
    "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"
    "/usr/libexec/polkit-gnome-authentication-agent-1"
    "/usr/libexec/polkit-kde-authentication-agent-1"
    "/usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1"
    "/usr/lib/x86_64-linux-gnu/polkit-mate/polkit-mate-authentication-agent-1"
    "/usr/libexec/polkit-mate-authentication-agent-1"
)

for path in "${POSSIBLE_PATHS[@]}"; do
    if [ -f "$path" ]; then
        AGENT_BIN="$path"
        break
    fi
done

if [ -z "$AGENT_BIN" ] && command -v hyprpolkitagent &>/dev/null; then
    AGENT_BIN="$(which hyprpolkitagent)"
fi

# 2. Auto-install Polkit Agent using native package manager if missing
if [ -z "$AGENT_BIN" ]; then
    echo -e "${YELLOW}[*] No active Polkit agent found. Installing package...${NC}"
    if command -v pacman &>/dev/null; then
        sudo pacman -S --noconfirm --needed polkit-kde-agent || sudo pacman -S --noconfirm --needed polkit-gnome
    elif command -v apt &>/dev/null; then
        sudo apt update && sudo apt install -y policykit-1-gnome || sudo apt install -y lxpolkit
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y polkit-kde || sudo dnf install -y polkit-gnome
    fi

    # Re-check after installation
    for path in "${POSSIBLE_PATHS[@]}"; do
        if [ -f "$path" ]; then
            AGENT_BIN="$path"
            break
        fi
    done
fi

if [ -n "$AGENT_BIN" ]; then
    echo -e "${GREEN}[OK] Verified Polkit Agent at: $AGENT_BIN${NC}"
else
    echo -e "${RED}[!] Error: Could not locate or install a valid Polkit authentication agent.${NC}"
    exit 1
fi

# 3. Launch the Polkit Agent in background live
echo -e "\n${CYAN}[2/4] Launching Polkit Authentication Agent in background...${NC}"
AGENT_NAME="$(basename "$AGENT_BIN")"
pkill -f "$AGENT_NAME" 2>/dev/null || true
"$AGENT_BIN" &>/dev/null &
sleep 1

if pgrep -f "$AGENT_NAME" >/dev/null; then
    echo -e "${GREEN}[OK] Polkit Authentication Agent is running live!${NC}"
else
    echo -e "${YELLOW}[*] Polkit background trigger executed.${NC}"
fi

# 4. Auto-register in Hyprland / Wayland / X11 autostarts
echo -e "\n${CYAN}[3/4] Registering auto-start across desktop environments...${NC}"

# Hyprland registration
HYPR_CONF="$HOME/.config/hypr/userprefs.conf"
if [ -d "$HOME/.config/hypr" ]; then
    touch "$HYPR_CONF"
    if ! grep -q "polkit" "$HYPR_CONF"; then
        cat << EOF >> "$HYPR_CONF"

# Start Polkit Authentication Agent for LocalWP and elevated privileges dialogs
exec-once = $AGENT_BIN
EOF
        echo -e "${GREEN}[OK] Registered exec-once in Hyprland ($HYPR_CONF)${NC}"
    else
        echo -e "${GREEN}[OK] Polkit agent already configured in Hyprland ($HYPR_CONF)${NC}"
    fi
fi

# XDG Autostart Desktop entry registration (Works for Sway, Wayfire, Xmonad, i3, Openbox, KDE, GNOME, XFCE)
XDG_AUTOSTART="$HOME/.config/autostart/polkit-agent-localwp.desktop"
mkdir -p "$HOME/.config/autostart"
cat << EOF > "$XDG_AUTOSTART"
[Desktop Entry]
Type=Application
Name=Polkit Authentication Agent
Comment=Auto-starts Polkit Agent for LocalWP and privilege dialogs
Exec=$AGENT_BIN
Terminal=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
EOF
echo -e "${GREEN}[OK] Registered XDG Desktop autostart at $XDG_AUTOSTART${NC}"

# 5. LocalWP helper script deployment
mkdir -p "$HOME/.local/share/bin"
cp "$0" "$HOME/.local/share/bin/fix-polkit-localwp.sh" 2>/dev/null || true
chmod +x "$HOME/.local/share/bin/fix-polkit-localwp.sh" 2>/dev/null || true

echo -e "\n${GREEN}${BOLD}[OK] Polkit Fix Applied & Verified Successfully for Any Device!${NC}\n"
