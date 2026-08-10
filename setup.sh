#!/usr/bin/env bash

# Usage:
#   ./setup.sh              # copy configs from this repo into ~/.config (real files, no symlinks)
#   ./setup.sh --dry-run    # print what would happen, change nothing

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"
BACKUP_DIR="$HOME/.config-backup/$(date +%Y%m%d-%H%M%S)"
DRY_RUN=false

for arg in "$@"; do
  case "$arg" in
  --dry-run) DRY_RUN=true ;;
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

for name in "${!LINK_MAP[@]}"; do
  materialize "$REPO_DIR/$name" "${LINK_MAP[$name]}"
done

run mkdir -p "$HOME/.local/share/icons"
materialize "$REPO_DIR/icons/macOS" "$HOME/.local/share/icons/macOS"

materialize "$REPO_DIR/starship.toml" "$CONFIG_DIR/starship.toml"

run sudo pacman -S --needed pamixer brightnessctl xdg-desktop-portal-hyprland
run sudo usermod -aG video "$USER"

echo -e "\033[32mSetup complete. Log out and back into your session (or reboot) for all changes to take effect.\033[0m"
