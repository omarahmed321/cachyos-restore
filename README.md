# CachyOS + Hyprland Complete System Replicator & Restorer

This repository contains an automated setup script designed to replicate and restore a highly customized, gorgeous **CachyOS + Hyprland + HyDE** desktop environment in a single execution.

It was created and verified to run flawlessly on Arch Linux / CachyOS bases.

---

## 🚀 Quick Start (Replicate on Any Device)

To deploy your complete setup onto a fresh installation, you can run it either as a combined **one-liner command** or by executing the steps individually.

### Option 1: The Automated One-Liner (Recommended)
Copy and paste this single command into your terminal to clone, enter, and execute the restorer automatically:
```bash
git clone https://github.com/omarahmed321/cachyos-restore.git && cd cachyos-restore && chmod +x restore_my_setup.sh && ./restore_my_setup.sh
```

### Option 2: Run directly via `curl` (No manual cloning required)
Since the restoration script is fully self-contained, you can execute it directly from the cloud without even cloning the repository manually:
```bash
curl -sSL https://raw.githubusercontent.com/omarahmed321/cachyos-restore/main/restore_my_setup.sh | bash
```

### Option 3: Step-by-Step Execution
If you prefer running each step individually:
```bash
# 1. Clone the repository
git clone https://github.com/omarahmed321/cachyos-restore.git

# 2. Enter the repository directory
cd cachyos-restore

# 3. Make the script executable
chmod +x restore_my_setup.sh

# 4. Run the replicator script
./restore_my_setup.sh
```

---

## 🛠️ What this config actually does

The `restore_my_setup.sh` script automates the entire installation and configuration pipeline:

- **Core & AUR Preparation**: Checks for an AUR helper (`yay`/`paru`), installs `yay` if missing, and ensures basic system utilities (`git`, `zsh`) are installed.
- **Dynamic Kernel Headers Installation**: Automatically detects the running kernel (`uname -r`) and installs the matching headers package (e.g. `linux-cachyos-headers` or `linux-lts-headers`), which is required for compiling out-of-tree kernel modules.
- **Automated Package Deployment**: Verifies and installs **45+ system, font, and GUI packages** (including `hyprland`, `waybar`, `dunst`, `rofi-wayland`, `sddm`, `kitty`, `firefox`, `visual-studio-code-bin`, `dolphin`, `antigravity`, `antigravity-ide`, `prismlauncher`, etc.).
- **VS Code Settings & Extensions Restoration**: Deploys your custom editor settings (`settings.json`) and automatically installs all your active VS Code extensions (Tailwind CSS, animations, Gruvbox theme, Prettier, etc.) automatically.
- **Self-Sufficient Fallback Installer**: Uses a batch installation method with an automatic individual package installer fallback loop to prevent minor package or AUR failures from crashing the setup.
- **Dynamic Monitor & G-Sync Setup**: Automatically queries monitor layouts, native resolutions, and maximum refresh rates; configures the highest refresh rate monitor as the primary display, rotates the secondary monitor to portrait on the left, and configures G-Sync/VRR.
- **Interactive Mouse Offset Calibration**: Launches an interactive Zenity calibration loop at the end of the script, allowing the user to shift and align the monitors in rea- **Custom Keyboard Layout**: Integrates a custom Arabic layout variant (`thal_bksl` on the standard `ara` layout) mapping the letter `ذ` to the backslash key, allowing quick `Alt+Shift` toggles between US and Arabic layouts.
- **Antigravity Keyring & Token Persistence**: Configures Electron keyring flags (`--password-store=gnome-libsecret`) and unmasks `gnome-keyring-daemon` services to securely persist login tokens on reboot.
- **Nvidia & Firefox Stability Fix**: Writes custom registry configuration tweaks (`PowerMizerDefaultAC=0x3`) to stop Firefox crash/stutter loops between P0 and P8 GPU states.
- **SDDM Login Screen (Candy Theme)**: Installs the SDDM Candy theme, configures Qt5 graphical effects, centers login prompts, and dynamically syncs the background image with the active desktop wallpaper.
- **Wi-Fi Hotspot Wrapper**: Installs `create_ap` and copies a helper script (`start_hotspot.sh`) to quickly spawn local hotspots, automatically disabling Wi-Fi power-save via `iw` for maximum stability.
- **Zsh & Fastfetch Customization**: Configures Oh My Zsh, Powerlevel10k, zsh autocomplete/syntax plugins, and displays a custom Braille anime mascot fastfetch logo.
- **Automated Wi-Fi Driver Patching**: Detects `/usr/src/8188eu-*` driver source directories and automatically executes `patch_driver.py` to fix compilation issues on kernels 6.1+, followed by rebuilding/reinstalling via DKMS.
- **HyDE Framework Setup**: Clones the official `hyprdots` (HyDE) framework, automated using pre-seeded inputs to skip standard installation prompt timers.

---

## 📂 Repository File Structure & Descriptions

When you clone this repository, you will find the following files. Here is what each file does:

| File | Description |
| :--- | :--- |
| **[`restore_my_setup.sh`](file:///home/omar/cachyosconfigupdate/restore_my_setup.sh)** | **The main installer & configuration script.** It handles core packages installation, kernel headers installation, SDDM Candy theme setup, HyDE configuration, monitor layout calculation, VS Code settings sync, keyboard layout, and driver building. |
| **[`patch_driver.py`](file:///home/omar/cachyosconfigupdate/patch_driver.py)** | **The Wi-Fi driver patcher.** A Python script that automatically modifies the out-of-tree RTL8188EUS (`8188eu`) wireless driver source files (Makefiles, header inclusions, and modern Timer APIs) so that the driver successfully compiles and loads on 6.x/7.x kernels under modern compilers (Clang/GCC). |
| **[`start_hotspot.sh`](file:///home/omar/cachyosconfigupdate/start_hotspot.sh)** | **Hotspot activation utility.** Spawns a Wi-Fi hotspot on the Realtek `wlan0` interface using `create_ap`, automatically disabling wireless power-saving via `iw` for maximum link stability and bandwidth. |
| **[`double-pageup.sh`](file:///home/omar/cachyosconfigupdate/double-pageup.sh)** | **Key-binding helper script.** Runs in the background to capture double-taps of the Page_Up key, using `wtype` to simulate pressing `Ctrl + \`` (used to toggle the integrated terminal on and off). |
| **[`ara-custom`](file:///home/omar/cachyosconfigupdate/ara-custom)** | **Custom keyboard layout reference.** Custom XKB layout symbol map reference that maps the Arabic letter `ذ` (Thal) to the backslash (`\`) key, allowing natural Arabic typing. |
| **[`ioctl_cfg80211_patched.c`](file:///home/omar/cachyosconfigupdate/ioctl_cfg80211_patched.c)** | **Patched source reference.** A reference backup file containing the patched version of the driver's wireless configuration interfaces (`ioctl_cfg80211.c`). |
| **[`README.md`](file:///home/omar/cachyosconfigupdate/README.md)** | **Documentation.** The setup guide and description file you are reading right now. |
