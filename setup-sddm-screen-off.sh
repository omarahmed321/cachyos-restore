#!/usr/bin/env bash
#===============================================================================
#   Standalone SDDM Screen Visibility & Disabler Tool (CLI & GUI)
#   Part of: CachyOS + HyDE System Restorer
#   Repo:    https://github.com/omarahmed321/cachyos-restore
#===============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}${BOLD}"
cat << "EOF"
  ==============================================================
     SDDM Screen Disabler & Visibility Manager (Universal)
  ==============================================================
EOF
echo -e "${NC}"

# If GUI environment is active, launch Python GUI panel
if command -v python3 &>/dev/null && [ -f "$SCRIPT_DIR/sddm-off-screen-config.py" ] && [ -n "$WAYLAND_DISPLAY" -o -n "$DISPLAY" ]; then
    echo -e "${GREEN}[+] Launching SDDM Screen Disabler GUI...${NC}"
    python3 "$SCRIPT_DIR/sddm-off-screen-config.py" &
    exit 0
fi

# Fallback: CLI Terminal Mode
if command -v hyprctl &>/dev/null && hyprctl monitors &>/dev/null; then
    MONITORS_JSON=$(hyprctl monitors -j)
    MONITOR_NAMES=($(echo "$MONITORS_JSON" | jq -r '.[].name'))
    NUM_MONITORS=${#MONITOR_NAMES[@]}
    
    if [ "$NUM_MONITORS" -gt 0 ]; then
        echo -e "${YELLOW}Connected Monitors Detected:${NC}"
        for i in "${!MONITOR_NAMES[@]}"; do
            m_name="${MONITOR_NAMES[i]}"
            m_w=$(echo "$MONITORS_JSON" | jq -r ".[$i].width")
            m_h=$(echo "$MONITORS_JSON" | jq -r ".[$i].height")
            m_hz=$(echo "$MONITORS_JSON" | jq -r ".[$i].refreshRate" | cut -d'.' -f1)
            echo -e "  [$((i+1))] ${GREEN}${m_name}${NC} (${m_w}x${m_h}@${m_hz}Hz)"
        done
        
        echo -e "\n${CYAN}Select which screens to TURN OFF during SDDM login (comma-separated numbers, e.g. 2):${NC}"
        echo -e "  [0] Keep SDDM ON for all screens"
        read -p "  Enter selection [0-$NUM_MONITORS]: " choice
        
        if [ "$choice" != "0" ] && [ -n "$choice" ]; then
            DISABLED_ARR=()
            IFS=',' read -ra ADDR <<< "$choice"
            for num in "${ADDR[@]}"; do
                idx=$((num - 1))
                if [ $idx -ge 0 ] && [ $idx -lt $NUM_MONITORS ]; then
                    DISABLED_ARR+=("${MONITOR_NAMES[idx]}")
                fi
            done
            if [ ${#DISABLED_ARR[@]} -gt 0 ]; then
                python3 "$SCRIPT_DIR/sddm-off-screen-config.py" --disable "${DISABLED_ARR[@]}"
                echo -e "${GREEN}[OK] Turned OFF SDDM on: ${DISABLED_ARR[*]}${NC}"
            fi
        else
            python3 "$SCRIPT_DIR/sddm-off-screen-config.py" --disable
            echo -e "${GREEN}[OK] SDDM enabled on all screens.${NC}"
        fi
    fi
fi
