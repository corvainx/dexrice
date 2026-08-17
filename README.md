<div align="center">
<img src="screenshot.png" alt="Desktop preview" width="100%">

# dexrice

**A clean, minimal, keyboard-driven Hyprland setup for Arch Linux, powered by Noctalia.**

[![Made for](https://img.shields.io/badge/made%20for-Arch%20Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white)](https://archlinux.org)
[![WM](https://img.shields.io/badge/WM-Hyprland-89b4fa?style=for-the-badge)](https://hyprland.org)
[![Shell](https://img.shields.io/badge/Shell-Noctalia%20(v5%20beta)-f5c2e7?style=for-the-badge)](https://docs.noctalia.dev)

</div>

---

## Highlights

- **Desktop Shell**: Custom [Noctalia](https://docs.noctalia.dev) v5 layout, bar, quick settings, and Catppuccin color scheme.
- **Window Management**: Smooth scrolling/dwindle tiling layout with minimal gaps and soft rounded corners.
- **Default File Manager**: GNOME Nautilus (`nautilus`) with QuickLook preview (`sushi`), archive integration (`file-roller`), and custom sidebar bookmarks.
- **Terminal & Shell**: Kitty terminal with multiple built-in color themes (Catppuccin, Tokyo Night, Cyberdream, Oxocarbon), Fish shell, Starship prompt, and Fastfetch.
- **Hardware-Agnostic Display**: Hyprland auto-detects connected monitors out of the box.
- **Smart Browser Launcher**: Fallback launcher script checks for installed browsers in priority order (`Brave Origin` → `Helium` → `Brave` → `Zen Browser` → `Firefox` → `Vivaldi` → `LibreWolf`).
- **Audio Experience**: Native EasyEffects suite with optional Dolby Atmos PipeWire profile.
- **Automated Installer**: Robust, interactive setup wizard built on `minimaLinux` architecture with full `--dry-run` simulation support.

---

## Requirements

- **OS**: Arch Linux (or a clean Arch-based install).
- **User**: A non-root user with `sudo` privileges.
- **Network**: Working internet connection for downloading packages, Chaotic-AUR, and SDDM theme assets.

---

## Installation

Clone the repository and run the setup script:

```bash
git clone https://github.com/corvainx/dexrice.git
cd dexrice
sudo ./install.sh
```

### Preview First (Dry Run)

To preview the interactive wizard and inspect all commands that would be executed without modifying your system or requiring root privileges:

```bash
./install.sh --dry-run
```

> **Safe to Re-Run**: The installer automatically creates a timestamped backup of existing configs at `~/.config-backup/<timestamp>/` before copying any dotfiles.

---

## Interactive Setup Wizard

When you run `sudo ./install.sh`, the wizard interactively guides you through:

1. **Nvidia GPU Detection**: Automatically configures hardware cursors, VA-API decoding, and D-Bus environment daemons in `~/.config/hypr/startup.lua`.
2. **Display Manager (SDDM)**: Installs SDDM, pulls the `matugen-minimal` theme from [ilyamiro/imperative-dots](https://github.com/ilyamiro/imperative-dots), generates a Catppuccin Mocha `Colors.qml`, and sets Wayland display server defaults.
3. **Audio Stack**:
   - `EasyEffects (default)`: Installs EasyEffects + LSP plugins + Calf studio plugins.
   - `Dolby Atmos`: Installs EasyEffects and deploys the custom Dolby PipeWire profile.
   - `Skip`: Leaves audio settings untouched.
4. **Media Players**: Choose any combination of `mpv`, `vlc`, `deadbeef`, `rhythmbox`, `elisa`, `dragon`, `haruna`, or install all.
5. **Web Browser Selection**: Pick your preferred browser:
   - **Brave Origin** (`curl -fsS https://dl.brave.com/install.sh | FLAVOR=origin sh`)
   - **Helium** (`helium-browser-bin`)
   - **Brave** (`brave-bin`)
   - **Zen Browser** (`zen-browser-bin`)
   - **Firefox** (`firefox`)
   - **Vivaldi** (`vivaldi`)
   - **LibreWolf** (`librewolf`)
6. **Office Suite**: Option to install LibreOffice (`libreoffice-fresh`).
7. **Gaming Stack**: Pick from `steam`, `mangohud` (with `lib32-mangohud`), `protonplus`, `wine`, `winetricks`, `protontricks`, `lutris`, `heroic-games-launcher-bin`, `prismlauncher` (with `jdk21-openjdk`), `goverlay`, and `mangojuice`.
8. **Optional Applications**:
   - **VSCodium** (`vscodium-bin`): Automatically deploys `vscodium/settings.json` and installs all extensions from `vscodium/extensions.txt`.
   - **VS Code** (`visual-studio-code-bin`)
   - **Obsidian** (`obsidian`)
   - **OBS Studio** (`obs-studio` + `luajit`)
   - **Upscayl** (`upscayl-desktop-git`)
   - **Video Downloader** (`video-downloader`)
   - **Mission Center** (`mission-center`)
9. **Hardware Services**:
   - **Printer Support**: CUPS daemon, PDF printing, Gutenprint, and HP drivers.
   - **Bluetooth**: BlueZ stack, `blueman` manager, and systemd service.
   - **DDCutil**: DDC/CI monitor brightness control over I2C with udev rules and user group assignment.

---

## Keybindings Reference

The desktop is keyboard-driven with `SUPER` (Windows key) as the main modifier:

### Applications
| Keybind | Action | Command |
| :--- | :--- | :--- |
| `SUPER + RETURN` | Terminal | `kitty` |
| `SUPER + E` | File Manager | `nautilus --new-window` |
| `SUPER + C` | Code Editor | `codium` |
| `SUPER + B` | Web Browser | `browser-launcher.sh` |
| `SUPER + D` | Application Launcher | `noctalia msg panel-toggle launcher` |
| `SUPER + T` | Settings Panel | `noctalia msg settings-toggle` |
| `SUPER + L` | Screen Lock | `noctalia msg screen-lock` |
| `SUPER + S` | Steam | `steam` |
| `SUPER + V` | Video Player | `mpv` (pseudo-gui) |
| `SUPER + ESC` | Session Menu | `noctalia msg panel-toggle session` |

### Window Management
| Keybind | Action |
| :--- | :--- |
| `SUPER + Q` | Close focused window |
| `SUPER + W` | Toggle floating mode |
| `SUPER + F` | Toggle fullscreen |
| `SUPER + Arrow` | Move focus (Left / Right / Up / Down) |
| `SUPER + SHIFT + Arrow` | Resize active window |
| `SUPER + CTRL + SHIFT + Arrow` | Move / Swap window |
| `ALT + TAB` | Cycle through windows |
| `SUPER + Left Mouse Drag` | Move floating window |
| `SUPER + Right Mouse Drag` | Resize window |

### Workspaces
| Keybind | Action |
| :--- | :--- |
| `SUPER + 1..9` | Switch to workspace 1–9 |
| `SUPER + SHIFT + 1..9` | Move focused window to workspace 1–9 |
| `SUPER + CTRL + Right / Left` | Next / Previous workspace |
| `SUPER + CTRL + Down` | Open empty workspace |
| `SUPER + Scroll Wheel` | Cycle through workspaces |

### Screenshots
| Keybind | Action | Tool |
| :--- | :--- | :--- |
| `SUPER + PRINT` | Capture active window | `hyprshot` |
| `SHIFT + PRINT` | Capture selected region | `hyprshot` |
| `ALT + PRINT` | Capture entire monitor | `hyprshot` |
| `SUPER + A` | Interactive screenshot & annotate | `grim` + `slurp` + `satty` |

### Media & Hardware
| Keybind | Action |
| :--- | :--- |
| `XF86AudioPlay` / `Next` / `Prev` | Play / Pause / Next / Prev track (`playerctl`) |
| `XF86AudioRaiseVolume` / `LowerVolume` | Adjust volume $\pm 5\%$ (`pamixer`) |
| `XF86AudioMute` | Toggle audio mute (`pamixer`) |
| `XF86MonBrightnessUp` / `Down` | Adjust screen brightness $\pm 5\%$ (`brightnessctl`) |

---

## Customization

### Testing the SDDM Theme
If you installed the SDDM display manager and `matugen-minimal` theme, you can test the greeter UI without logging out:

```bash
sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/matugen-minimal
```

### Wallpaper Selection
All the wallpapers in `backgrounds/` are deployed to `~/Pictures/backgrounds/`. You can change wallpapers directly via Noctalia's built-in wallpaper selector or control center.

---

## Post-Installation

After the script finishes, choose `y` to reboot (or reboot manually):

```bash
reboot
```

Log in via SDDM into your new Hyprland + Noctalia desktop session.