#!/usr/bin/env bash
#
# Usage:
#   ./setup.sh              # copy configs from this repo into ~/.config (real files, no symlinks)
#   ./setup.sh --dry-run    # print what would happen, change nothing
#   ./setup.sh --sync-back  # copy your live ~/.config files back into this repo,
#                           # so you can `git add`/`git commit` your latest configs

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"
BACKUP_DIR="$HOME/.config-backup/$(date +%Y%m%d-%H%M%S)"
DRY_RUN=false
SYNC_BACK=false

for arg in "$@"; do
  case "$arg" in
  --dry-run) DRY_RUN=true ;;
  --sync-back) SYNC_BACK=true ;;
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
  echo "  backed up: $dest -> $BACKUP_DIR/$(basename "$dest")"
}

materialize() {
  local src="$1" dest="$2"

  if [[ -L "$dest" ]]; then
    local target
    target="$(readlink -f "$dest")"

    if [[ -e "$target" ]]; then
      echo "  migrating symlink: $dest (was -> $target)"
      run cp -aL "$target" "$dest.dexrice-tmp"
      run rm "$dest"
      run mv "$dest.dexrice-tmp" "$dest"
      echo "  now a real copy: $dest"
    else
      echo "  broken symlink at $dest, restoring from repo"
      run rm "$dest"
      run mkdir -p "$(dirname "$dest")"
      run cp -a "$src" "$dest"
      echo "  copied: $src -> $dest"
    fi
    return
  fi

  if [[ -e "$dest" ]]; then
    echo "  already a real file/dir, leaving as-is: $dest"
    return
  fi

  run mkdir -p "$(dirname "$dest")"
  run cp -a "$src" "$dest"
  echo "  copied: $src -> $dest"
}

# Copy the live ~/.config item back into the repo, for git tracking.
sync_back_one() {
  local src="$1" dest="$2"

  if [[ -L "$dest" ]]; then
    echo "  skipping $dest (still a symlink - run setup.sh first to migrate it)"
    return
  fi

  if [[ ! -e "$dest" ]]; then
    echo "  skipping $dest (does not exist)"
    return
  fi

  if [[ -e "$src" || -L "$src" ]]; then
    run rm -rf "$src"
  fi

  run cp -a "$dest" "$src"
  echo "  synced: $dest -> $src"
}

if $SYNC_BACK; then
  echo "Syncing live configs from $CONFIG_DIR back into $REPO_DIR ..."
  for name in "${!LINK_MAP[@]}"; do
    sync_back_one "$REPO_DIR/$name" "${LINK_MAP[$name]}"
  done
  sync_back_one "$REPO_DIR/icons/macOS" "$HOME/.local/share/icons/macOS"
  sync_back_one "$REPO_DIR/starship.toml" "$CONFIG_DIR/starship.toml"
  echo -e "\033[32mSync complete. Review the changes with 'git status' / 'git diff' in $REPO_DIR, then commit.\033[0m"
  exit 0
fi

for name in "${!LINK_MAP[@]}"; do
  materialize "$REPO_DIR/$name" "${LINK_MAP[$name]}"
done

run mkdir -p "$HOME/.local/share/icons"
materialize "$REPO_DIR/icons/macOS" "$HOME/.local/share/icons/macOS"

materialize "$REPO_DIR/starship.toml" "$CONFIG_DIR/starship.toml"

echo -e "\033[32mSetup complete. Log out and back into your session (or reboot) for all changes to take effect.\033[0m"
