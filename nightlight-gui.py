#!/usr/bin/env python3
# =============================================================================
#   Night Light & Brightness GUI Panel (Hyprland / hyprsunset)
#   Part of: CachyOS + HyDE System Restorer
#   Repo:    https://github.com/omarahmed321/cachyos-restore
# =============================================================================

import gi
import subprocess
import os
import re
import sys
import threading

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Gtk, Adw, GLib, Gdk, Gio

HYPRLAND_CONF = os.path.expanduser("~/.config/hypr/hyprland.conf")
CONFIG_FILE   = os.path.expanduser("~/.config/hypr/nightlight.conf")

# --- Temperature / Percentage Helpers ---
# 0% warmth = 6500K (Daylight)
# 100% warmth = 1000K (Max Warmth)
def pct_to_temp(pct):
    pct = max(0, min(100, pct))
    return int(6500 - (pct / 100.0) * 5500)

def temp_to_pct(temp):
    temp = max(1000, min(6500, temp))
    return int(round(((6500 - temp) / 5500.0) * 100))

# --- Backend Config Functions ---
def _load_conf():
    t, g, en = 3500, 100, True
    if os.path.exists(CONFIG_FILE):
        try:
            with open(CONFIG_FILE, "r") as f:
                c = f.read()
            m_t = re.search(r"^\s*ENABLE_NIGHTLIGHT=(\d+)", c, re.M)
            m_g = re.search(r"^\s*HYPRSUNSET_GAMMA=(\d+)", c, re.M)
            m_e = re.search(r"^\s*HYPRSUNSET_ENABLED=(true|false)", c, re.M)
            if m_t: t = int(m_t.group(1))
            if m_g: g = int(m_g.group(1))
            if m_e: en = (m_e.group(1) == "true")
        except Exception:
            pass
    return t, g, en

def _save_conf(t, g, en):
    os.makedirs(os.path.dirname(CONFIG_FILE), exist_ok=True)
    with open(CONFIG_FILE, "w") as f:
        f.write(f"""# Night Light Configuration
ENABLE_NIGHTLIGHT={t}
HYPRSUNSET_GAMMA={g}
HYPRSUNSET_ENABLED={'true' if en else 'false'}
""")

def _apply_live(t, g, en):
    if not en:
        subprocess.run(["killall", "-q", "hyprsunset"], check=False)
        return

    g_val = max(0.1, min(1.0, g / 100.0))
    g_str = f"{g_val:.2f}"
    cmd = ["hyprsunset", "-t", str(t)]
    if g < 100:
        cmd.extend(["-g", g_str])

    subprocess.run(["killall", "-q", "hyprsunset"], check=False)
    try:
        subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception as e:
        print(f"[!] Failed to run hyprsunset: {e}")

def _patch_hyprland(t, en):
    if not os.path.exists(HYPRLAND_CONF):
        return
    try:
        with open(HYPRLAND_CONF, "r") as f:
            lines = f.readlines()
        exec_line = "exec-once = python3 ~/.config/hypr/nightlight-start.sh\n"
        has_exec = any("nightlight-start.sh" in l for l in lines)
        if not has_exec:
            lines.append("\n# Auto-start Night Light\n" + exec_line)
            with open(HYPRLAND_CONF, "w") as f:
                f.writelines(lines)
    except Exception:
        pass

# --- Clean & Modern UI Window ---
CSS = """
window { background-color: transparent; }

.main-card {
    background: alpha(@window_bg_color, 0.95);
    border-radius: 20px;
    border: 1px solid alpha(@window_fg_color, 0.1);
    padding: 24px;
    box-shadow: 0 10px 30px rgba(0, 0, 0, 0.4);
}

.title-label {
    font-size: 17px;
    font-weight: 800;
}

.slider-label {
    font-size: 13px;
    font-weight: 700;
    margin-top: 10px;
}

.val-badge {
    font-size: 15px;
    font-weight: 800;
    color: @accent_color;
}

scale trough {
    border-radius: 8px;
    min-height: 12px;
}
"""

class NightLightApp(Adw.Application):
    def __init__(self):
        super().__init__(application_id="org.cachyos.nightlight")
        self.connect("activate", self.on_activate)

    def on_activate(self, app):
        p = Gtk.CssProvider()
        p.load_from_data(CSS.encode())
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(), p, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

        win = Adw.ApplicationWindow(application=app, title="Night Light & Brightness")
        win.set_default_size(380, 280)

        t, g, en = _load_conf()
        self._t = t
        self._g = g
        self._en = en
        self._timer = None

        card = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        card.add_css_class("main-card")

        # Header Row with Switch Toggle
        header = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        title = Gtk.Label(label="🌙 Night Light & Brightness")
        title.add_css_class("title-label")
        title.set_hexpand(True)
        title.set_halign(Gtk.Align.START)
        header.append(title)

        self.toggle = Gtk.Switch()
        self.toggle.set_active(self._en)
        self.toggle.connect("state-set", self._on_toggle)
        header.append(self.toggle)
        card.append(header)

        # Divider
        card.append(Gtk.Separator(orientation=Gtk.Orientation.HORIZONTAL))

        # Slider 1: Night Light Warmth (Percentage 0% - 100%)
        row_nl = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        lbl_nl = Gtk.Label(label="Night Light Warmth")
        lbl_nl.add_css_class("slider-label")
        lbl_nl.set_hexpand(True)
        lbl_nl.set_halign(Gtk.Align.START)
        row_nl.append(lbl_nl)

        self.val_nl = Gtk.Label(label=f"{temp_to_pct(self._t)}%")
        self.val_nl.add_css_class("val-badge")
        row_nl.append(self.val_nl)
        card.append(row_nl)

        self.scale_nl = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, 0, 100, 1)
        self.scale_nl.set_value(temp_to_pct(self._t))
        self.scale_nl.connect("value-changed", self._on_temp_pct_changed)
        card.append(self.scale_nl)

        # Slider 2: Brightness (Percentage 10% - 100%)
        row_br = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        lbl_br = Gtk.Label(label="Brightness")
        lbl_br.add_css_class("slider-label")
        lbl_br.set_hexpand(True)
        lbl_br.set_halign(Gtk.Align.START)
        row_br.append(lbl_br)

        self.val_br = Gtk.Label(label=f"{self._g}%")
        self.val_br.add_css_class("val-badge")
        row_br.append(self.val_br)
        card.append(row_br)

        self.scale_br = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, 10, 100, 1)
        self.scale_br.set_value(self._g)
        self.scale_br.connect("value-changed", self._on_gamma_changed)
        card.append(self.scale_br)

        # Action Save Button
        save_btn = Gtk.Button(label="💾 Save Settings")
        save_btn.add_css_class("suggested-action")
        save_btn.set_margin_top(8)
        save_btn.connect("clicked", self._on_save)
        card.append(save_btn)

        self.status_lbl = Gtk.Label(label="")
        self.status_lbl.set_margin_top(4)
        card.append(self.status_lbl)

        win.set_content(card)
        win.present()

    def _on_toggle(self, sw, state):
        self._en = state
        self.scale_nl.set_sensitive(state)
        self.scale_br.set_sensitive(state)
        self._debounce()

    def _on_temp_pct_changed(self, sc):
        pct = int(sc.get_value())
        self.val_nl.set_label(f"{pct}%")
        self._t = pct_to_temp(pct)
        self._debounce()

    def _on_gamma_changed(self, sc):
        pct = int(sc.get_value())
        self.val_br.set_label(f"{pct}%")
        self._g = pct
        self._debounce()

    def _debounce(self):
        if self._timer:
            GLib.source_remove(self._timer)
        self._timer = GLib.timeout_add(300, self._do_apply)

    def _do_apply(self):
        self._timer = None
        threading.Thread(target=_apply_live, args=(self._t, self._g, self._en), daemon=True).start()
        return False

    def _on_save(self, b):
        def _do():
            _save_conf(self._t, self._g, self._en)
            _patch_hyprland(self._t, self._en)
            GLib.idle_add(self._show_status, "✓ Saved successfully!")
        threading.Thread(target=_do, daemon=True).start()

    def _show_status(self, msg):
        self.status_lbl.set_label(msg)
        GLib.timeout_add_seconds(3, lambda: self.status_lbl.set_label("") or False)

if __name__ == "__main__":
    app = NightLightApp()
    app.run(None)
