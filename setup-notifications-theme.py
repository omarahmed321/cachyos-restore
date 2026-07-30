#!/usr/bin/env python3
# =============================================================================
#   Dunst Notification Theme & Appearance Customizer
#   Part of: CachyOS + HyDE System Restorer
#   Repo:    https://github.com/omarahmed321/cachyos-restore
# =============================================================================

import os
import sys
import subprocess
import tkinter as tk
from tkinter import ttk, messagebox

DUNST_CONF = os.path.expanduser("~/.config/dunst/dunstrc")

THEMES = {
    "1. 💎 Glassmorphism Floating": """[global]
    monitor = 0
    follow = mouse
    width = (280, 380)
    height = (80, 160)
    origin = top-right
    offset = 20x50
    scale = 0
    notification_limit = 5
    progress_bar = true
    progress_bar_height = 8
    progress_bar_min_width = 150
    progress_bar_max_width = 300
    indicate_consecutive_notifications = true
    transparency = 20
    separator_height = 2
    padding = 12
    horizontal_padding = 16
    text_icon_padding = 12
    frame_width = 2
    frame_color = "#83a598"
    gap_size = 8
    separator_color = frame
    sort = yes
    font = JetBrains Mono 10
    corner_radius = 12
    background = "#1d2021"
    foreground = "#ebdbb2"

[urgency_low]
    background = "#282828"
    foreground = "#a89984"
    frame_color = "#504945"

[urgency_normal]
    background = "#1d2021"
    foreground = "#ebdbb2"
    frame_color = "#83a598"

[urgency_critical]
    background = "#3c3836"
    foreground = "#fb4934"
    frame_color = "#fb4934"
""",

    "2. 📜 Gruvbox Retro Dark": """[global]
    monitor = 0
    follow = mouse
    width = 320
    height = 140
    origin = top-right
    offset = 15x45
    padding = 10
    horizontal_padding = 12
    frame_width = 2
    frame_color = "#fabd2f"
    font = JetBrains Mono 10
    corner_radius = 6
    background = "#282828"
    foreground = "#ebdbb2"

[urgency_low]
    background = "#282828"
    foreground = "#928374"
    frame_color = "#665c54"

[urgency_normal]
    background = "#282828"
    foreground = "#ebdbb2"
    frame_color = "#fabd2f"

[urgency_critical]
    background = "#282828"
    foreground = "#fb4934"
    frame_color = "#cc241d"
""",

    "3. 💜 Cyberpunk Neon": """[global]
    monitor = 0
    follow = mouse
    width = 350
    height = 150
    origin = top-right
    offset = 20x50
    padding = 14
    horizontal_padding = 18
    frame_width = 2
    frame_color = "#d3869b"
    font = JetBrains Mono 10
    corner_radius = 10
    background = "#1d2021"
    foreground = "#b8bb26"

[urgency_low]
    background = "#1d2021"
    foreground = "#8ec07c"
    frame_color = "#458588"

[urgency_normal]
    background = "#1d2021"
    foreground = "#b8bb26"
    frame_color = "#d3869b"

[urgency_critical]
    background = "#1d2021"
    foreground = "#fb4934"
    frame_color = "#fe8019"
""",

    "4. 💊 Minimalist Floating Pill": """[global]
    monitor = 0
    follow = mouse
    width = (240, 320)
    height = (60, 120)
    origin = top-center
    offset = 0x30
    padding = 10
    horizontal_padding = 16
    frame_width = 1
    frame_color = "#d5c4a1"
    font = JetBrains Mono 9
    corner_radius = 18
    background = "#3c3836"
    foreground = "#fbf1c7"

[urgency_low]
    background = "#3c3836"
    foreground = "#a89984"
    frame_color = "#665c54"

[urgency_normal]
    background = "#3c3836"
    foreground = "#fbf1c7"
    frame_color = "#83a598"

[urgency_critical]
    background = "#504945"
    foreground = "#fb4934"
    frame_color = "#fb4934"
"""
}

def apply_dunst_theme(theme_name):
    if theme_name not in THEMES:
        return False
    try:
        os.makedirs(os.path.dirname(DUNST_CONF), exist_ok=True)
        with open(DUNST_CONF, 'w') as f:
            f.write(THEMES[theme_name])
            
        # Restart Dunst daemon
        subprocess.run(["pkill", "dunst"], capture_output=True)
        subprocess.Popen(["dunst"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        
        # Send test notification
        subprocess.run(["notify-send", "-u", "normal", "Theme Applied!", f"Notification theme set to: {theme_name}"])
        return True
    except Exception as e:
        messagebox.showerror("Error", f"Failed to apply Dunst theme: {e}")
        return False

class DunstThemeApp(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("Notification Theme Customizer")
        self.geometry("520x420")
        self.configure(bg='#272727')
        
        self.selected_theme = tk.StringVar(value=list(THEMES.keys())[0])
        
        self.setup_styles()
        self.build_ui()
        
    def setup_styles(self):
        style = ttk.Style()
        style.theme_use('clam')
        style.configure('.', background='#272727', foreground='#ebdbb2', font=('JetBrains Mono', 10))
        style.configure('TLabel', background='#272727', foreground='#ebdbb2')
        style.configure('TRadiobutton', background='#3c3836', foreground='#ebdbb2', font=('JetBrains Mono', 10))
        style.configure('TButton', background='#3c3836', foreground='#ebdbb2', padding=[10, 5])
        style.map('TButton', background=[('active', '#504945')])

    def build_ui(self):
        ttk.Label(self, text="🔔 Notification Theme Customizer", font=('JetBrains Mono', 13, 'bold'), foreground='#d3869b').pack(pady=(15, 5))
        ttk.Label(self, text="Choose a theme style for Dunst popup notifications:", font=('JetBrains Mono', 9), foreground='#a89984').pack(pady=(0, 15))
        
        frame = ttk.Frame(self)
        frame.pack(fill='both', expand=True, padx=20, pady=10)
        
        for name in THEMES.keys():
            rb = ttk.Radiobutton(frame, text=f"  {name}", value=name, variable=self.selected_theme)
            rb.pack(fill='x', pady=8, padx=5, ipady=6)
            
        btn_frame = ttk.Frame(self)
        btn_frame.pack(fill='x', side='bottom', padx=20, pady=15)
        
        ttk.Button(btn_frame, text="Close", command=self.destroy).pack(side='left')
        ttk.Button(btn_frame, text="Apply Theme & Test Notification", command=self.save).pack(side='right')

    def save(self):
        theme = self.selected_theme.get()
        if apply_dunst_theme(theme):
            messagebox.showinfo("Success", f"Applied '{theme}' notification theme successfully!")

if __name__ == "__main__":
    if not os.environ.get('WAYLAND_DISPLAY') and not os.environ.get('DISPLAY'):
        print("Error: Display environment not found.")
        sys.exit(1)
    app = DunstThemeApp()
    app.mainloop()
