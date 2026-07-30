#!/usr/bin/env bash
#===============================================================================
#   Zen Browser Glassmorphism & Pywal Theme Customizer
#   Part of: CachyOS + HyDE System Restorer
#   Repo:    https://github.com/omarahmed321/cachyos-restore
#===============================================================================

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}${BOLD}"
cat << "EOF"
  ==============================================================
        Zen Browser Glassmorphism & Pywal Theme Customizer
  ==============================================================
EOF
echo -e "${NC}"

ZEN_BASE_DIR="$HOME/.config/zen"

if [ ! -d "$ZEN_BASE_DIR" ]; then
    echo -e "${YELLOW}[!] Warning: Zen Browser config directory (~/.config/zen) not found.${NC}"
    echo -e "${CYAN}[*] Please launch Zen Browser at least once first.${NC}"
    exit 1
fi

echo -e "${CYAN}[1/3] Locating Zen Browser profiles...${NC}"

mapfile -t PROFILES < <(find "$ZEN_BASE_DIR" -maxdepth 1 -mindepth 1 -type d \( -name "*.Default*" -o -name "*default*" \))

if [ ${#PROFILES[@]} -eq 0 ]; then
    mapfile -t PROFILES < <(find "$ZEN_BASE_DIR" -maxdepth 1 -mindepth 1 -type d ! -name "Profile Groups" ! -name "firefox-mpris")
fi

if [ ${#PROFILES[@]} -eq 0 ]; then
    echo -e "${YELLOW}[!] Error: Could not locate a valid Zen Browser profile directory.${NC}"
    exit 1
fi

echo -e "${CYAN}[2/3] Enabling custom stylesheets in user preferences (prefs.js)...${NC}"

for prof in "${PROFILES[@]}"; do
    [ -d "$prof" ] || continue
    echo -e "${GREEN}[+] Target Profile: $(basename "$prof")${NC}"
    PREFS_FILE="$prof/prefs.js"
    
    if [ -f "$PREFS_FILE" ]; then
        if ! grep -q "toolkit.legacyUserProfileCustomizations.stylesheets" "$PREFS_FILE"; then
            echo 'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);' >> "$PREFS_FILE"
        fi
        if ! grep -q "svg.context-properties.content.enabled" "$PREFS_FILE"; then
            echo 'user_pref("svg.context-properties.content.enabled", true);' >> "$PREFS_FILE"
        fi
    else
        cat << 'EOF' > "$PREFS_FILE"
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
user_pref("svg.context-properties.content.enabled", true);
EOF
    fi

    CHROME_DIR="$prof/chrome"
    mkdir -p "$CHROME_DIR"
    
    USER_CHROME="$CHROME_DIR/userChrome.css"
    USER_CONTENT="$CHROME_DIR/userContent.css"

    echo -e "${CYAN}[3/3] Writing Glassmorphism 3-Island theme to userChrome.css...${NC}"
    
    cat << 'EOF' > "$USER_CHROME"
/* =============================================================================
   Zen Browser Glassmorphism & Pywal Theme (3-Island Floating Style)
   ============================================================================= */

:root {
  --zen-dark-bg: rgba(29, 32, 33, 0.75);
  --zen-glass-bg: rgba(40, 40, 40, 0.55);
  --zen-glass-border: rgba(131, 165, 152, 0.35);
  --zen-accent-color: #83a598;
  --zen-border-radius: 14px;
}

/* Glassmorphism sidebar & tab strip container */
#sidebar-box,
#tabbrowser-tabs,
.zen-sidebar-panel,
#navigator-toolbox {
  background-color: var(--zen-dark-bg) !important;
  backdrop-filter: blur(16px) saturate(140%) !important;
  border-radius: var(--zen-border-radius) !important;
  border: 1px solid var(--zen-glass-border) !important;
}

/* Floating rounded URL bar */
#urlbar-background {
  background-color: var(--zen-glass-bg) !important;
  backdrop-filter: blur(12px) !important;
  border-radius: 20px !important;
  border: 1px solid var(--zen-glass-border) !important;
}

/* Tab buttons styling */
.tabbrowser-tab .tab-stack {
  border-radius: 10px !important;
  transition: all 0.2s ease-in-out !important;
}

.tabbrowser-tab[selected="true"] .tab-stack {
  background-color: rgba(131, 165, 152, 0.25) !important;
  border: 1px solid var(--zen-accent-color) !important;
}

/* Remove default harsh borders */
#navigator-toolbox {
  border-bottom: none !important;
}
EOF

    cat << 'EOF' > "$USER_CONTENT"
/* Zen Browser Content Glassmorphism overrides */
@-moz-document url("about:newtab"), url("about:home") {
  body {
    background-color: #1d2021 !important;
    color: #ebdbb2 !important;
  }
}
EOF

done

# Copy script to user bin
mkdir -p "$HOME/.local/share/bin"
cp "$0" "$HOME/.local/share/bin/setup-zen-browser-theme.sh" 2>/dev/null || true
chmod +x "$HOME/.local/share/bin/setup-zen-browser-theme.sh" 2>/dev/null || true

echo -e "\n${GREEN}${BOLD}[OK] Zen Browser Glassmorphism Theme Installed & Applied Successfully!${NC}"
echo -e "${CYAN}[*] Restart Zen Browser to experience the new Glassmorphism design.${NC}\n"
