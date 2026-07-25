#!/usr/bin/env bash
#===============================================================================
#   Dual Monitor Cursor Alignment & Position Calibration Tool
#   Part of: CachyOS + HyDE Complete System Restorer
#   Repo:    https://github.com/omarahmed321/cachyos-restore
#===============================================================================

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}${BOLD}"
cat << "EOF"
  ==============================================================
   Dual Monitor Cursor Alignment & Boundary Calibration Tool
  ==============================================================
EOF
echo -e "${NC}"

# Check Hyprland environment
if [ -z "$WAYLAND_DISPLAY" ]; then
    echo -e "${RED}[ERROR] Wayland display not found. This script requires active Hyprland session.${NC}"
    exit 1
fi

# Detect monitors using hyprctl
MONITORS_JSON=$(hyprctl monitors -j 2>/dev/null)
MONITOR_COUNT=$(echo "$MONITORS_JSON" | jq '. | length' 2>/dev/null || echo "0")

if [ "$MONITOR_COUNT" -lt 2 ]; then
    echo -e "${YELLOW}[WARNING] Only $MONITOR_COUNT monitor detected. Alignment calibration requires dual monitors.${NC}"
    if command -v zenity &>/dev/null; then
        zenity --warning --title="Single Monitor Detected" --text="Only 1 monitor was detected on this system.\nDual monitor cursor alignment requires at least 2 connected displays." --width=350 2>/dev/null
    fi
    exit 0
fi

# Extract primary and secondary monitor names & modes
MAIN_NAME=$(echo "$MONITORS_JSON" | jq -r '.[] | select(.isFocused == true or .id == 0) | .name' | head -n 1)
SIDE_NAME=$(echo "$MONITORS_JSON" | jq -r ".[] | select(.name != \"$MAIN_NAME\") | .name" | head -n 1)

MAIN_WIDTH=$(echo "$MONITORS_JSON" | jq -r ".[] | select(.name == \"$MAIN_NAME\") | .width")
MAIN_HEIGHT=$(echo "$MONITORS_JSON" | jq -r ".[] | select(.name == \"$MAIN_NAME\") | .height")
MAIN_HZ=$(echo "$MONITORS_JSON" | jq -r ".[] | select(.name == \"$MAIN_NAME\") | .refreshRate" | cut -d'.' -f1)

SIDE_WIDTH=$(echo "$MONITORS_JSON" | jq -r ".[] | select(.name == \"$SIDE_NAME\") | .width")
SIDE_HEIGHT=$(echo "$MONITORS_JSON" | jq -r ".[] | select(.name == \"$SIDE_NAME\") | .height")
SIDE_HZ=$(echo "$MONITORS_JSON" | jq -r ".[] | select(.name == \"$SIDE_NAME\") | .refreshRate" | cut -d'.' -f1)

MAIN_TRANSFORM=0
SIDE_TRANSFORM=1
OFFSET_Y=0

echo -e "Main Monitor:      ${GREEN}${MAIN_NAME} (${MAIN_WIDTH}x${MAIN_HEIGHT}@${MAIN_HZ}Hz)${NC}"
echo -e "Secondary Monitor: ${GREEN}${SIDE_NAME} (${SIDE_WIDTH}x${SIDE_HEIGHT}@${SIDE_HZ}Hz)${NC}"

# Calibration Loop using Zenity
while true; do
    if [ "$SIDE_TRANSFORM" -eq 1 ] || [ "$SIDE_TRANSFORM" -eq 3 ]; then
        ROTATED_SIDE_WIDTH=${SIDE_HEIGHT}
        ROTATED_SIDE_HEIGHT=${SIDE_WIDTH}
    else
        ROTATED_SIDE_WIDTH=${SIDE_WIDTH}
        ROTATED_SIDE_HEIGHT=${SIDE_HEIGHT}
    fi
    
    if [ "$MAIN_TRANSFORM" -eq 1 ] || [ "$MAIN_TRANSFORM" -eq 3 ]; then
        ROTATED_MAIN_WIDTH=${MAIN_HEIGHT}
        ROTATED_MAIN_HEIGHT=${MAIN_WIDTH}
    else
        ROTATED_MAIN_WIDTH=${MAIN_WIDTH}
        ROTATED_MAIN_HEIGHT=${MAIN_HEIGHT}
    fi
    
    OFFSET_X=${ROTATED_SIDE_WIDTH}
    
    MONITOR_CONFIGS="monitor = ${MAIN_NAME},${MAIN_WIDTH}x${MAIN_HEIGHT}@${MAIN_HZ},${OFFSET_X}x${OFFSET_Y},1,transform,${MAIN_TRANSFORM}\n"
    MONITOR_CONFIGS="${MONITOR_CONFIGS}monitor = ${SIDE_NAME},${SIDE_WIDTH}x${SIDE_HEIGHT}@${SIDE_HZ},0x0,1,transform,${SIDE_TRANSFORM}"
    
    mkdir -p "$HOME/.config/hypr"
    cat << MONEOF > "$HOME/.config/hypr/monitors.conf"
# █▀▄▀█ █▀█ █▄░█ █ ▀█▀ █▀█ █▀█ █▀
# █░▀░█ █▄█ █░▀█ █ ░█░ █▄█ █▀▄ ▄█
# Dynamically configured by monitor-alignment.sh

$(echo -e "$MONITOR_CONFIGS")
MONEOF
    
    # Apply changes dynamically in Hyprland
    if command -v hyprctl &>/dev/null; then
        hyprctl keyword monitor "${MAIN_NAME},${MAIN_WIDTH}x${MAIN_HEIGHT}@${MAIN_HZ},${OFFSET_X}x${OFFSET_Y},1,transform,${MAIN_TRANSFORM}" &>/dev/null
        hyprctl keyword monitor "${SIDE_NAME},${SIDE_WIDTH}x${SIDE_HEIGHT}@${SIDE_HZ},0x0,1,transform,${SIDE_TRANSFORM}" &>/dev/null
        hyprctl reload &>/dev/null
    fi

    # Show list dialog
    if command -v zenity &>/dev/null; then
        choice=$(zenity --list \
            --title="Mouse Path & Monitor Alignment Calibration" \
            --text="Adjust screen rotation or vertical alignment (Y-offset).\nCurrent Y-Offset: ${OFFSET_Y}px" \
            --column="Action / Adjustment" \
            "Rotate Secondary: Landscape (Normal)" \
            "Rotate Secondary: Portrait (90°)" \
            "Rotate Secondary: Flipped Landscape (180°)" \
            "Rotate Secondary: Flipped Portrait (270°)" \
            "Rotate Main: Landscape (Normal)" \
            "Rotate Main: Portrait (90°)" \
            "Enter Custom Y-Offset Value" \
            "Shift Main Monitor Down (+50px)" \
            "Shift Main Monitor Up (-50px)" \
            "Fine-tune Down (+10px)" \
            "Fine-tune Up (-10px)" \
            "Save and Exit" \
            --width=480 --height=550 2>/dev/null)
    else
        echo -e "\n${CYAN}1) Rotate Secondary: Landscape (Normal)${NC}"
        echo -e "${CYAN}2) Rotate Secondary: Portrait (90°)${NC}"
        echo -e "${CYAN}3) Shift Main Monitor Down (+50px)${NC}"
        echo -e "${CYAN}4) Shift Main Monitor Up (-50px)${NC}"
        echo -e "${CYAN}5) Save and Exit${NC}"
        read -p "Select option [1-5]: " cli_choice
        case "$cli_choice" in
            1) choice="Rotate Secondary: Landscape (Normal)" ;;
            2) choice="Rotate Secondary: Portrait (90°)" ;;
            3) choice="Shift Main Monitor Down (+50px)" ;;
            4) choice="Shift Main Monitor Up (-50px)" ;;
            *) choice="Save and Exit" ;;
        esac
    fi
        
    case "$choice" in
        "Rotate Secondary: Landscape (Normal)")
            SIDE_TRANSFORM=0
            ROTATED_SIDE_HEIGHT=${SIDE_HEIGHT}
            OFFSET_Y=$(( (ROTATED_SIDE_HEIGHT - ROTATED_MAIN_HEIGHT) / 2 ))
            [ $OFFSET_Y -lt 0 ] && OFFSET_Y=0
            ;;
        "Rotate Secondary: Portrait (90°)")
            SIDE_TRANSFORM=1
            ROTATED_SIDE_HEIGHT=${SIDE_WIDTH}
            OFFSET_Y=$(( (ROTATED_SIDE_HEIGHT - ROTATED_MAIN_HEIGHT) / 2 ))
            [ $OFFSET_Y -lt 0 ] && OFFSET_Y=0
            ;;
        "Rotate Secondary: Flipped Landscape (180°)")
            SIDE_TRANSFORM=2
            ROTATED_SIDE_HEIGHT=${SIDE_HEIGHT}
            OFFSET_Y=$(( (ROTATED_SIDE_HEIGHT - ROTATED_MAIN_HEIGHT) / 2 ))
            [ $OFFSET_Y -lt 0 ] && OFFSET_Y=0
            ;;
        "Rotate Secondary: Flipped Portrait (270°)")
            SIDE_TRANSFORM=3
            ROTATED_SIDE_HEIGHT=${SIDE_WIDTH}
            OFFSET_Y=$(( (ROTATED_SIDE_HEIGHT - ROTATED_MAIN_HEIGHT) / 2 ))
            [ $OFFSET_Y -lt 0 ] && OFFSET_Y=0
            ;;
        "Rotate Main: Landscape (Normal)")
            MAIN_TRANSFORM=0
            ROTATED_MAIN_HEIGHT=${MAIN_HEIGHT}
            OFFSET_Y=$(( (ROTATED_SIDE_HEIGHT - ROTATED_MAIN_HEIGHT) / 2 ))
            [ $OFFSET_Y -lt 0 ] && OFFSET_Y=0
            ;;
        "Rotate Main: Portrait (90°)")
            MAIN_TRANSFORM=1
            ROTATED_MAIN_HEIGHT=${MAIN_WIDTH}
            OFFSET_Y=$(( (ROTATED_SIDE_HEIGHT - ROTATED_MAIN_HEIGHT) / 2 ))
            [ $OFFSET_Y -lt 0 ] && OFFSET_Y=0
            ;;
        "Enter Custom Y-Offset Value")
            if command -v zenity &>/dev/null; then
                custom_val=$(zenity --entry \
                    --title="Custom Y-Offset" \
                    --text="Enter Y-offset in pixels (e.g., 0, 100, 200...):" \
                    --entry-text="$OFFSET_Y" 2>/dev/null)
            else
                read -p "Enter custom Y-offset in pixels: " custom_val
            fi
            if [[ "$custom_val" =~ ^-?[0-9]+$ ]]; then
                OFFSET_Y=$custom_val
            fi
            ;;
        "Shift Main Monitor Down (+50px)")
            OFFSET_Y=$((OFFSET_Y + 50))
            ;;
        "Shift Main Monitor Up (-50px)")
            OFFSET_Y=$((OFFSET_Y - 50))
            ;;
        "Fine-tune Down (+10px)")
            OFFSET_Y=$((OFFSET_Y + 10))
            ;;
        "Fine-tune Up (-10px)")
            OFFSET_Y=$((OFFSET_Y - 10))
            ;;
        *)
            echo -e "${GREEN}[+] Alignment configuration saved to ~/.config/hypr/monitors.conf successfully!${NC}"
            break
            ;;
    esac
done
