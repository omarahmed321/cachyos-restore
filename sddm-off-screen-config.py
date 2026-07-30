#!/usr/bin/env python3
# =============================================================================
#   SDDM Screen Disabler & Visibility Manager
#   Part of: CachyOS + HyDE System Restorer
#   Repo:    https://github.com/omarahmed321/cachyos-restore
# =============================================================================

import os
import sys
import re
import subprocess
import tkinter as tk
from tkinter import ttk, messagebox

SDDM_CONF_DIR = "/etc/sddm.conf.d"
DISABLED_MON_FILE = "/etc/sddm.conf.d/disabled_monitors"

def get_monitors_info():
    monitors = {}
    try:
        output = subprocess.check_output(['hyprctl', 'monitors'], text=True)
        chunks = output.split('Monitor ')[1:]
        for chunk in chunks:
            lines = chunk.strip().split('\n')
            if not lines:
                continue
            match_name = re.match(r'^(\S+)\s+\(ID', lines[0])
            if not match_name:
                continue
            name = match_name.group(1)
            
            info = {
                'name': name,
                'model': 'Unknown',
                'resolution': 'Unknown',
                'refresh_rate': 'Unknown'
            }
            
            if len(lines) > 1:
                match_mode = re.search(r'(\d+x\d+)@(\d+(?:\.\d+)?)\s+at\s+(\d+x\d+)', lines[1])
                if match_mode:
                    info['resolution'] = match_mode.group(1)
                    info['refresh_rate'] = f"{float(match_mode.group(2)):.2f} Hz"
            
            for line in lines:
                line_str = line.strip()
                if line_str.startswith('model:'):
                    info['model'] = line_str.split('model:')[1].strip()
                    
            monitors[name] = info
    except Exception:
        try:
            output = subprocess.check_output(['xrandr'], text=True)
            for line in output.splitlines():
                if ' connected' in line:
                    parts = line.split()
                    name = parts[0]
                    monitors[name] = {
                        'name': name,
                        'model': 'Connected Display',
                        'resolution': 'Default',
                        'refresh_rate': '60 Hz'
                    }
        except Exception:
            pass
            
    return monitors

def get_currently_disabled():
    disabled = set()
    if os.path.exists(DISABLED_MON_FILE):
        try:
            with open(DISABLED_MON_FILE, 'r') as f:
                for line in f:
                    m = line.strip()
                    if m:
                        disabled.add(m)
        except Exception:
            pass
    return disabled

def apply_disabled_monitors(disabled_list):
    try:
        tmp_target = "/tmp/disabled_monitors"
        tmp_xsetup = "/tmp/Xsetup"
        with open(tmp_target, 'w') as f:
            for mon in disabled_list:
                f.write(mon + '\n')

        xsetup_content = """#!/bin/sh
# Xsetup - run as root before the login dialog appears

CONNECTED_MONITORS=$(xrandr | grep " connected" | awk '{print $1}')
MONITOR_COUNT=$(echo "$CONNECTED_MONITORS" | wc -l)
if [ "$MONITOR_COUNT" -gt 1 ]; then
    TARGET_MON=$(cat /etc/sddm.conf.d/target_monitor 2>/dev/null | tr -d '[:space:]')
    DISABLED_MONS=$(cat /etc/sddm.conf.d/disabled_monitors 2>/dev/null)

    PRIMARY_MONITOR=""
    if [ -n "$TARGET_MON" ] && echo "$CONNECTED_MONITORS" | grep -qx "$TARGET_MON"; then
        PRIMARY_MONITOR="$TARGET_MON"
    fi

    if [ -z "$PRIMARY_MONITOR" ]; then
        PRIMARY_MONITOR=$(echo "$CONNECTED_MONITORS" | head -n 1)
    fi

    if [ -n "$PRIMARY_MONITOR" ]; then
        XRANDR_CMD="xrandr --output $PRIMARY_MONITOR --auto --primary"
        for mon in $CONNECTED_MONITORS; do
            if [ "$mon" != "$PRIMARY_MONITOR" ]; then
                if echo "$DISABLED_MONS" | grep -qx "$mon"; then
                    XRANDR_CMD="$XRANDR_CMD --output $mon --off"
                else
                    XRANDR_CMD="$XRANDR_CMD --output $mon --auto --right-of $PRIMARY_MONITOR"
                fi
            fi
        done
        eval "$XRANDR_CMD"
    fi
fi

# Mouse sensitivity
for id in $(xinput list --id-only 2>/dev/null); do
    xinput set-prop "$id" "libinput Accel Profile Enabled" 0 1 0 2>/dev/null || true
    xinput set-prop "$id" "libinput Accel Speed" -0.5 2>/dev/null || true
done
"""
        with open(tmp_xsetup, 'w') as f:
            f.write(xsetup_content)

        cmd = f"sudo mkdir -p {SDDM_CONF_DIR} /usr/share/sddm/scripts && sudo cp {tmp_target} {DISABLED_MON_FILE} && sudo cp {tmp_xsetup} /usr/share/sddm/scripts/Xsetup && sudo chmod 644 {DISABLED_MON_FILE} && sudo chmod +x /usr/share/sddm/scripts/Xsetup"
        res = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        if res.returncode != 0:
            subprocess.run(f"pkexec bash -c '{cmd}'", shell=True, check=True)
            
        return True
    except Exception as e:
        messagebox.showerror("Error", f"Failed to save disabled screens configuration: {e}")
        return False

class SDDMDisablerApp(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("SDDM Screen Disabler Manager")
        self.geometry("540x480")
        self.configure(bg='#272727')
        
        self.monitors = get_monitors_info()
        self.disabled_set = get_currently_disabled()
        self.checkbox_vars = {}
        
        self.setup_styles()
        self.build_ui()
        
    def setup_styles(self):
        style = ttk.Style()
        style.theme_use('clam')
        style.configure('.', background='#272727', foreground='#ebdbb2', font=('JetBrains Mono', 10))
        style.configure('TLabel', background='#272727', foreground='#ebdbb2')
        style.configure('TLabelframe', background='#272727', foreground='#fabd2f')
        style.configure('TLabelframe.Label', background='#272727', foreground='#fabd2f', font=('JetBrains Mono', 10, 'bold'))
        style.configure('TCheckbutton', background='#3c3836', foreground='#ebdbb2', font=('JetBrains Mono', 10))
        style.configure('TButton', background='#3c3836', foreground='#ebdbb2', padding=[10, 5])
        style.map('TButton', background=[('active', '#504945')])

    def build_ui(self):
        header = ttk.Label(self, text="🚫 SDDM Screen Visibility & Disabler", font=('JetBrains Mono', 13, 'bold'), foreground='#fb4934')
        header.pack(pady=(15, 5))
        
        sub = ttk.Label(self, text="Check screens where SDDM should be TURNED OFF during login:", font=('JetBrains Mono', 9), foreground='#a89984')
        sub.pack(pady=(0, 15))
        
        container = ttk.Frame(self)
        container.pack(fill='both', expand=True, padx=20, pady=10)
        
        if not self.monitors:
            ttk.Label(container, text="No monitors detected via hyprctl/xrandr.", foreground='#fb4934').pack()
            return
            
        for name, info in self.monitors.items():
            lf = ttk.LabelFrame(container, text=f" Screen: {name} ")
            lf.pack(fill='x', pady=8, padx=5)
            
            var = tk.BooleanVar(value=(name in self.disabled_set))
            self.checkbox_vars[name] = var
            
            cb = ttk.Checkbutton(lf, text=f"Turn OFF SDDM on {name} during login screen", variable=var)
            cb.pack(anchor='w', padx=10, pady=5)
            
            props = f"• Model: {info['model']}\n• Resolution: {info['resolution']} @ {info['refresh_rate']}"
            ttk.Label(lf, text=props, justify='left', foreground='#bdae93').pack(anchor='w', padx=25, pady=(0, 8))
            
        btn_frame = ttk.Frame(self)
        btn_frame.pack(fill='x', side='bottom', padx=20, pady=15)
        
        ttk.Button(btn_frame, text="Close", command=self.destroy).pack(side='left')
        ttk.Button(btn_frame, text="Save SDDM Visibility Settings", command=self.save).pack(side='right')

    def save(self):
        disabled_list = [mon for mon, var in self.checkbox_vars.items() if var.get()]
        if apply_disabled_monitors(disabled_list):
            msg = f"SDDM screen visibility settings updated successfully!\n\n"
            if disabled_list:
                msg += f"Turned OFF during SDDM login: {', '.join(disabled_list)}"
            else:
                msg += "SDDM will display on all connected screens."
            messagebox.showinfo("Success", msg)

if __name__ == "__main__":
    if len(sys.argv) > 2 and sys.argv[1] == "--disable":
        mon_to_disable = sys.argv[2:]
        if apply_disabled_monitors(mon_to_disable):
            print(f"Disabled SDDM on: {', '.join(mon_to_disable)}")
        sys.exit(0)

    if not os.environ.get('WAYLAND_DISPLAY') and not os.environ.get('DISPLAY'):
        print("Error: No display environment found.")
        sys.exit(1)
    app = SDDMDisablerApp()
    app.mainloop()
