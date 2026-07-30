#!/usr/bin/env bash
#===============================================================================
#   Zen Mode Minimal Focus Toggle Script
#   Part of: CachyOS + HyDE System Restorer
#   Repo:    https://github.com/omarahmed321/cachyos-restore
#===============================================================================

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

STATE_FILE="$HOME/.cache/zen_mode_state"

if [ ! -f "$STATE_FILE" ]; then
    echo "off" > "$STATE_FILE"
fi

CURRENT_STATE=$(cat "$STATE_FILE")

if [ "$CURRENT_STATE" == "off" ]; then
    echo -e "${CYAN}[+] Enabling Zen Mode (Minimal Focus)...${NC}"
    
    # Hide Waybar
    pkill waybar 2>/dev/null || true
    
    # Apply Hyprland zero gaps & zero borders
    hyprctl keyword general:gaps_in 0 >/dev/null 2>&1 || true
    hyprctl keyword general:gaps_out 0 >/dev/null 2>&1 || true
    hyprctl keyword general:border_size 0 >/dev/null 2>&1 || true
    
    echo "on" > "$STATE_FILE"
    notify-send -u normal "🧘 Zen Mode Enabled" "Waybar hidden & workspace set to borderless minimal focus." 2>/dev/null || true
    echo -e "${GREEN}[OK] Zen Mode Enabled.${NC}"
else
    echo -e "${CYAN}[+] Disabling Zen Mode (Restoring Standard Layout)...${NC}"
    
    # Restore Hyprland gaps & borders
    hyprctl keyword general:gaps_in 4 >/dev/null 2>&1 || true
    hyprctl keyword general:gaps_out 8 >/dev/null 2>&1 || true
    hyprctl keyword general:border_size 2 >/dev/null 2>&1 || true
    
    # Restore Waybar if not running
    if ! pgrep -x waybar >/dev/null; then
        if [ -f "$HOME/.local/share/bin/setup-waybar-glassmorphism.sh" ]; then
            bash "$HOME/.local/share/bin/setup-waybar-glassmorphism.sh" >/dev/null 2>&1 &
        else
            waybar >/dev/null 2>&1 &
        fi
    fi
    
    echo "off" > "$STATE_FILE"
    notify-send -u normal "✨ Zen Mode Disabled" "Waybar restored & standard workspace layout active." 2>/dev/null || true
    echo -e "${GREEN}[OK] Standard Layout Restored.${NC}"
fi
