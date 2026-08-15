#!/usr/bin/env bash

# Usage:
#   ./setup.sh              # copy configs from this repo into ~/.config (real files, no symlinks)
#                            # + install/enable SDDM + apply matugen-minimal SDDM theme
#   ./setup.sh --dry-run    # print what would happen, change nothing
#   ./setup.sh --no-sddm    # skip SDDM install + theme step entirely

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"
BACKUP_DIR="$HOME/.config-backup/$(date +%Y%m%d-%H%M%S)"
DRY_RUN=false
SKIP_SDDM=false

THEME_NAME="matugen-minimal"
THEME_REPO_URL="https://github.com/ilyamiro/imperative-dots.git"
THEME_DEST="/usr/share/sddm/themes/${THEME_NAME}"

for arg in "$@"; do
  case "$arg" in
  --dry-run) DRY_RUN=true ;;
  --no-sddm) SKIP_SDDM=true ;;
  *)
    echo "Unknown option: $arg" >&2
    exit 1
    ;;
  esac
done

run() {
  if $DRY_RUN; then
    echo "  [dry-run] $*"
  else
    "$@"
  fi
}

declare -A LINK_MAP=(
  [hypr]="$CONFIG_DIR/hypr"
  [kitty]="$CONFIG_DIR/kitty"
  [fish]="$CONFIG_DIR/fish"
  [fastfetch]="$CONFIG_DIR/fastfetch"
  [nvim]="$CONFIG_DIR/nvim"
  [noctalia]="$CONFIG_DIR/noctalia"
  [vesktop]="$CONFIG_DIR/vesktop"
)

backup_existing() {
  local dest="$1"
  run mkdir -p "$BACKUP_DIR"
  run mv "$dest" "$BACKUP_DIR/$(basename "$dest")"
  if ! $DRY_RUN; then
    echo "  backed up: $dest -> $BACKUP_DIR/$(basename "$dest")"
  fi
}

materialize() {
  local src="$1" dest="$2"

  if [[ -e "$dest" || -L "$dest" ]]; then
    backup_existing "$dest"
  fi

  run mkdir -p "$(dirname "$dest")"
  run cp -a "$src" "$dest"
  if ! $DRY_RUN; then
    echo "  copied: $src -> $dest"
  fi
}

# ------------------------------------------------------------------
# 1. Dotfiles
# ------------------------------------------------------------------
for name in "${!LINK_MAP[@]}"; do
  materialize "$REPO_DIR/$name" "${LINK_MAP[$name]}"
done

run mkdir -p "$HOME/.local/share/icons"
materialize "$REPO_DIR/icons/macOS" "$HOME/.local/share/icons/macOS"

materialize "$REPO_DIR/starship.toml" "$CONFIG_DIR/starship.toml"

# ------------------------------------------------------------------
# 2. Base packages
# ------------------------------------------------------------------
run sudo pacman -S --needed pamixer brightnessctl xdg-desktop-portal-hyprland
run yay -S --needed ttf-jetbrains-mono-nerd
run sudo usermod -aG video "$USER"

# ------------------------------------------------------------------
# 3. SDDM install + matugen-minimal theme
# ------------------------------------------------------------------
if ! $SKIP_SDDM; then
  echo -e "\n\033[36m[*] Installing SDDM...\033[0m"
  run sudo pacman -S --needed sddm
  run sudo systemctl enable sddm

  echo -e "\033[36m[*] Fetching SDDM theme (${THEME_NAME})...\033[0m"
  if $DRY_RUN; then
    echo "  [dry-run] clone ${THEME_REPO_URL} theme dir, install to ${THEME_DEST}, write config"
  else
    TMP_DIR="$(mktemp -d)"
    git clone --depth 1 --filter=blob:none --sparse "$THEME_REPO_URL" "$TMP_DIR" >/dev/null 2>&1
    git -C "$TMP_DIR" sparse-checkout set ".config/sddm/themes/${THEME_NAME}" >/dev/null 2>&1

    SRC_DIR="$TMP_DIR/.config/sddm/themes/${THEME_NAME}"
    if [ ! -d "$SRC_DIR" ]; then
      echo "  [!] Theme folder not found in repo. Skipping theme install." >&2
      rm -rf "$TMP_DIR"
    else
      sudo mkdir -p "$THEME_DEST"
      sudo cp -r "$SRC_DIR/"* "$THEME_DEST/"

      sudo tee "$THEME_DEST/Colors.qml" >/dev/null <<'EOF'
pragma Singleton
import QtQuick
QtObject {
    readonly property color base: "#1e1e2e"
    readonly property color crust: "#11111b"
    readonly property color mantle: "#181825"
    readonly property color text: "#cdd6f4"
    readonly property color subtext0: "#a6adc8"
    readonly property color surface0: "#313244"
    readonly property color surface1: "#45475a"
    readonly property color surface2: "#585b70"
    readonly property color mauve: "#cba6f7"
    readonly property color red: "#f38ba8"
    readonly property color peach: "#fab387"
    readonly property color blue: "#89b4fa"
    readonly property color green: "#a6e3a1"
}
EOF
      sudo chown "$USER:$USER" "$THEME_DEST/Colors.qml"

      sudo mkdir -p /etc/sddm.conf.d
      cat <<EOF | sudo tee /etc/sddm.conf.d/10-wayland-matugen.conf >/dev/null
[Theme]
Current=${THEME_NAME}

[General]
DisplayServer=wayland
GreeterEnvironment=QT_WAYLAND_DISABLE_WINDOWDECORATION=1
EOF
      rm -rf "$TMP_DIR"
      echo "  -> Theme installed and set active."
      echo "     Test with: sddm-greeter-qt6 --test-mode --theme ${THEME_DEST}"
    fi
  fi
else
  echo -e "\n\033[33m[!] Skipping SDDM install/theme step (--no-sddm passed).\033[0m"
fi

echo -e "\n\033[32mSetup complete. Log out and back into your session (or reboot) for all changes to take effect.\033[0m"
materialize "$REPO_DIR/starship.toml" "$CONFIG_DIR/starship.toml"

run sudo pacman -S --needed pamixer brightnessctl xdg-desktop-portal-hyprland
run yay -S --needed ttf-jetbrains-mono-nerd
run sudo usermod -aG video "$USER"

echo -e "\033[32mSetup complete. Log out and back into your session (or reboot) for all changes to take effect.\033[0m"
