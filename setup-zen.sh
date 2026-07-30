#!/usr/bin/env bash
#===============================================================================
#   Unified Zen Suite (Zen Browser Glassmorphism & Zen Minimal Focus Mode)
#   Part of: CachyOS + HyDE System Restorer
#   Repo:    https://github.com/omarahmed321/cachyos-restore
#===============================================================================

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}${BOLD}"
cat << "EOF"
  ==============================================================
           Unified Zen Setup Suite (Browser & Mode)
  ==============================================================
EOF
echo -e "${NC}"

# --- PART 1: Zen Browser Glassmorphism CSS Theme ---
echo -e "${MAGENTA}[1/2] Configuring Zen Browser Glassmorphism CSS Theme...${NC}"

ZEN_BASE_DIR="$HOME/.config/zen"

if [ -d "$ZEN_BASE_DIR" ]; then
    mapfile -t PROFILES < <(find "$ZEN_BASE_DIR" -maxdepth 1 -mindepth 1 -type d \( -name "*.Default*" -o -name "*default*" \))
    if [ ${#PROFILES[@]} -eq 0 ]; then
        mapfile -t PROFILES < <(find "$ZEN_BASE_DIR" -maxdepth 1 -mindepth 1 -type d ! -name "Profile Groups" ! -name "firefox-mpris")
    fi

    for prof in "${PROFILES[@]}"; do
        [ -d "$prof" ] || continue
        echo -e "${GREEN}[+] Zen Profile: $(basename "$prof")${NC}"
        PREFS_FILE="$prof/prefs.js"
        if [ -f "$PREFS_FILE" ]; then
            if ! grep -q "toolkit.legacyUserProfileCustomizations.stylesheets" "$PREFS_FILE"; then
                echo 'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);' >> "$PREFS_FILE"
            fi
        else
            echo 'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);' > "$PREFS_FILE"
        fi

        CHROME_DIR="$prof/chrome"
        mkdir -p "$CHROME_DIR"
        cat << 'EOF_CSS' > "$CHROME_DIR/userChrome.css"
/* Zen Browser Glassmorphism 3-Island Theme */
:root {
  --zen-dark-bg: rgba(29, 32, 33, 0.75);
  --zen-glass-bg: rgba(40, 40, 40, 0.55);
  --zen-glass-border: rgba(131, 165, 152, 0.35);
  --zen-accent-color: #83a598;
  --zen-border-radius: 14px;
}
#sidebar-box, #tabbrowser-tabs, .zen-sidebar-panel, #navigator-toolbox {
  background-color: var(--zen-dark-bg) !important;
  backdrop-filter: blur(16px) saturate(140%) !important;
  border-radius: var(--zen-border-radius) !important;
  border: 1px solid var(--zen-glass-border) !important;
}
#urlbar-background {
  background-color: var(--zen-glass-bg) !important;
  backdrop-filter: blur(12px) !important;
  border-radius: 20px !important;
  border: 1px solid var(--zen-glass-border) !important;
}
EOF_CSS
    done
    echo -e "${GREEN}[OK] Zen Browser Theme applied successfully.${NC}"
else
    echo -e "${YELLOW}[!] Zen Browser config directory (~/.config/zen) not found. Skipping CSS theme.${NC}"
fi

# --- PART 2: Toggle Minimal Zen Focus Mode ---
echo -e "\n${MAGENTA}[2/2] Toggling Minimal Zen Focus Mode...${NC}"

STATE_FILE="$HOME/.cache/zen_mode_state"
if [ ! -f "$STATE_FILE" ]; then
    echo "off" > "$STATE_FILE"
fi

CURRENT_STATE=$(cat "$STATE_FILE")

if [ "$CURRENT_STATE" == "off" ]; then
    echo -e "${CYAN}[+] Enabling Minimal Zen Focus Mode...${NC}"
    pkill waybar 2>/dev/null || true
    hyprctl keyword general:gaps_in 0 >/dev/null 2>&1 || true
    hyprctl keyword general:gaps_out 0 >/dev/null 2>&1 || true
    hyprctl keyword general:border_size 0 >/dev/null 2>&1 || true
    echo "on" > "$STATE_FILE"
    notify-send -u normal "🧘 Zen Focus Mode Enabled" "Waybar hidden & workspace set to borderless focus." 2>/dev/null || true
    echo -e "${GREEN}[OK] Zen Focus Mode Active.${NC}"
else
    echo -e "${CYAN}[+] Disabling Minimal Zen Focus Mode...${NC}"
    hyprctl keyword general:gaps_in 4 >/dev/null 2>&1 || true
    hyprctl keyword general:gaps_out 8 >/dev/null 2>&1 || true
    hyprctl keyword general:border_size 2 >/dev/null 2>&1 || true
    if ! pgrep -x waybar >/dev/null; then
        if [ -f "$HOME/.local/share/bin/setup-waybar-glassmorphism.sh" ]; then
            bash "$HOME/.local/share/bin/setup-waybar-glassmorphism.sh" >/dev/null 2>&1 &
        else
            waybar >/dev/null 2>&1 &
        fi
    fi
    echo "off" > "$STATE_FILE"
    notify-send -u normal "✨ Zen Focus Mode Disabled" "Waybar & standard workspace layout restored." 2>/dev/null || true
    echo -e "${GREEN}[OK] Standard Layout Restored.${NC}"
fi

# Copy script to user bin
mkdir -p "$HOME/.local/share/bin"
cp "$0" "$HOME/.local/share/bin/setup-zen.sh" 2>/dev/null || true
chmod +x "$HOME/.local/share/bin/setup-zen.sh" 2>/dev/null || true

echo -e "\n${GREEN}${BOLD}[OK] Unified Zen Suite setup completed successfully!${NC}\n"
