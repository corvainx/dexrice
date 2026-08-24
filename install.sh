#!/bin/bash

export LC_MESSAGES=C
export LANG=C

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_DIR="$SCRIPT_DIR"

DRY_RUN=false
for arg in "$@"; do
  case "$arg" in
  --dry-run)
    DRY_RUN=true
    ;;
  --help | -h)
    echo "Usage:"
    echo "  sudo ./install.sh          # Full interactive installation"
    echo "  ./install.sh --dry-run     # Preview actions without changing system"
    exit 0
    ;;
  *)
    echo "Unknown option: $arg"
    echo "Run ./install.sh --help for usage."
    exit 1
    ;;
  esac
done

if [ "$DRY_RUN" = false ]; then
  if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root (use sudo ./install.sh)." >&2
    echo "Tip: Run './install.sh --dry-run' to simulate without root privileges." >&2
    exit 1
  fi

  if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
    ACTUAL_USER="$SUDO_USER"
  else
    ACTUAL_USER=$(logname 2>/dev/null || id -un)
  fi

  if [ -z "$ACTUAL_USER" ] || [ "$ACTUAL_USER" = "root" ]; then
    echo "ERROR: Could not determine a non-root target user. Run this script with sudo from your normal user account." >&2
    exit 1
  fi

  ACTUAL_USER_HOME=$(getent passwd "$ACTUAL_USER" | cut -d: -f6)
  if [ -z "$ACTUAL_USER_HOME" ] || [ ! -d "$ACTUAL_USER_HOME" ]; then
    echo "ERROR: Could not determine home directory for user '$ACTUAL_USER'." >&2
    exit 1
  fi
else
  ACTUAL_USER="${SUDO_USER:-$(id -un)}"
  ACTUAL_USER_HOME="$HOME"
fi

TEMP_SUDOERS_FILE="/etc/sudoers.d/99-dexrice-installer-temp"
cleanup_sudoers() {
  if [ -f "$TEMP_SUDOERS_FILE" ]; then
    rm -f "$TEMP_SUDOERS_FILE"
  fi
}
trap cleanup_sudoers EXIT INT TERM HUP

if [ "$DRY_RUN" = false ] && [[ $EUID -eq 0 ]]; then
  mkdir -p /etc/sudoers.d
  echo "$ACTUAL_USER ALL=(ALL) NOPASSWD: ALL" >"$TEMP_SUDOERS_FILE"
  chmod 0440 "$TEMP_SUDOERS_FILE"
  if command -v visudo >/dev/null 2>&1 && ! visudo -c -f "$TEMP_SUDOERS_FILE" >/dev/null 2>&1; then
    rm -f "$TEMP_SUDOERS_FILE"
  fi
fi

CONFIG_DIR="$ACTUAL_USER_HOME/.config"
BACKUP_TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$ACTUAL_USER_HOME/.config-backup/$BACKUP_TIMESTAMP"

disable_colors() {
  unset ALL_OFF BOLD DIM BLUE GREEN RED YELLOW CYAN MAGENTA
  ALL_OFF="" BOLD="" DIM="" BLUE="" GREEN="" RED="" YELLOW="" CYAN="" MAGENTA=""
}

enable_colors() {
  if tput setaf 0 &>/dev/null; then
    ALL_OFF="$(tput sgr0)"
    BOLD="$(tput bold)"
    DIM="$(tput dim 2>/dev/null || echo '')"
    RED="${BOLD}$(tput setaf 1)"
    GREEN="${BOLD}$(tput setaf 2)"
    YELLOW="${BOLD}$(tput setaf 3)"
    BLUE="${BOLD}$(tput setaf 4)"
    MAGENTA="${BOLD}$(tput setaf 5)"
    CYAN="${BOLD}$(tput setaf 6)"
  else
    ALL_OFF="\e[0m"
    BOLD="\e[1m"
    DIM="\e[2m"
    RED="${BOLD}\e[31m"
    GREEN="${BOLD}\e[32m"
    YELLOW="${BOLD}\e[33m"
    BLUE="${BOLD}\e[34m"
    MAGENTA="${BOLD}\e[35m"
    CYAN="${BOLD}\e[36m"
  fi
}

if [[ -t 1 ]] || [[ -t 2 ]]; then
  enable_colors
else
  disable_colors
fi

msg() {
  printf "%b==>%b %b%s%b\n" "${GREEN}" "${ALL_OFF}" "${BOLD}" "$*" "${ALL_OFF}"
}

info() {
  printf "%b  ->%b %s\n" "${CYAN}" "${ALL_OFF}" "$*"
}

warn() {
  printf "%b  !%b %b%s%b\n" "${YELLOW}" "${ALL_OFF}" "${YELLOW}" "$*" "${ALL_OFF}"
}

error() {
  printf "%b  x%b %b%s%b\n" "${RED}" "${ALL_OFF}" "${RED}" "$*" "${ALL_OFF}" >&2
}

banner() {
  echo ""
  printf "%b      _                     _%b\n" "${MAGENTA}" "${ALL_OFF}"
  printf "%b     | |                   (_)%b\n" "${MAGENTA}" "${ALL_OFF}"
  printf "%b   __| | _____  ___ __ _  ___ ___%b\n" "${CYAN}" "${ALL_OFF}"
  printf "%b  / _\` |/ _ \ \/ / '__| |/ __/ _ \%b\n" "${CYAN}" "${ALL_OFF}"
  printf "%b | (_| |  __/>  <| |  | | (_|  __/%b\n" "${BLUE}" "${ALL_OFF}"
  printf "%b  \__,_|\___/_/\_\_|  |_|\___\___|%b\n" "${BLUE}" "${ALL_OFF}"
  echo ""
  printf "  %bArch%b . %bHyprland%b . %bNoctalia%b -- %bminimal dotfiles%b\n" \
    "${CYAN}" "${ALL_OFF}" "${GREEN}" "${ALL_OFF}" "${MAGENTA}" "${ALL_OFF}" "${YELLOW}" "${ALL_OFF}"
  echo "  ================================================================"
  echo ""
}

run_cmd() {
  if [ "$DRY_RUN" = true ]; then
    printf "%b  [dry-run]%b %s\n" "${DIM}${YELLOW}" "${ALL_OFF}" "$*"
    return 0
  else
    "$@"
  fi
}

as_user() {
  if [ "$DRY_RUN" = true ]; then
    printf "%b  [dry-run] (as %s)%b %s\n" "${DIM}${YELLOW}" "$ACTUAL_USER" "${ALL_OFF}" "$*"
    return 0
  fi

  if [[ $EUID -eq 0 ]]; then
    sudo -u "$ACTUAL_USER" "$@"
  else
    "$@"
  fi
}

append_unique_package() {
  local -n package_list="$1"
  local package="$2"
  local existing_package

  for existing_package in "${package_list[@]}"; do
    if [ "$existing_package" = "$package" ]; then
      return 0
    fi
  done

  package_list+=("$package")
}

banner

if pacman -Qq hyprland >/dev/null 2>&1 || pacman -Qq hyprland-git >/dev/null 2>&1 || command -v Hyprland >/dev/null 2>&1 || command -v hyprland >/dev/null 2>&1; then
  info "Verified: Hyprland is already installed."
else
  info "Hyprland is not installed. It will be installed automatically via pacman."
fi

if [ "$DRY_RUN" = true ]; then
  warn "Running in DRY-RUN mode. No changes will be made to your system."
fi

echo "This script will install custom dotfiles for Hyprland, Noctalia, and the Chaotic AUR on Arch Linux."
while true; do
  read -r -p "Would you like to proceed? (y/n): " proceed
  case "$proceed" in
  y | Y | yes | YES)
    msg "Proceeding with installation..."
    break
    ;;
  n | N | no | NO)
    echo "Installation aborted. Have a nice day!"
    exit 0
    ;;
  *)
    echo "Please answer 'y' or 'n'."
    ;;
  esac
done

INSTALL_NVIDIA_OPTIONAL=0
while true; do
  echo ""
  read -r -p "Are you using an Nvidia GPU? (y/n): " nvidia_choice
  case "$nvidia_choice" in
  y | Y | yes | YES)
    INSTALL_NVIDIA_OPTIONAL=1
    info "Nvidia-specific Hyprland options will be enabled."
    break
    ;;
  n | N | no | NO)
    INSTALL_NVIDIA_OPTIONAL=0
    info "Skipping Nvidia-specific Hyprland options."
    break
    ;;
  *)
    echo "Please answer 'y' or 'n'."
    ;;
  esac
done

INSTALL_SDDM=1
while true; do
  echo ""
  read -r -p "Do you want to install SDDM and apply the matugen-minimal theme? (y/n): " sddm_choice
  case "$sddm_choice" in
  y | Y | yes | YES | "")
    INSTALL_SDDM=1
    info "SDDM and matugen-minimal theme will be configured."
    break
    ;;
  n | N | no | NO)
    INSTALL_SDDM=0
    info "Skipping SDDM display manager installation."
    break
    ;;
  *)
    echo "Please answer 'y' or 'n'."
    ;;
  esac
done

AUDIO_MODE="easyeffects"
while true; do
  echo ""
  echo "Audio setup options:"
  echo "  0. Skip EasyEffects and Dolby setup"
  echo "  1. EasyEffects (default)"
  echo "  2. Dolby Atmos PipeWire profile"
  read -r -p "Choose audio option (0-2) [1]: " audio_choice
  case "$audio_choice" in
  0)
    AUDIO_MODE="none"
    info "Skipping EasyEffects and Dolby setup."
    break
    ;;
  1 | "")
    AUDIO_MODE="easyeffects"
    info "Using EasyEffects audio setup."
    break
    ;;
  2)
    AUDIO_MODE="dolby"
    info "Dolby Atmos PipeWire profile will be applied."
    break
    ;;
  *)
    echo "Please enter 0, 1, or 2."
    ;;
  esac
done

AUDIO_VIDEO_PACKAGES=()
while true; do
  echo ""
  echo "Audio/Video Players (select one or more):"
  echo "  1. mpv (lightweight video player)"
  echo "  2. vlc (versatile media player)"
  echo "  3. dragon (simple KDE video player)"
  echo "  4. haruna (modern KDE video player)"
  echo "  5. deadbeef (modular audio player)"
  echo "  6. rhythmbox (GNOME music player)"
  echo "  7. elisa (lightweight KDE music player)"
  echo "  a. Install all audio/video players"
  echo "  0. Skip audio/video player installation"
  read -r -p "Enter your choices (e.g. 1,2 or 1 2, or a for all) [0]: " av_choices

  if [ "$av_choices" = "0" ] || [ -z "$av_choices" ]; then
    info "Skipping audio/video players."
    AUDIO_VIDEO_PACKAGES=()
    break
  fi

  if [[ "$av_choices" =~ ^[aA]$ ]]; then
    av_choices="1 2 3 4 5 6 7"
  fi

  av_choices=$(echo "$av_choices" | tr ',' ' ')
  AUDIO_VIDEO_PACKAGES=()
  invalid_choice=false

  for choice in $av_choices; do
    case "$choice" in
    1) append_unique_package AUDIO_VIDEO_PACKAGES mpv ;;
    2) append_unique_package AUDIO_VIDEO_PACKAGES vlc ;;
    3) append_unique_package AUDIO_VIDEO_PACKAGES dragon ;;
    4) append_unique_package AUDIO_VIDEO_PACKAGES haruna ;;
    5) append_unique_package AUDIO_VIDEO_PACKAGES deadbeef ;;
    6) append_unique_package AUDIO_VIDEO_PACKAGES rhythmbox ;;
    7) append_unique_package AUDIO_VIDEO_PACKAGES elisa ;;
    *)
      echo "Invalid choice: $choice"
      invalid_choice=true
      ;;
    esac
  done

  if [ "$invalid_choice" = false ]; then
    info "Selected audio/video players: ${AUDIO_VIDEO_PACKAGES[*]}"
    break
  fi
done

SELECTED_BROWSERS=()
while true; do
  echo ""
  echo "Web Browsers (select one or more):"
  echo "  1. Brave Origin"
  echo "  2. Helium"
  echo "  3. Brave"
  echo "  4. Zen Browser"
  echo "  5. Firefox"
  echo "  6. Vivaldi"
  echo "  7. LibreWolf"
  echo "  a. Install all web browsers"
  echo "  0. Skip web browser installation"
  read -r -p "Enter your choices (e.g. 1,5 or 1 5, or a for all) [0]: " b_choices

  if [ "$b_choices" = "0" ] || [ -z "$b_choices" ]; then
    info "Skipping web browser installation."
    SELECTED_BROWSERS=()
    break
  fi

  if [[ "$b_choices" =~ ^[aA]$ ]]; then
    b_choices="1 2 3 4 5 6 7"
  fi

  b_choices=$(echo "$b_choices" | tr ',' ' ')
  SELECTED_BROWSERS=()
  invalid_choice=false

  for choice in $b_choices; do
    case "$choice" in
    1) append_unique_package SELECTED_BROWSERS brave-origin ;;
    2) append_unique_package SELECTED_BROWSERS helium ;;
    3) append_unique_package SELECTED_BROWSERS brave ;;
    4) append_unique_package SELECTED_BROWSERS zen-browser ;;
    5) append_unique_package SELECTED_BROWSERS firefox ;;
    6) append_unique_package SELECTED_BROWSERS vivaldi ;;
    7) append_unique_package SELECTED_BROWSERS librewolf ;;
    *)
      echo "Invalid choice: $choice"
      invalid_choice=true
      ;;
    esac
  done

  if [ "$invalid_choice" = false ]; then
    info "Selected web browsers: ${SELECTED_BROWSERS[*]}"
    break
  fi
done

INSTALL_LIBREOFFICE=0
while true; do
  echo ""
  read -r -p "Do you want to install LibreOffice? (y/n) [n]: " lo_choice
  case "$lo_choice" in
  y | Y | yes | YES)
    INSTALL_LIBREOFFICE=1
    info "LibreOffice will be installed."
    break
    ;;
  n | N | no | NO | "")
    INSTALL_LIBREOFFICE=0
    info "Skipping LibreOffice installation."
    break
    ;;
  *)
    echo "Please answer 'y' or 'n'."
    ;;
  esac
done

GAMING_SELECTED_PACKAGES=()
while true; do
  echo ""
  echo "Gaming Packages (select one or more):"
  echo "  1. steam"
  echo "  2. mangohud"
  echo "  3. protonplus"
  echo "  4. wine"
  echo "  5. winetricks"
  echo "  6. protontricks"
  echo "  7. lutris"
  echo "  8. heroic-games-launcher-bin"
  echo "  9. prismlauncher"
  echo " 10. goverlay"
  echo " 11. mangojuice"
  echo "  a. Install all gaming packages"
  echo "  0. Skip gaming package installation"
  read -r -p "Enter your choices (e.g. 1,2,5 or 1 2 5, or a for all) [0]: " g_choices

  if [ "$g_choices" = "0" ] || [ -z "$g_choices" ]; then
    info "Skipping gaming packages."
    GAMING_SELECTED_PACKAGES=()
    break
  fi

  if [[ "$g_choices" =~ ^[aA]$ ]]; then
    g_choices="1 2 3 4 5 6 7 8 9 10 11"
  fi

  g_choices=$(echo "$g_choices" | tr ',' ' ')
  GAMING_SELECTED_PACKAGES=()
  invalid_choice=false

  for choice in $g_choices; do
    case "$choice" in
    1) append_unique_package GAMING_SELECTED_PACKAGES steam ;;
    2) append_unique_package GAMING_SELECTED_PACKAGES mangohud ;;
    3) append_unique_package GAMING_SELECTED_PACKAGES protonplus ;;
    4) append_unique_package GAMING_SELECTED_PACKAGES wine ;;
    5) append_unique_package GAMING_SELECTED_PACKAGES winetricks ;;
    6) append_unique_package GAMING_SELECTED_PACKAGES protontricks ;;
    7) append_unique_package GAMING_SELECTED_PACKAGES lutris ;;
    8) append_unique_package GAMING_SELECTED_PACKAGES heroic-games-launcher-bin ;;
    9) append_unique_package GAMING_SELECTED_PACKAGES prismlauncher ;;
    10) append_unique_package GAMING_SELECTED_PACKAGES goverlay ;;
    11) append_unique_package GAMING_SELECTED_PACKAGES mangojuice ;;
    *)
      echo "Invalid choice: $choice"
      invalid_choice=true
      ;;
    esac
  done

  if [ "$invalid_choice" = false ]; then
    info "Selected gaming packages: ${GAMING_SELECTED_PACKAGES[*]}"
    break
  fi
done

OPTIONALPKG=(
  vscodium-bin
  visual-studio-code-bin
  obsidian
  obs-studio
  upscayl-desktop-git
  video-downloader
  mission-center
)

declare -A OPTIONALPKG_DESC=(
  [vscodium - bin]="VSCodium Open Source Code Editor (auto-restores settings & extensions)"
  [visual - studio - code - bin]="Visual Studio Code editor"
  [obsidian]="Markdown text editor / knowledge base"
  [obs - studio]="OBS Studio recording & streaming software"
  [upscayl - desktop - git]="Image upscaler (desktop GUI)"
  [video - downloader]="Download videos locally from various sources"
  [mission - center]="Sleek task manager / system monitor"
)

SELECTED_OPTIONAL_PACKAGES=()
RESTORE_VSCODIUM=0

while true; do
  echo ""
  echo "Optional Applications (select one or more):"
  menu_index=1
  for pkg in "${OPTIONALPKG[@]}"; do
    desc="${OPTIONALPKG_DESC[$pkg]}"
    if [ -n "$desc" ]; then
      echo "  $menu_index. $pkg ($desc)"
    else
      echo "  $menu_index. $pkg"
    fi
    menu_index=$((menu_index + 1))
  done
  echo "  a. Install all optional packages"
  echo "  0. Skip optional packages"
  read -r -p "Enter your choices (e.g. 1,3 or 1 3, or a for all) [0]: " opt_choices

  if [ "$opt_choices" = "0" ] || [ -z "$opt_choices" ]; then
    info "Skipping optional applications."
    SELECTED_OPTIONAL_PACKAGES=()
    break
  fi

  if [[ "$opt_choices" =~ ^[aA]$ ]]; then
    opt_choices=$(seq -s ' ' 1 "${#OPTIONALPKG[@]}")
  fi

  opt_choices=$(echo "$opt_choices" | tr ',' ' ')
  SELECTED_OPTIONAL_PACKAGES=()
  invalid_choice=false

  for choice in $opt_choices; do
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "${#OPTIONALPKG[@]}" ]; then
      echo "Invalid choice: $choice"
      invalid_choice=true
      continue
    fi
    pkg_idx=$((choice - 1))
    append_unique_package SELECTED_OPTIONAL_PACKAGES "${OPTIONALPKG[$pkg_idx]}"
  done

  if [ "$invalid_choice" = false ]; then
    for pkg in "${SELECTED_OPTIONAL_PACKAGES[@]}"; do
      if [ "$pkg" = "vscodium-bin" ]; then
        RESTORE_VSCODIUM=1
      fi
    done
    info "Selected optional packages: ${SELECTED_OPTIONAL_PACKAGES[*]}"
    break
  fi
done

INSTALL_PRINTER_SUPPORT=0
while true; do
  echo ""
  read -r -p "Do you want printer support (CUPS + drivers)? (y/n) [n]: " printer_choice
  case "$printer_choice" in
  y | Y | yes | YES)
    INSTALL_PRINTER_SUPPORT=1
    info "Printer support packages will be installed and CUPS enabled."
    break
    ;;
  n | N | no | NO | "")
    INSTALL_PRINTER_SUPPORT=0
    info "Skipping printer support installation."
    break
    ;;
  *)
    echo "Please answer 'y' or 'n'."
    ;;
  esac
done

INSTALL_BLUETOOTH_PACKAGES=0
while true; do
  echo ""
  read -r -p "Do you want Bluetooth support (bluez + blueman)? (y/n) [y]: " bluetooth_choice
  case "${bluetooth_choice:-y}" in
  y | Y | yes | YES)
    INSTALL_BLUETOOTH_PACKAGES=1
    info "Bluetooth packages will be installed and service enabled."
    break
    ;;
  n | N | no | NO)
    INSTALL_BLUETOOTH_PACKAGES=0
    info "Skipping Bluetooth installation."
    break
    ;;
  *)
    echo "Please answer 'y' or 'n'."
    ;;
  esac
done

DDCUTIL_ENABLED=0
while true; do
  echo ""
  read -r -p "Do you want to configure ddcutil for external monitor brightness? (y/n) [n]: " ddc_choice
  case "$ddc_choice" in
  y | Y | yes | YES)
    DDCUTIL_ENABLED=1
    info "ddcutil monitor brightness support will be configured."
    break
    ;;
  n | N | no | NO | "")
    DDCUTIL_ENABLED=0
    info "Skipping ddcutil setup."
    break
    ;;
  *)
    echo "Please answer 'y' or 'n'."
    ;;
  esac
done

PACKAGES=(
  hyprmod
  polkit-gnome
  gnome-keyring
  hyprlock
  hypridle
  xdg-desktop-portal-hyprland
  xdg-desktop-portal-gtk
  hyprland-protocols
  pavucontrol
  playerctl
  pamixer
  brightnessctl
  wlsunset
  kitty
  kitty-shell-integration
  kitty-terminfo
  fish
  fastfetch
  starship
  eza
  neovim
  gedit
  loupe
  nautilus
  sushi
  file-roller
  unrar
  unzip
  7zip
  gnome-disk-utility
  gnome-calculator
  xdg-user-dirs
  grim
  slurp
  hyprshot
  satty
  jq
  gvfs
  gvfs-afc
  gvfs-mtp
  gvfs-smb
  ntfs-3g
  dosfstools
  exfatprogs
  tumbler
  ffmpegthumbnailer
  poppler-glib
  libopenraw
  libgsf
  freetype2
  libgepub
  matugen
  adw-gtk-theme
  nwg-look
  nwg-displays
  bibata-cursor-theme
  gcolor3
  yaru-icon-theme
  humanity-icon-theme
  cava
  unimatrix
  noto-fonts-emoji
  ttf-dejavu
  ttf-symbola
  power-profiles-daemon
  cpupower
  upower
  gpu-screen-recorder
  flatpak
  base-devel
  git
  github-cli
  clang
  cmake
  go
  rust
  pkgconf
  meson
  yazi
  ninja
  python
  qt6-base
  qt6ct
  qt6-websockets
  gst-plugins-good
  gst-plugins-ugly
  gst-libav
  stb
)

if [ "$AUDIO_MODE" = "easyeffects" ] || [ "$AUDIO_MODE" = "dolby" ]; then
  PACKAGES+=(
    easyeffects
    lsp-plugins-lv2
    calf
  )
fi

setup_chaotic_aur() {
  msg "Step 1: Setting up Chaotic-AUR and Multilib repositories..."

  local pacman_conf="/etc/pacman.conf"

  if grep -Eq '^[[:space:]]*\[multilib\][[:space:]]*$' "$pacman_conf" 2>/dev/null; then
    info "multilib is already enabled."
  else
    info "Enabling multilib repository..."
    if grep -Eq '^[[:space:]]*#[[:space:]]*\[multilib\][[:space:]]*$' "$pacman_conf" 2>/dev/null; then
      run_cmd sed -i '/^[[:space:]]*#[[:space:]]*\[multilib\][[:space:]]*$/,/^[[:space:]]*#[[:space:]]*Include[[:space:]]*=[[:space:]]*\/etc\/pacman\.d\/mirrorlist[[:space:]]*$/ s/^[[:space:]]*#[[:space:]]*//' "$pacman_conf"
    else
      if [ "$DRY_RUN" = true ]; then
        printf "%b  [dry-run]%b Append [multilib] section to %s\n" "${DIM}${YELLOW}" "${ALL_OFF}" "$pacman_conf"
      else
        printf "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist\n" >>"$pacman_conf"
      fi
    fi
  fi

  if grep -q "\[chaotic-aur\]" "$pacman_conf" 2>/dev/null; then
    info "Chaotic-AUR is already configured."
  else
    info "Adding Chaotic-AUR GPG key and keyring..."
    run_cmd pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
    run_cmd pacman-key --lsign-key 3056513887B78AEB
    run_cmd pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
    run_cmd pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

    if [ "$DRY_RUN" = true ]; then
      printf "%b  [dry-run]%b Append [chaotic-aur] section to %s\n" "${DIM}${YELLOW}" "${ALL_OFF}" "$pacman_conf"
    else
      printf "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist\n" >>"$pacman_conf"
    fi
  fi

  info "Refreshing package databases..."
  run_cmd pacman -Syy
}

remove_conflicting_packages() {
  msg "Step 2: Removing conflicting packages..."
  run_cmd pacman -Rns --noconfirm dolphin polkit-kde-agent vim thunar thunar-archive-plugin thunar-volman 2>/dev/null || true
}

update_system_packages() {
  msg "Step 3: Upgrading system packages before building AUR packages..."
  run_cmd pacman -Syu --noconfirm
}

ensure_yay() {
  msg "Step 4: Checking for AUR helper (yay)..."
  if command -v yay >/dev/null 2>&1; then
    info "yay is already installed."
    return 0
  fi

  info "yay not found. Attempting fast install via pacman (Chaotic-AUR)..."
  if run_cmd pacman -S --needed --noconfirm yay 2>/dev/null; then
    if [ "$DRY_RUN" = true ] || command -v yay >/dev/null 2>&1; then
      info "yay installed successfully via pacman."
      return 0
    fi
  fi

  info "Building and installing yay from AUR..."
  run_cmd pacman -S --needed --noconfirm base-devel git

  if [ "$DRY_RUN" = true ]; then
    printf "%b  [dry-run] (as %s)%b git clone https://aur.archlinux.org/yay.git && makepkg -si --noconfirm\n" "${DIM}${YELLOW}" "$ACTUAL_USER" "${ALL_OFF}"
  else
    local tmp_yay
    tmp_yay="$(mktemp -d)"
    chown "$ACTUAL_USER:$ACTUAL_USER" "$tmp_yay"
    as_user git clone https://aur.archlinux.org/yay.git "$tmp_yay"
    (cd "$tmp_yay" && as_user makepkg -si --noconfirm)
    rm -rf "$tmp_yay"

    if command -v yay >/dev/null 2>&1; then
      info "yay built and installed successfully from AUR."
    else
      warn "yay installation could not be verified. Some AUR packages may fail to install."
    fi
  fi
}

ensure_hyprland() {
  msg "Step 5: Checking for Hyprland compositor..."
  if pacman -Qq hyprland >/dev/null 2>&1 || pacman -Qq hyprland-git >/dev/null 2>&1 || command -v Hyprland >/dev/null 2>&1 || command -v hyprland >/dev/null 2>&1; then
    info "Hyprland is already installed."
    return 0
  fi

  info "Hyprland is not detected. Installing Hyprland via pacman..."
  if ! run_cmd pacman -S --needed --noconfirm hyprland; then
    error "Failed to install Hyprland via pacman."
    exit 1
  fi
}

install_core_packages() {
  msg "Step 6: Installing core desktop packages and defaults..."
  if ! run_cmd pacman -S --needed --noconfirm "${PACKAGES[@]}"; then
    info "Retrying core package installation via yay to resolve any AUR dependencies..."
    as_user yay -S --needed --noconfirm "${PACKAGES[@]}"
  fi

  info "Installing JetBrains Mono Nerd Font via yay..."
  as_user yay -S --needed --noconfirm ttf-jetbrains-mono-nerd

  info "Adding $ACTUAL_USER to the video group..."
  run_cmd usermod -aG video "$ACTUAL_USER"
}

install_noctalia() {
  msg "Step 7: Installing Noctalia shell (noctalia-git)..."
  as_user yay -S --needed --noconfirm noctalia-git
}

install_selected_components() {
  msg "Step 8: Installing user-selected components..."

  if [ "${#AUDIO_VIDEO_PACKAGES[@]}" -gt 0 ]; then
    info "Installing audio/video players: ${AUDIO_VIDEO_PACKAGES[*]}"
    run_cmd pacman -S --needed --noconfirm "${AUDIO_VIDEO_PACKAGES[@]}"
  fi

  if [ "${#SELECTED_BROWSERS[@]}" -gt 0 ]; then
    info "Installing web browsers: ${SELECTED_BROWSERS[*]}"
    for browser in "${SELECTED_BROWSERS[@]}"; do
      case "$browser" in
      brave-origin)
        info "Installing Brave Origin..."
        if [ "$DRY_RUN" = true ]; then
          printf "%b  [dry-run]%b curl -fsS https://dl.brave.com/install.sh | FLAVOR=origin sh\n" "${DIM}${YELLOW}" "${ALL_OFF}"
        else
          curl -fsS https://dl.brave.com/install.sh | FLAVOR=origin sh
        fi
        ;;
      helium)
        info "Installing Helium Browser..."
        as_user yay -S --needed --noconfirm helium-browser-bin
        ;;
      brave)
        info "Installing Brave..."
        as_user yay -S --needed --noconfirm brave-bin
        ;;
      zen-browser)
        info "Installing Zen Browser..."
        as_user yay -S --needed --noconfirm zen-browser-bin
        ;;
      firefox)
        info "Installing Firefox..."
        run_cmd pacman -S --needed --noconfirm firefox
        ;;
      vivaldi)
        info "Installing Vivaldi..."
        run_cmd pacman -S --needed --noconfirm vivaldi
        ;;
      librewolf)
        info "Installing LibreWolf..."
        as_user yay -S --needed --noconfirm librewolf
        ;;
      esac
    done
  fi

  if [ "$INSTALL_LIBREOFFICE" -eq 1 ]; then
    info "Installing LibreOffice..."
    run_cmd pacman -S --needed --noconfirm libreoffice-fresh
  fi

  if [ "${#GAMING_SELECTED_PACKAGES[@]}" -gt 0 ]; then
    for pkg in "${GAMING_SELECTED_PACKAGES[@]}"; do
      case "$pkg" in
      mangohud) append_unique_package GAMING_SELECTED_PACKAGES lib32-mangohud ;;
      prismlauncher) append_unique_package GAMING_SELECTED_PACKAGES jdk21-openjdk ;;
      esac
    done
    info "Installing gaming packages: ${GAMING_SELECTED_PACKAGES[*]}"
    as_user yay -S --needed --noconfirm "${GAMING_SELECTED_PACKAGES[@]}"
  fi

  if [ "${#SELECTED_OPTIONAL_PACKAGES[@]}" -gt 0 ]; then
    for pkg in "${SELECTED_OPTIONAL_PACKAGES[@]}"; do
      if [ "$pkg" = "obs-studio" ]; then
        append_unique_package SELECTED_OPTIONAL_PACKAGES luajit
      fi
    done
    info "Installing optional packages: ${SELECTED_OPTIONAL_PACKAGES[*]}"
    as_user yay -S --needed --noconfirm "${SELECTED_OPTIONAL_PACKAGES[@]}"
  fi

  if [ "$INSTALL_PRINTER_SUPPORT" -eq 1 ]; then
    info "Installing printer support (cups, drivers)..."
    run_cmd pacman -S --needed --noconfirm \
      cups cups-filters cups-pdf hplip gutenprint system-config-printer \
      foomatic-db foomatic-db-engine \
      python-pyqt5 python-reportlab python-pyqt6
  fi

  if [ "$INSTALL_BLUETOOTH_PACKAGES" -eq 1 ]; then
    info "Installing Bluetooth packages..."
    run_cmd pacman -S --needed --noconfirm bluez bluez-utils blueman
  fi
}

configure_services() {
  msg "Step 9: Configuring system services..."

  if [ "$INSTALL_PRINTER_SUPPORT" -eq 1 ]; then
    info "Enabling and starting CUPS service..."
    run_cmd systemctl enable --now cups
  fi

  if [ "$INSTALL_BLUETOOTH_PACKAGES" -eq 1 ]; then
    info "Enabling Bluetooth service..."
    run_cmd systemctl enable bluetooth
  fi
}

setup_ddcutil() {
  if [ "$DDCUTIL_ENABLED" -ne 1 ]; then
    return 0
  fi

  msg "Step 10: Setting up ddcutil monitor brightness control..."
  run_cmd pacman -S --needed --noconfirm ddcutil
  as_user yay -S --needed --noconfirm ddcutil-service 2>/dev/null || true

  info "Loading i2c-dev kernel module..."
  run_cmd modprobe i2c-dev 2>/dev/null || true

  if [ "$DRY_RUN" = true ]; then
    printf "%b  [dry-run]%b Write i2c-dev to /etc/modules-load.d/i2c-dev.conf\n" "${DIM}${YELLOW}" "${ALL_OFF}"
  else
    echo "i2c-dev" >/etc/modules-load.d/i2c-dev.conf
  fi

  info "Reloading udev rules..."
  run_cmd udevadm control --reload-rules
  run_cmd udevadm trigger

  info "Adding $ACTUAL_USER to the i2c group..."
  run_cmd usermod -aG i2c "$ACTUAL_USER"
}

setup_sddm() {
  if [ "$INSTALL_SDDM" -ne 1 ]; then
    return 0
  fi

  msg "Step 11: Installing SDDM and configuring matugen-minimal theme..."
  run_cmd pacman -S --needed --noconfirm sddm
  run_cmd systemctl enable sddm

  local theme_name="matugen-minimal"
  local theme_repo="https://github.com/ilyamiro/imperative-dots.git"
  local theme_dest="/usr/share/sddm/themes/${theme_name}"

  info "Fetching ${theme_name} theme..."
  if [ "$DRY_RUN" = true ]; then
    printf "%b  [dry-run]%b Sparse clone %s theme to %s\n" "${DIM}${YELLOW}" "${ALL_OFF}" "$theme_repo" "$theme_dest"
    printf "%b  [dry-run]%b Generate %s/Colors.qml\n" "${DIM}${YELLOW}" "${ALL_OFF}" "$theme_dest"
    printf "%b  [dry-run]%b Write /etc/sddm.conf.d/10-wayland-matugen.conf\n" "${DIM}${YELLOW}" "${ALL_OFF}"
  else
    local tmp_sddm
    tmp_sddm="$(mktemp -d)"
    git clone --depth 1 --filter=blob:none --sparse "$theme_repo" "$tmp_sddm" >/dev/null 2>&1 || true
    git -C "$tmp_sddm" sparse-checkout set ".config/sddm/themes/${theme_name}" >/dev/null 2>&1 || true

    local src_theme="$tmp_sddm/.config/sddm/themes/${theme_name}"
    if [ -d "$src_theme" ]; then
      mkdir -p "$theme_dest"
      cp -r "$src_theme/"* "$theme_dest/"

      cat >"$theme_dest/Colors.qml" <<'EOF'
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
      mkdir -p /etc/sddm.conf.d
      cat >/etc/sddm.conf.d/10-wayland-matugen.conf <<EOF
[Theme]
Current=${theme_name}

[General]
DisplayServer=wayland
GreeterEnvironment=QT_WAYLAND_DISABLE_WINDOWDECORATION=1
EOF
      info "SDDM theme installed and set active."
    else
      warn "Could not fetch SDDM theme from upstream repository. Skipping theme setup."
    fi
    rm -rf "$tmp_sddm"
  fi
}

set_default_file_manager() {
  msg "Step 12: Setting GNOME Nautilus as default file manager & configuring bookmarks..."

  as_user mkdir -p "$CONFIG_DIR/gtk-3.0"
  as_user xdg-mime default org.gnome.Nautilus.desktop inode/directory application/x-gnome-saved-search

  if [ "$DRY_RUN" = true ]; then
    printf "%b  [dry-run] (as %s)%b Write sidebar bookmarks to %s/gtk-3.0/bookmarks\n" "${DIM}${YELLOW}" "$ACTUAL_USER" "${ALL_OFF}" "$CONFIG_DIR"
  else
    cat >"$CONFIG_DIR/gtk-3.0/bookmarks" <<EOF
file://$ACTUAL_USER_HOME/Documents
file://$ACTUAL_USER_HOME/Downloads
file://$ACTUAL_USER_HOME/Pictures
file://$ACTUAL_USER_HOME/Music
file://$ACTUAL_USER_HOME/Videos
file://$ACTUAL_USER_HOME/.config/hypr
EOF
    chown "$ACTUAL_USER:$ACTUAL_USER" "$CONFIG_DIR/gtk-3.0/bookmarks"
  fi
}

update_user_directories() {
  msg "Step 13: Updating standard user directories..."
  as_user xdg-user-dirs-update
}

deploy_configs() {
  msg "Step 14: Deploying dotfiles, icons, and wallpapers..."

  as_user mkdir -p "$CONFIG_DIR"
  as_user mkdir -p "$ACTUAL_USER_HOME/.local/share/icons"
  as_user mkdir -p "$ACTUAL_USER_HOME/Pictures/backgrounds"

  local dot_dirs=(hypr kitty fish fastfetch nvim noctalia vesktop)

  info "Checking for existing configurations to back up..."
  for d in "${dot_dirs[@]}"; do
    local target="$CONFIG_DIR/$d"
    if [ -e "$target" ] || [ -L "$target" ]; then
      if [ "$DRY_RUN" = true ]; then
        printf "%b  [dry-run]%b Backup %s -> %s/%s\n" "${DIM}${YELLOW}" "${ALL_OFF}" "$target" "$BACKUP_DIR" "$d"
      else
        mkdir -p "$BACKUP_DIR"
        mv "$target" "$BACKUP_DIR/$d"
        info "Backed up existing $d -> $BACKUP_DIR/$d"
      fi
    fi
  done

  for d in "${dot_dirs[@]}"; do
    if [ -d "$REPO_DIR/$d" ]; then
      info "Deploying $d config -> $CONFIG_DIR/$d"
      run_cmd cp -a "$REPO_DIR/$d" "$CONFIG_DIR/$d"
    fi
  done

  if [ -f "$REPO_DIR/starship.toml" ]; then
    info "Deploying starship.toml -> $CONFIG_DIR/starship.toml"
    run_cmd cp -a "$REPO_DIR/starship.toml" "$CONFIG_DIR/starship.toml"
  fi

  if [ -d "$REPO_DIR/icons/macOS" ]; then
    info "Deploying macOS cursor theme -> $ACTUAL_USER_HOME/.local/share/icons/macOS"
    run_cmd cp -a "$REPO_DIR/icons/macOS" "$ACTUAL_USER_HOME/.local/share/icons/macOS"
  fi

  if [ -d "$REPO_DIR/backgrounds" ]; then
    info "Deploying wallpapers -> $ACTUAL_USER_HOME/Pictures/backgrounds"
    run_cmd cp -a "$REPO_DIR/backgrounds/"* "$ACTUAL_USER_HOME/Pictures/backgrounds/" 2>/dev/null || true
  fi

  if [ -d "$CONFIG_DIR/hypr/Scripts" ]; then
    info "Setting executable permissions for Hyprland scripts..."
    run_cmd find "$CONFIG_DIR/hypr/Scripts" -type f -exec chmod +x {} +
  fi

  if [ "$INSTALL_NVIDIA_OPTIONAL" -eq 1 ] && [ -f "$CONFIG_DIR/hypr/startup.lua" ]; then
    info "Enabling Nvidia-specific Hyprland configuration..."
    run_cmd sed -i 's|local enable_nvidia_optional = false|local enable_nvidia_optional = true|' "$CONFIG_DIR/hypr/startup.lua"
  fi

  if [ "$DDCUTIL_ENABLED" -eq 1 ] && [ -f "$CONFIG_DIR/noctalia/settings.json" ]; then
    info "Enabling Noctalia DDC support in settings.json..."
    if [ "$DRY_RUN" = true ]; then
      printf "%b  [dry-run]%b Patch %s/noctalia/settings.json enableDdcSupport=True\n" "${DIM}${YELLOW}" "${ALL_OFF}" "$CONFIG_DIR"
    else
      python3 - "$CONFIG_DIR/noctalia/settings.json" <<'PY'
import json, sys
path = sys.argv[1]
try:
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
    if not isinstance(data.get("brightness"), dict):
        data["brightness"] = {}
    data["brightness"]["enableDdcSupport"] = True
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=4)
        f.write("\n")
except Exception:
    pass
PY
    fi
  fi

  if [ "$DRY_RUN" = false ] && [[ $EUID -eq 0 ]]; then
    chown -R "$ACTUAL_USER:$ACTUAL_USER" "$CONFIG_DIR" "$ACTUAL_USER_HOME/.local/share/icons" "$ACTUAL_USER_HOME/Pictures/backgrounds"
    if [ -d "$BACKUP_DIR" ]; then
      chown -R "$ACTUAL_USER:$ACTUAL_USER" "$BACKUP_DIR"
    fi
  fi
}

apply_dolby_pipewire_profile() {
  if [ "$AUDIO_MODE" != "dolby" ]; then
    return 0
  fi

  msg "Step 15: Applying Dolby Atmos PipeWire profile..."
  local pw_src="$REPO_DIR/pipewire"
  local pw_dest="$CONFIG_DIR/pipewire"

  if [ -d "$pw_src" ]; then
    run_cmd mkdir -p "$pw_dest"
    run_cmd cp -a "$pw_src/"* "$pw_dest/"
    if [ "$DRY_RUN" = false ] && [[ $EUID -eq 0 ]]; then
      chown -R "$ACTUAL_USER:$ACTUAL_USER" "$pw_dest"
    fi
    info "Dolby PipeWire profile deployed to $pw_dest."
  else
    warn "No pipewire/ folder found in repo. Skipping profile copy."
  fi
}

restore_vscodium() {
  if [ "$RESTORE_VSCODIUM" -ne 1 ]; then
    return 0
  fi

  msg "Step 16: Restoring VSCodium configuration & extensions..."

  local vscodium_user_dir="$CONFIG_DIR/VSCodium/User"
  as_user mkdir -p "$vscodium_user_dir"

  if [ -f "$REPO_DIR/vscodium/settings.json" ]; then
    info "Restoring VSCodium settings.json..."
    run_cmd cp -a "$REPO_DIR/vscodium/settings.json" "$vscodium_user_dir/settings.json"
    if [ "$DRY_RUN" = false ] && [[ $EUID -eq 0 ]]; then
      chown -R "$ACTUAL_USER:$ACTUAL_USER" "$vscodium_user_dir"
    fi
  fi

  if [ -f "$REPO_DIR/vscodium/extensions.txt" ]; then
    info "Installing VSCodium extensions..."
    while read -r ext || [ -n "$ext" ]; do
      ext="$(echo "$ext" | tr -d '\r\n[:space:]')"
      if [ -z "$ext" ] || [[ "$ext" =~ ^# ]]; then
        continue
      fi
      info "Extension: $ext"
      as_user codium --install-extension "$ext" 2>/dev/null || true
    done <"$REPO_DIR/vscodium/extensions.txt"
  fi
}

reboot_prompt() {
  echo ""
  echo "  ================================================================"
  printf "%b  [SUCCESS] setup completed successfully!%b\n" "${GREEN}" "${ALL_OFF}"
  echo "  ================================================================"
  echo ""
  info "All dotfiles, themes, and application configurations have been deployed."
  if [ "$DRY_RUN" = false ] && [ -d "$BACKUP_DIR" ]; then
    info "Previous configs backed up to: $BACKUP_DIR"
  fi
  echo ""

  if [ "$DRY_RUN" = true ]; then
    info "Dry run simulation complete. No changes were made."
    exit 0
  fi

  while true; do
    read -r -p "Reboot now? (y/n): " rb_choice
    case "$rb_choice" in
    y | Y | yes | YES)
      msg "Rebooting system now..."
      reboot
      break
      ;;
    n | N | no | NO)
      echo ""
      info "Setup complete! Please log out and back in (or reboot manually) for all changes to take effect."
      break
      ;;
    *)
      echo "Please answer 'y' or 'n'."
      ;;
    esac
  done
}

main() {
  setup_chaotic_aur
  remove_conflicting_packages
  update_system_packages
  ensure_yay
  ensure_hyprland
  install_core_packages
  install_noctalia
  install_selected_components
  configure_services
  setup_ddcutil
  setup_sddm
  set_default_file_manager
  update_user_directories
  deploy_configs
  apply_dolby_pipewire_profile
  restore_vscodium
  reboot_prompt
}

main
