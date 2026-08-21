# Declarative NixOS + Home Manager + labwc Configuration

A modular, reproducible, and performance-oriented **NixOS** and **Home Manager** configuration using **Nix Flakes**.

This setup features **[labwc](https://github.com/labwc/labwc)** (a lightweight Wayland stacking compositor inspired by Openbox) paired with **[Waybar](https://github.com/Alexays/Waybar)**, **[Wofi](https://hg.sr.ht/~scoopta/wofi)**, **[SwayNC](https://github.com/ErikReider/SwayNotificationCenter)**, **[Hyprlock](https://github.com/hyprwm/hyprlock)**, **[Hypridle](https://github.com/hyprwm/hypridle)**, **Flameshot**, and **Incus** virtualization. It is heavily tuned for **Gaming (Steam, GameMode, MangoHud)**, **NVIDIA DRM/EGL acceleration**, **21:9 Ultrawide displays**, and **Bluetooth AirPods Pro telemetry with MPRIS controls**.

---

## 📸 Key Features & Architecture Highlights

- **Compositor (labwc):** Ultra-fast, minimal memory footprint wlroots-based stacking Wayland compositor with native VRR (Variable Refresh Rate / Adaptive Sync) for tear-free gaming.
- **21:9 Ultrawide Support:** Dedicated centered region (`center-ultrawide`, 60% screen width) toggled with `Super + 0` to center apps comfortably on ultrawide monitors without stretching across 21:9.
- **Custom Waybar (Bottom Bar):**
  - **NixOS Launcher Button:** Centered `` icon triggering Wofi application launcher.
  - **Dynamic CPU Metrics (`group/cpu-pill`):** Two-digit percentage usage with temperature and an interactive tooltip listing the **Top 5 CPU-consuming processes** in real-time (`cpu-usage.py`).
  - **NVIDIA GPU Monitor (`custom/gpu-temp`):** Real-time GPU utilization and temperature querying `nvidia-smi`.
  - **AirPods Pro D-Bus Telemetry (`custom/airpods`):** Live independent battery percentages for left earbud, right earbud, and charging case with charging indicators (⚡) via Apple Accessory Protocol (AAP) over BlueZ Profile1 L2CAP.
  - **SwayNC Notification Center:** Transient notifications, DND mode, and history drawer.
  - **NixOS Update Notifier (`custom/updates`):** Waybar indicator that checks every 30 minutes whether a newer NixOS revision is available on the channel. Compares the locally installed git revision (`nixos-version --revision`) against the latest published revision at `channels.nixos.org`. Displays a `󰚰` icon when an update is available — **click it** to open an interactive terminal (`foot`) that runs `nix flake update && nixos-rebuild switch` and restarts Waybar automatically on success.
  - **Audio & Media (MPRIS Proxy):** PipeWire/WirePlumber integration with AirPods Pro stem click media control translation.
- **Floating GTK Exit Menu:** Centered card-style power menu (`Super + Escape`) for power off, reboot, suspend, logout, and screen lock.
- **Right-Click Desktop Context Menu:** Full Openbox-style context menu (`menu.xml`) with categorized submenus — see [Desktop Context Menu](#%EF%B8%8F-desktop-context-menu-right-click) section.
- **Gaming Ready:** Out-of-the-box Steam configuration, Feral Interactive `gamemode`, and MangoHud HUD metrics.
- **Vim Editor:** Configured with a curated plugin set including NERDTree, fzf-vim, vim-fugitive, vim-gitgutter, vim-floaterm, UltiSnips, and Gruvbox theme. Ansible snippets included via a custom plugin fetched from GitHub.
- **Reproducible Nix Flakes:** Pinned packages and Home Manager modules on NixOS 26.05.

---

## 📁 Repository Structure

```text
nixos-config/
├── flake.nix                  # Flake entrypoint & system output declarations
├── flake.lock                 # Pinned dependencies (nixpkgs, home-manager)
├── configuration.nix          # System-level configuration (NixOS)
├── hardware-configuration.nix # Kernel modules, file systems, disk UUIDs
├── garbage-collector.nix      # Automated Nix store GC and deduplication
├── nvidia.nix                 # NVIDIA proprietary drivers & power management
├── steam.nix                  # Steam, GameMode, and MangoHud configuration
├── .gitignore                 # Git ignore rules
├── home/                      # Home Manager user configurations
│   ├── user.nix               # User profile module
│   ├── root.nix               # Root user profile module
│   └── modules/               # Modular Home Manager configurations
│       ├── bash.nix            # Bash shell configuration
│       ├── starship.nix        # Starship prompt integration
│       ├── starship.toml       # Starship theme definition
│       ├── packages.nix        # User CLI packages
│       ├── vim.nix             # Vim editor configuration and plugins
│       ├── vimrc               # Detailed Vim runtime configuration
│       ├── labwc.nix           # labwc, Waybar, Wofi, SwayNC & tool wrappers
│       └── labwc/              # Modular labwc & desktop environment configs
│           ├── rc.xml          # Keybindings, 21:9 regions, VRR, window snapping
│           ├── menu.xml        # Context menu (right click on desktop)
│           ├── autostart       # Startup script (waybar, swaybg, hypridle, etc.)
│           ├── environment     # Wayland & NVIDIA environment variables
│           ├── waybar-config.json # Waybar modules layout and configuration
│           ├── waybar-style.css   # Waybar visual theme & styling
│           ├── wofi-config        # Application launcher settings
│           ├── wofi-style.css     # Wofi CSS theme
│           ├── flameshot.ini      # Flameshot screenshot settings (Grim backend)
│           ├── foot.ini        # Foot terminal emulator theme & font config
│           ├── swaync-config.json # SwayNC notification daemon config
│           ├── swaync-style.css   # SwayNC styling
│           ├── hyprlock.conf   # Lock screen styling and widgets
│           ├── hypridle.conf   # Inactivity and idle management
│           └── scripts/        # Helper scripts
│               ├── airpods.py        # D-Bus/AAP battery monitor for AirPods
│               ├── check-updates.sh  # NixOS update checker & interactive upgrader
│               ├── cpu-usage.py      # Real-time CPU & Top 5 processes calculator
│               ├── exit-menu.sh      # Centered power & exit menu
│               ├── exit-menu-config # Wofi settings for exit menu
│               ├── exit-menu-style.css # CSS styling for exit menu
│               ├── keybindings-help.sh # Interactive keyboard shortcuts helper (YAD)
│               └── nixos-admin-help.sh # NixOS & Flakes administration guide (YAD)
└── README.md                  # Project documentation
```

---

## 🚀 Installation & Deployment

### 1. Clone the Repository

```bash
git clone https://github.com/YOUR_USERNAME/nixos-config.git ~/nixos-config
cd ~/nixos-config
```

### 2. Generate Hardware Configuration

Generate the `hardware-configuration.nix` tailored for your machine's drives and hardware:

```bash
nixos-generate-config --show-hardware-config > hardware-configuration.nix
```

### 3. Customize System Settings

- **Username & Account:**
  In [`configuration.nix`](configuration.nix), adjust the username from `user` to your desired username under `users.users.<name>` and `home-manager.users.<name>`.
- **Hostname:**
  Update `networking.hostName = "nixos";` in [`configuration.nix`](configuration.nix).
- **Timezone & Locale:**
  Set `time.timeZone` (e.g., `"America/New_York"`, `"Europe/London"`, `"UTC"`) and `i18n.defaultLocale`.
- **Keyboard Layout:**
  In [`configuration.nix`](configuration.nix), [`home/modules/labwc/environment`](home/modules/labwc/environment), and [`home/modules/labwc/rc.xml`](home/modules/labwc/rc.xml), adjust `layout` (e.g. `us`, `es`, `de`, `fr`).
- **Display Output & Refresh Rate (Kanshi):**
  In [`home/modules/labwc.nix`](home/modules/labwc.nix), adjust the `criteria`, `mode`, and `scale` under `services.kanshi.settings` to match your monitor:

  ```nix
  outputs = [{
    criteria = "DP-3";            # ← Your display output name (see below)
    mode = "1920x1080@60Hz";      # ← Your resolution and refresh rate
    position = "0,0";
    scale = 1.0;
  }];
  ```

  To find your display output name and supported modes, run either of these commands after logging in:

  ```bash
  # Option 1: via wlr-randr (Wayland)
  wlr-randr

  # Option 2: via kanshi itself (shows available outputs and modes)
  kanshi --config /dev/null
  ```

  Common output names: `DP-1`, `DP-2`, `DP-3`, `HDMI-A-1`, `eDP-1` (laptop internal display).
  The refresh rate in the mode string must match exactly one of the values listed by `wlr-randr`.


### 4. Build and Switch

To apply the configuration using Nix Flakes:

```bash
sudo nixos-rebuild switch --flake .#nixos
```

---

## ⌨️ Keybindings Reference (`labwc`)

| Category | Keybinding | Action |
|---|---|---|
| **Applications** | `Super + Space` | Toggle application launcher (Wofi) |
| **Applications** | `Super + T` | Open terminal (`foot`) |
| **Applications** | `Super + W` | Open web browser (`brave` / default browser) |
| **Applications** | `Super + E` | Open file manager (`thunar`) |
| **Applications** | `Super + A` | Open code editor (`antigravity-ide`) |
| **Window Control** | `Super + Q` | Close active window |
| **Window Control** | `Super + F` | Toggle fullscreen |
| **Window Control** | `Super + M` / `Super + 5` | Toggle maximize |
| **Window Control** | `Super + 0` | Center window for **21:9 Ultrawide** displays (60% width) |
| **Window Control** | `Super + N` | Minimize window |
| **Window Control** | `Super + D` | Toggle window decorations |
| **Window Control** | `Super + Left / Right` | Snap window to left / right half |
| **Window Control** | `Alt + Tab` | Switch to next window |
| **Window Control** | `Alt + Shift + Tab` | Switch to previous window |
| **Workspaces** | `Super + 1..4` | Switch to workspace 1–4 |
| **Workspaces** | `Super + Shift + 1..4` | Move active window to workspace 1–4 |
| **System & Power** | `Super + Escape` | Open centered exit / power menu (`exit-menu.sh`) |
| **System & Power** | `Super + L` | Lock screen (`hyprlock`) |
| **System & Power** | `Super + V` | Clipboard history manager (`cliphist` + `wofi`) |
| **System & Power** | `Print` / `Super + Shift + S` | Interactive screenshot tool (`flameshot gui`) |
| **System & Power** | `Super + Shift + R` | Reload labwc configuration |
| **Help** | `Super + F1` | Open interactive keyboard shortcuts helper (`keybindings-help.sh`) |
| **Recovery** | `Ctrl + Alt + Backspace` | Force terminate graphical session ($\rightarrow$ SDDM) |
| **Recovery** | `Alt + SysRq + K` | Linux Kernel SAK: Kill hung VT / frozen session |

---

## 🖱️ Desktop Context Menu (Right Click)

Right-clicking on the desktop opens a categorized Openbox-style context menu (`menu.xml`):

| Entry | Action |
|---|---|
| 🔍 **Search Applications** | Open Wofi application launcher |
| 📷 **Screenshot (Flameshot)** | Open Flameshot GUI |
| 💻 **Terminal** | Open `foot` terminal |
| 🌐 **Web Browser** | Open `brave` |
| 📁 **File Manager** | Open `thunar` |
| 🎮 **Gaming** → Steam | Launch Steam |
| 🎮 **Gaming** → GameMode Status | Check `gamemoded` status in terminal |
| 🎮 **Gaming** → MangoHud Config | Edit MangoHud configuration in terminal |
| 📦 **Incus** → List Instances | List running containers/VMs |
| 📦 **Incus** → Resource Monitor | Run `incus top` |
| 📦 **Incus** → Web UI | Open Incus Web UI at `https://127.0.0.1:8443` |
| 🔧 **Preferences** → Audio / Network / Bluetooth / Display | Open respective GUI tools |
| 🔧 **Preferences** → Appearance (nwg-look) | GTK theme & icon configurator |
| 🔧 **Preferences** → Window Settings (obconf-qt) | labwc/Openbox theme configurator |
| 🔧 **Preferences** → Edit rc.xml / menu.xml / autostart | Edit config files in terminal |
| 📊 **System** → 📖 NixOS Administration Manual | Open `nixos-admin-help.sh` YAD dialog |
| 📊 **System** → ⌨️ Keyboard Shortcuts | Open keybindings help dialog |
| 📊 **System** → Process Monitor (btop) | Launch `btop` |
| 📊 **System** → System Info | Run `fastfetch` |
| 📊 **System** → Disk Usage | Show `df -h` and `lsblk` |
| 🔒 **Lock Screen** | Run `hyprlock` |
| 🔄 **Reload labwc** | Reload compositor configuration |
| ⏻ **Exit** | Log out, Reboot, Power Off, or Suspend |

---

## 📖 NixOS Administration Manual

The script [`nixos-admin-help.sh`](home/modules/labwc/scripts/nixos-admin-help.sh) opens a searchable **YAD table dialog** with the most common NixOS and Flakes administration commands organized by category:

| Category | Examples |
|---|---|
| 🔄 Rebuild & Deploy | `nixos-rebuild switch`, `test`, `boot`, `--rollback`, `dry-build`, `--flake` |
| ❄️ Flakes & Environments | `nix flake update/check/metadata`, `nix-shell`, `nix shell`, `nix run` |
| 🧹 Maintenance & Clean | `nix-collect-garbage`, `nix-store --optimise`, delete old generations |
| 📊 Generations & History | `nixos-rebuild list-generations`, `home-manager generations`, `nix store diff-closures` |
| 🔍 Diagnostics & Logs | `systemctl status`, `journalctl`, `nixos-version --json`, `nix log` |

Access it via: **Right-click desktop → 📊 System → 📖 NixOS Administration Manual**

---

## 🔄 NixOS Update Notifier

The script [`check-updates.sh`](home/modules/labwc/scripts/check-updates.sh) powers the `custom/updates` Waybar module:

- **How it works:** Every **30 minutes**, it fetches the latest published git revision from `https://channels.nixos.org/<channel>/git-revision` and compares it against the locally installed revision reported by `nixos-version --revision`.
- **Channel auto-detection:** Reads the active channel from `nix-channel --list`. Falls back to `nixos-26.05` if no channel is configured (Flakes-only setups).
- **Waybar indicator:** Shows a `󰚰` icon with a tooltip showing installed vs. available revision when an update is available. Hidden when the system is up to date or offline.
- **One-click upgrade:** Clicking the icon opens a `foot` terminal titled **"NixOS Upgrade"** that interactively asks for confirmation, then runs:
  - **Flakes:** `nix flake update && nixos-rebuild switch --flake /etc/nixos#nixos`
  - **Channels:** `nix-channel --update && nixos-rebuild switch`
  - On success, Waybar is automatically restarted.

---

## 🛠️ Useful Administration Commands

| Task | Command |
|---|---|
| **Rebuild System** | `sudo nixos-rebuild switch --flake .#nixos` |
| **Test Rebuild (In Memory)** | `sudo nixos-rebuild test --flake .#nixos` |
| **Rollback to Previous State** | `sudo nixos-rebuild switch --rollback` |
| **Update Flake Inputs** | `nix flake update` |
| **Run Garbage Collection** | `sudo nix-collect-garbage -d && nix-collect-garbage -d` |
| **Deduplicate Nix Store** | `sudo nix-store --optimise` |
| **List System Generations** | `nixos-rebuild list-generations` |
| **Check System Errors** | `journalctl -b -p err` |

---

## 📄 License & Credits

- [labwc](https://github.com/labwc/labwc) — Lightweight stacking Wayland compositor.
- [waybar-airpods-module](https://github.com/Silverquark/waybar-airpods-module) by Silverquark & [Bluetooth-Battery-Meter](https://github.com/maniacx/Bluetooth-Battery-Meter) by maniacx for Apple Accessory Protocol reverse engineering.
- Distributed under the MIT License.
