<div align="center">
<img src="screenshot.png" alt="Desktop preview" width="100%">

# dexrice

**A clean, minimal Hyprland setup for Arch Linux, powered by Noctalia.**

[![Made for](https://img.shields.io/badge/made%20for-Arch%20Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white)](https://archlinux.org)
[![WM](https://img.shields.io/badge/WM-Hyprland-89b4fa?style=for-the-badge)](https://hyprland.org)
[![Shell](https://img.shields.io/badge/Shell-Noctalia%20v5.0.0-f5c2e7?style=for-the-badge)](https://docs.noctalia.dev)

</div>

---

## About

These are my personal dotfiles for a minimal, keyboard-driven Hyprland desktop on Arch Linux.

**Highlights**

- Scrolling-tiling layout, minimal gaps, soft rounded corners
- Custom Noctalia (v5.0.0) bar layout, control center, and color scheme
- Several kitty themes included (Catppuccin, Tokyo Night, Cyberdream, Oxocarbon)
- Hardware-agnostic monitor config: Hyprland auto-detects your display, no editing required
- Fallback launcher scripts (e.g. browser picker checks for Brave → Firefox → Zen → Vivaldi → LibreWolf, whichever is installed)

## Requirements

- Arch Linux (or an Arch-based distro with `pacman`)
- A non-root user with `sudo` access
- Internet connection (setup.sh clones the SDDM theme repo)

> **A fresh install is recommended.** I built and use this on top of [minimaLinux](https://github.com/Echilonvibin/minimaLinux), a bare Hyprland starter with no extra bloat. Starting from that base (or an equally clean Hyprland install) avoids conflicts with whatever bar, shell, or configs a non-fresh system already has in place.

## Installation

This assumes Hyprland, Noctalia, and everything else are already installed. The script copies the dotfiles into `~/.config` as real files, and also installs/enables SDDM with a matugen-minimal theme.

```bash
git clone https://github.com/corvainx/dexrice.git
cd dexrice
./setup.sh
```

Must be run **from inside the cloned repo**, since it resolves paths relative to its own location.

Preview what it'll do first, without changing anything:

```bash
./setup.sh --dry-run
```

Skip the SDDM install/theme step entirely:

```bash
./setup.sh --no-sddm
```

Safe to re-run. It backs up anything it'd overwrite to `~/.config-backup/<timestamp>/` first.

## Display Manager (SDDM)

By default, `setup.sh` also:

- Installs and enables **SDDM** as your display manager
- Pulls the **matugen-minimal** theme (sparse-checked out from [ilyamiro/imperative-dots](https://github.com/ilyamiro/imperative-dots)) into `/usr/share/sddm/themes/matugen-minimal`
- Applies a Catppuccin Mocha color palette via a generated `Colors.qml`
- Writes `/etc/sddm.conf.d/10-wayland-matugen.conf` to set the theme active and force Wayland

Requires sudo and a working internet connection (clones the theme repo). Test the theme independently with:

```bash
sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/matugen-minimal
```

Pass `--no-sddm` to skip this step if you already run a different display manager or theme.

## Notes

- `hypr/keybinds.lua` binds the editor key to VS Codium (`codium`) by default. Change the `$EDITOR` variable if you use something else.
- `fish/config.fish` includes a few personal project aliases (`cdv`, `cdf`, `cdn`, `cdp`, `cdb`, `agy`, `vel`) pointing at my own repos. Harmless if unused, feel free to delete them.
- SDDM install/theme setup can be skipped with `--no-sddm`.
- After installing, log out and back into Hyprland (or reboot) to pick everything up.