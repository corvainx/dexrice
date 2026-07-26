#!/usr/bin/env bash
#
# Usage:
#   ./setup.sh              # link everything
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

backup_and_link() {
  local src="$1" dest="$2"

  if [[ -L "$dest" && "$(readlink -f "$dest")" == "$(readlink -f "$src")" ]]; then
    echo "  already linked: $dest"
    return
  fi

  if [[ -e "$dest" || -L "$dest" ]]; then
    run mkdir -p "$BACKUP_DIR"
    run mv "$dest" "$BACKUP_DIR/$(basename "$dest")"
    echo "  backed up: $dest -> $BACKUP_DIR/$(basename "$dest")"
  fi

  run mkdir -p "$(dirname "$dest")"
  run ln -sfn "$src" "$dest"
  echo "  linked: $dest -> $src"
}

for name in "${!LINK_MAP[@]}"; do
  backup_and_link "$REPO_DIR/$name" "${LINK_MAP[$name]}"
done

run mkdir -p "$HOME/.local/share/icons"
backup_and_link "$REPO_DIR/icons/macOS" "$HOME/.local/share/icons/macOS"

backup_and_link "$REPO_DIR/starship.toml" "$CONFIG_DIR/starship.toml"

echo -e "\033[32mSetup complete. Log out and back into your session (or reboot) for all changes to take effect.\033[0m"
