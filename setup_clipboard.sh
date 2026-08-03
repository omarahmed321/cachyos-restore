#!/usr/bin/env bash
#===============================================================================
#   Standalone Clipboard Manager Setup (wl-clipboard + cliphist + rofi)
#   This script installs and configures a clean, standalone clipboard manager
#   compatible with any Wayland/Hyprland environment without external dependencies.
#===============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# --- Root Check ---
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}[ERROR] Please do NOT run this script as root. Run it as your normal user.${NC}"
    exit 1
fi

echo -e "${BLUE}${BOLD}======================================================================${NC}"
echo -e "${BLUE}${BOLD}         Standalone Clipboard History Installer & Setup                ${NC}"
echo -e "${BLUE}${BOLD}======================================================================${NC}"

# --- Step 1: Install Dependencies ---
echo -e "\n${BLUE}${BOLD}[1/3] Checking and installing dependencies...${NC}"
DEPENDENCIES=(wl-clipboard cliphist rofi-wayland libnotify jq)
TO_INSTALL=()

for pkg in "${DEPENDENCIES[@]}"; do
    if pacman -Qi "$pkg" &>/dev/null; then
        echo -e "  - ${GREEN}[Installed]${NC} $pkg"
    else
        TO_INSTALL+=("$pkg")
    fi
done

if [ ${#TO_INSTALL[@]} -gt 0 ]; then
    echo -e "${YELLOW}[*] Installing missing dependencies: ${TO_INSTALL[*]}...${NC}"
    
    # Auto detect AUR Helper
    AUR_HELPER=""
    if command -v yay &>/dev/null; then
        AUR_HELPER="yay"
    elif command -v paru &>/dev/null; then
        AUR_HELPER="paru"
    else
        # Install fallback via pacman
        AUR_HELPER="sudo pacman"
    fi
    
    $AUR_HELPER -S --needed --noconfirm "${TO_INSTALL[@]}"
fi

# --- Step 2: Deploy Standalone cliphist-menu.sh ---
echo -e "\n${BLUE}${BOLD}[2/3] Writing standalone clipboard manager script...${NC}"
mkdir -p "$HOME/.local/bin"
MENU_SCRIPT="$HOME/.local/bin/cliphist-menu.sh"

cat << 'EOF' > "$MENU_SCRIPT"
#!/usr/bin/env bash
#===============================================================================
#   Standalone Rofi Clipboard History Selector
#   Supports viewing history, deleting items, and clearing the entire log.
#===============================================================================

# Define standard configurations
ROFI_THEME="-theme-str 'window { width: 40%; } listview { lines: 10; }'"
FAVORITES_FILE="$HOME/.cliphist_favorites"

# Check if arguments are passed. Default to History if no arguments
main_action=""
if [ $# -eq 0 ]; then
    main_action=$(echo -e "📋 Clipboard History\n❌ Delete Entry\n⭐ View Favorites\n➕ Add to Favorites\n🗑️ Clear History" | rofi -dmenu -i -p "Clipboard Actions" -font "JetBrainsMono Nerd Font 11" $ROFI_THEME)
else
    main_action="📋 Clipboard History"
fi

case "$main_action" in
    "📋 Clipboard History")
        selected=$(cliphist list | rofi -dmenu -i -p "Paste Item" -font "JetBrainsMono Nerd Font 11" $ROFI_THEME)
        if [ -n "$selected" ]; then
            echo "$selected" | cliphist decode | wl-copy
            notify-send "Clipboard" "Item copied to active clipboard" -i edit-paste
        fi
        ;;
    "❌ Delete Entry")
        selected=$(cliphist list | rofi -dmenu -i -p "Delete Item" -font "JetBrainsMono Nerd Font 11" $ROFI_THEME)
        if [ -n "$selected" ]; then
            echo "$selected" | cliphist delete
            notify-send "Clipboard" "Item deleted from history" -i edit-delete
        fi
        ;;
    "⭐ View Favorites")
        if [ -f "$FAVORITES_FILE" ] && [ -s "$FAVORITES_FILE" ]; then
            # Read and decode each favorite
            mapfile -t favorites < "$FAVORITES_FILE"
            decoded_lines=()
            for fav in "${favorites[@]}"; do
                decoded_lines+=("$(echo "$fav" | base64 --decode | tr '\n' ' ' | cut -c1-60)...")
            done
            
            selected_fav=$(printf "%s\n" "${decoded_lines[@]}" | rofi -dmenu -i -p "Favorite Item" -font "JetBrainsMono Nerd Font 11" $ROFI_THEME)
            if [ -n "$selected_fav" ]; then
                # Find matching index and copy base64 content
                index=$(printf "%s\n" "${decoded_lines[@]}" | grep -nxF "$selected_fav" | cut -d: -f1)
                if [ -n "$index" ]; then
                    echo "${favorites[$((index - 1))]}" | base64 --decode | wl-copy
                    notify-send "Clipboard" "Favorite item copied to active clipboard" -i edit-paste
                fi
            fi
        else
            notify-send "Clipboard" "No favorites saved yet" -i dialog-warning
        fi
        ;;
    "➕ Add to Favorites")
        selected=$(cliphist list | rofi -dmenu -i -p "Add to Favorites" -font "JetBrainsMono Nerd Font 11" $ROFI_THEME)
        if [ -n "$selected" ]; then
            full_item=$(echo "$selected" | cliphist decode)
            encoded_item=$(echo "$full_item" | base64 -w 0)
            
            # Check if already exists in favorites
            if grep -Fxq "$encoded_item" "$FAVORITES_FILE" 2>/dev/null; then
                notify-send "Clipboard" "Item is already in favorites" -i dialog-information
            else
                echo "$encoded_item" >> "$FAVORITES_FILE"
                notify-send "Clipboard" "Added to favorites successfully" -i emc-favorites
            fi
        fi
        ;;
    "🗑️ Clear History")
        confirm=$(echo -e "No\nYes" | rofi -dmenu -i -p "Clear Entire Clipboard History?" -font "JetBrainsMono Nerd Font 11" $ROFI_THEME)
        if [ "$confirm" = "Yes" ]; then
            cliphist wipe
            notify-send "Clipboard" "Entire clipboard history has been cleared" -i edit-clear
        fi
        ;;
esac
EOF

chmod +x "$MENU_SCRIPT"
echo -e "${GREEN}[+] Standalone script written and made executable at: $MENU_SCRIPT${NC}"

# --- Step 3: Autostart in Hyprland ---
echo -e "\n${BLUE}${BOLD}[3/3] Setting up Hyprland integration...${NC}"
HYPR_CONF="$HOME/.config/hypr/hyprland.conf"
if [ -f "$HYPR_CONF" ]; then
    # Add exec-once daemons if not present
    if ! grep -q "cliphist store" "$HYPR_CONF"; then
        echo -e "\n# Standalone Clipboard History Listeners" >> "$HYPR_CONF"
        echo "exec-once = wl-paste --type text --watch cliphist store" >> "$HYPR_CONF"
        echo "exec-once = wl-paste --type image --watch cliphist store" >> "$HYPR_CONF"
        echo -e "${GREEN}[+] Clipboard listener daemons appended to $HYPR_CONF${NC}"
    else
        echo -e "${YELLOW}[*] Clipboard listener daemons are already configured in $HYPR_CONF${NC}"
    fi
    
    # Add Keybinding if not present
    KEY_CONF="$HOME/.config/hypr/keybindings.conf"
    if [ -f "$KEY_CONF" ]; then
        if ! grep -q "cliphist-menu.sh" "$KEY_CONF"; then
            echo -e "\n# Clipboard History Hotkeys\nbind = \$mainMod, V, exec, $MENU_SCRIPT" >> "$KEY_CONF"
            echo -e "${GREEN}[+] Super + V keybinding appended to $KEY_CONF${NC}"
        else
            echo -e "${YELLOW}[*] Keybinding for cliphist-menu.sh already configured in $KEY_CONF${NC}"
        fi
    fi
else
    echo -e "${YELLOW}[!] hyprland.conf was not found. Please manually launch these commands at startup:${NC}"
    echo "  wl-paste --type text --watch cliphist store &"
    echo "  wl-paste --type image --watch cliphist store &"
fi

echo -e "\n${GREEN}${BOLD}======================================================================${NC}"
echo -e "${GREEN}${BOLD}   Clipboard setup completed successfully!                            ${NC}"
echo -e "${GREEN}${BOLD}   Use Super + V to open the clipboard history overlay.              ${NC}"
echo -e "${GREEN}${BOLD}======================================================================${NC}"
