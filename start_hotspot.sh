#!/bin/bash

# --- Color Definitions ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# --- Default Configurations ---
DEFAULT_SSID="tplink-7825"
DEFAULT_PASS="bolbol123*#"
WIFI_INT="wlan0"
INTERNET_INT="enp37s0"
CHANNEL="11"

# --- Root Check & Auto-Sudo ---
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}[!] This script needs root privileges. Rerunning with sudo...${NC}"
    exec sudo "$0" "$@"
fi

# --- Parameter Parsing ---
SSID="${1:-$DEFAULT_SSID}"
PASSPHRASE="${2:-$DEFAULT_PASS}"

# --- Banner ---
show_banner() {
    clear
    echo -e "${CYAN}${BOLD}====================================================${NC}"
    echo -e "${MAGENTA}${BOLD}     TP-Link TL-WN722N v2 Hotspot Controller        ${NC}"
    echo -e "${CYAN}${BOLD}====================================================${NC}"
    echo -e "Interface:  ${GREEN}${WIFI_INT}${NC}"
    echo -e "Internet:   ${GREEN}${INTERNET_INT}${NC}"
    echo -e "Channel:    ${GREEN}${CHANNEL}${NC}"
    echo -e "SSID:       ${YELLOW}${SSID}${NC}"
    echo -e "Password:   ${YELLOW}${PASSPHRASE}${NC}"
    echo -e "${CYAN}----------------------------------------------------${NC}"
}

# Show configurations
show_banner

# --- Check Prerequisites ---
if ! command -v create_ap &> /dev/null; then
    echo -e "${RED}[-] Error: create_ap is not installed.${NC}"
    echo -e "${YELLOW}[*] Please install it first (e.g., yay -S create_ap).${NC}"
    exit 1
fi

if ! ip link show "$WIFI_INT" &> /dev/null; then
    echo -e "${RED}[-] Error: Wi-Fi interface '$WIFI_INT' not found!${NC}"
    echo -e "${YELLOW}[*] Available interfaces:${NC}"
    ip link show | grep -E "^[0-9]+: "
    exit 1
fi

# --- Cleanup Function ---
cleanup() {
    echo -e "\n${YELLOW}[*] Shutting down hotspot and cleaning up...${NC}"
    
    # Terminate create_ap and child processes
    if [ -n "$CREATE_AP_PID" ]; then
        kill -TERM "$CREATE_AP_PID" 2>/dev/null
    fi
    
    # Force kill dnsmasq and hostapd just to be sure
    killall -9 hostapd dnsmasq create_ap 2>/dev/null
    
    # Re-enable Wi-Fi Power Saving
    iw dev "$WIFI_INT" set power_save on 2>/dev/null
    
    echo -e "${GREEN}[+] Cleanup complete. Hotspot stopped.${NC}"
    exit 0
}

# Setup traps for SIGINT (Ctrl+C), SIGTERM, SIGHUP, and EXIT
trap cleanup SIGINT SIGTERM SIGHUP EXIT

# --- Start Hotspot ---
echo -e "${CYAN}[*] Stopping any conflicting services...${NC}"
killall -9 create_ap dnsmasq hostapd 2>/dev/null || true
sleep 1

echo -e "${CYAN}[*] Disabling Wi-Fi Power Saving on $WIFI_INT...${NC}"
iw dev "$WIFI_INT" set power_save off 2>/dev/null || true

echo -e "${GREEN}[+] Starting Hotspot... (Press Ctrl+C to stop)${NC}"
echo -e "${CYAN}----------------------------------------------------${NC}"

# Run create_ap in the background so the trap can catch signals
create_ap --no-virt --ieee80211n --ht_capab '[HT40-][SHORT-GI-20][SHORT-GI-40][DSSS_CCK-40]' -c "$CHANNEL" "$WIFI_INT" "$INTERNET_INT" "$SSID" "$PASSPHRASE" &
CREATE_AP_PID=$!

# Wait for create_ap to finish
wait "$CREATE_AP_PID"
