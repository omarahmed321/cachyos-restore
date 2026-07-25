#!/usr/bin/env bash
#===============================================================================
#   CachyOS & Hyprland Universal Tools Control Center Menu
#   Part of: CachyOS + HyDE Complete System Restorer
#   Repo:    https://github.com/omarahmed321/cachyos-restore
#
#   Usage:
#     ./cachy_tools_menu.sh          → Interactive Terminal CLI Menu
#     ./cachy_tools_menu.sh --gui    → Graphical Rofi/Zenity Launcher Menu
#===============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Color Definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Helper to find tool paths (prefer repo directory, fallback to ~/.local/share/bin/ or ~/)
find_tool() {
    local name="$1"
    if [ -f "$SCRIPT_DIR/$name" ]; then
        echo "$SCRIPT_DIR/$name"
    elif [ -f "$HOME/.local/share/bin/$name" ]; then
        echo "$HOME/.local/share/bin/$name"
    elif [ -f "$HOME/.local/bin/$name" ]; then
        echo "$HOME/.local/bin/$name"
    elif [ -f "$HOME/$name" ]; then
        echo "$HOME/$name"
    else
        echo ""
    fi
}

# Locate script targets
FAV_PATH=$(find_tool "omar-fav-setup.sh")
WP_PATH=$(find_tool "setup-wordpress-local.sh")
NIGHTLIGHT_PATH=$(find_tool "nightlight-gui.py")
DISPLAY_PATH=$(find_tool "hypr-display-settings.py")
ALIGNMENT_PATH=$(find_tool "monitor-alignment.sh")
WAYBAR_PATH=$(find_tool "setup-waybar-glassmorphism.sh")
PAGEUP_PATH=$(find_tool "double-pageup.sh")
HOTSPOT_PATH=$(find_tool "start_hotspot.sh")

# Launchers
launch_fav_setup() {
    if [ -n "$FAV_PATH" ]; then
        echo -e "${GREEN}[+] Launching Omar's Favorite Setup...${NC}"
        bash "$FAV_PATH"
    else
        echo -e "${RED}[ERROR] omar-fav-setup.sh not found!${NC}"
    fi
}

launch_wordpress_setup() {
    if [ -n "$WP_PATH" ]; then
        echo -e "${GREEN}[+] Launching Local WordPress Installer...${NC}"
        bash "$WP_PATH"
    else
        echo -e "${RED}[ERROR] setup-wordpress-local.sh not found!${NC}"
    fi
}

launch_nightlight() {
    if [ -n "$NIGHTLIGHT_PATH" ]; then
        echo -e "${GREEN}[+] Launching Night Light GUI...${NC}"
        python3 "$NIGHTLIGHT_PATH" &
    else
        echo -e "${RED}[ERROR] nightlight-gui.py not found!${NC}"
    fi
}

launch_display_settings() {
    if [ -n "$DISPLAY_PATH" ]; then
        echo -e "${GREEN}[+] Launching Display & Mouse Settings...${NC}"
        python3 "$DISPLAY_PATH" &
    else
        echo -e "${RED}[ERROR] hypr-display-settings.py not found!${NC}"
    fi
}

launch_cursor_alignment() {
    if [ -n "$ALIGNMENT_PATH" ]; then
        echo -e "${GREEN}[+] Launching Dual Monitor Cursor Alignment Calibration...${NC}"
        bash "$ALIGNMENT_PATH"
    else
        echo -e "${RED}[ERROR] monitor-alignment.sh not found!${NC}"
    fi
}

launch_waybar_setup() {
    if [ -n "$WAYBAR_PATH" ]; then
        echo -e "${GREEN}[+] Launching Waybar Glassmorphism Setup...${NC}"
        bash "$WAYBAR_PATH"
    else
        echo -e "${RED}[ERROR] setup-waybar-glassmorphism.sh not found!${NC}"
    fi
}

launch_double_pageup() {
    if [ -n "$PAGEUP_PATH" ]; then
        echo -e "${GREEN}[+] Running Double PageUp Listener helper...${NC}"
        bash "$PAGEUP_PATH" &
        echo -e "${GREEN}[OK] Double PageUp trigger executed.${NC}"
    else
        echo -e "${RED}[ERROR] double-pageup.sh not found!${NC}"
    fi
}

launch_hotspot() {
    if [ -n "$HOTSPOT_PATH" ]; then
        echo -e "${GREEN}[+] Launching Wi-Fi Hotspot Controller...${NC}"
        bash "$HOTSPOT_PATH"
    else
        echo -e "${RED}[ERROR] start_hotspot.sh not found!${NC}"
    fi
}

# Graphical GUI Rofi / Zenity Launcher
gui_menu() {
    if command -v rofi &>/dev/null; then
        SELECTION=$(echo -e "1. ⭐️ Omar's Favorite Setup (omar-fav-setup)\n2. 🌐 Install Local WordPress (LocalWP)\n3. 🌙 Night Light GUI\n4. 🖥️ Display & Mouse Settings\n5. 🎯 Dual Monitor Cursor Alignment\n6. 📊 Waybar Glassmorphism Setup\n7. ⌨️ Double PageUp Trigger\n8. 🔌 Wi-Fi Hotspot Controller" | rofi -dmenu -i -p "CachyOS Control Panel:")
    elif command -v zenity &>/dev/null; then
        SELECTION=$(zenity --list \
            --title="CachyOS Control Panel & System Tools" \
            --text="Choose a tool to launch:" \
            --column="Available Utilities" \
            "1. ⭐️ Omar's Favorite Setup (omar-fav-setup)" \
            "2. 🌐 Install Local WordPress (LocalWP)" \
            "3. 🌙 Night Light GUI" \
            "4. 🖥️ Display & Mouse Settings" \
            "5. 🎯 Dual Monitor Cursor Alignment" \
            "6. 📊 Waybar Glassmorphism Setup" \
            "7. ⌨️ Double PageUp Trigger" \
            "8. 🔌 Wi-Fi Hotspot Controller" \
            --width=450 --height=440 2>/dev/null)
    else
        echo -e "${YELLOW}[!] Neither Rofi nor Zenity found. Falling back to terminal menu...${NC}"
        cli_menu
        return
    fi

    case "$SELECTION" in
        *"Omar's Favorite"*) launch_fav_setup ;;
        *"Local WordPress"*) launch_wordpress_setup ;;
        *"Night Light"*) launch_nightlight ;;
        *"Display & Mouse"*) launch_display_settings ;;
        *"Cursor Alignment"*) launch_cursor_alignment ;;
        *"Waybar Glassmorphism"*) launch_waybar_setup ;;
        *"Double PageUp"*) launch_double_pageup ;;
        *"Hotspot"*) launch_hotspot ;;
        *) exit 0 ;;
    esac
}

# Terminal CLI Menu
cli_menu() {
    while true; do
        clear
        echo -e "${CYAN}${BOLD}"
        cat << "EOF"
  ==============================================================
         CachyOS + Hyprland Unified Tools Launcher Menu
  ==============================================================
EOF
        echo -e "${NC}"
        echo -e "  ${MAGENTA}${BOLD}1)${NC} ⭐️ Omar's Favorite Setup (${YELLOW}omar-fav-setup.sh${NC})"
        echo -e "     Apply Glassmorphism Waybar & set favorite paper background"
        echo
        echo -e "  ${MAGENTA}${BOLD}2)${NC} 🌐 Install Local WordPress (${YELLOW}setup-wordpress-local.sh${NC})"
        echo -e "     Install LocalWP desktop app for local WordPress development"
        echo
        echo -e "  ${MAGENTA}${BOLD}3)${NC} 🌙 Launch Night Light GUI (${YELLOW}nightlight-gui.py${NC})"
        echo -e "     Adjust screen warmth percentage (0%-100%) with instant auto-save"
        echo
        echo -e "  ${MAGENTA}${BOLD}4)${NC} 🖥️ Launch Display & Mouse Settings (${YELLOW}hypr-display-settings.py${NC})"
        echo -e "     Change resolution, refresh rate, custom scaling, and pointer sensitivity"
        echo
        echo -e "  ${MAGENTA}${BOLD}5)${NC} 🎯 Dual Monitor Cursor Alignment Calibration (${YELLOW}monitor-alignment.sh${NC})"
        echo -e "     Calibrate screen boundary alignment & shift cursor movement between dual displays"
        echo
        echo -e "  ${MAGENTA}${BOLD}6)${NC} 📊 Launch Waybar Glassmorphism Setup (${YELLOW}setup-waybar-glassmorphism.sh${NC})"
        echo -e "     Apply or restore 3-island glassmorphic floating Waybar design"
        echo
        echo -e "  ${MAGENTA}${BOLD}7)${NC} ⌨️ Double PageUp Listener Trigger (${YELLOW}double-pageup.sh${NC})"
        echo -e "     Simulate keybinding shortcut for terminal toggling"
        echo
        echo -e "  ${MAGENTA}${BOLD}8)${NC} 🔌 Wi-Fi Hotspot Controller (${YELLOW}start_hotspot.sh${NC})"
        echo -e "     Spawn local Wi-Fi hotspot with QR code display"
        echo
        echo -e "  ${MAGENTA}${BOLD}9)${NC} 🚪 Exit"
        echo -e "${CYAN}--------------------------------------------------------------${NC}"
        read -p " Select choice [1-9]: " choice

        case "$choice" in
            1) launch_fav_setup; read -p "Press Enter to continue..." ;;
            2) launch_wordpress_setup; read -p "Press Enter to continue..." ;;
            3) launch_nightlight; read -p "Press Enter to continue..." ;;
            4) launch_display_settings; read -p "Press Enter to continue..." ;;
            5) launch_cursor_alignment; read -p "Press Enter to continue..." ;;
            6) launch_waybar_setup; read -p "Press Enter to continue..." ;;
            7) launch_double_pageup; read -p "Press Enter to continue..." ;;
            8) launch_hotspot; read -p "Press Enter to continue..." ;;
            9|q|Q) echo -e "${GREEN}Goodbye!${NC}"; exit 0 ;;
            *) echo -e "${RED}[!] Invalid choice.${NC}"; sleep 1 ;;
        esac
    done
}

# Check argument for --gui or auto-detect
if [ "$1" == "--gui" ] || [ ! -t 0 ]; then
    gui_menu
else
    cli_menu
fi
