#!/bin/bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║            cachyXhyprland-fried-rice — Auto Install Script                 ║
# ║              Hyprland Rice for CachyOS / Arch Linux                        ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
#
# Usage:  chmod +x install.sh && ./install.sh
#
# This script will:
#   1. Install yay (if missing)
#   2. Install all required packages
#   3. Backup your existing ~/.config to ~/.config-backup-<timestamp>
#   4. Deploy the rice configs via rsync
#   5. Copy wallpapers to ~/Downloads/Wallpapers
#   6. Set up GTK 4.0 symlinks
#   7. Make all scripts executable

set -euo pipefail

# ─── ANSI Color Codes ────────────────────────────────────────────────────────
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
MAGENTA='\033[1;35m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
DIM='\033[2m'
BOLD='\033[1m'
RESET='\033[0m'

# ─── Helper Functions ─────────────────────────────────────────────────────────
print_banner() {
    echo ""
    echo -e "${MAGENTA}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${MAGENTA}║${RESET}                                                            ${MAGENTA}║${RESET}"
    echo -e "${MAGENTA}║${RESET}   ${CYAN}${BOLD}🍚  cachyXhyprland-fried-rice  🍚${RESET}                        ${MAGENTA}║${RESET}"
    echo -e "${MAGENTA}║${RESET}   ${DIM}The Ultimate Hyprland Rice Installer${RESET}                      ${MAGENTA}║${RESET}"
    echo -e "${MAGENTA}║${RESET}                                                            ${MAGENTA}║${RESET}"
    echo -e "${MAGENTA}║${RESET}   ${WHITE}Components:${RESET}                                               ${MAGENTA}║${RESET}"
    echo -e "${MAGENTA}║${RESET}     ${GREEN}●${RESET} Hyprland     ${GREEN}●${RESET} AGS Bar       ${GREEN}●${RESET} Fuzzel            ${MAGENTA}║${RESET}"
    echo -e "${MAGENTA}║${RESET}     ${GREEN}●${RESET} SwayNC       ${GREEN}●${RESET} Matugen       ${GREEN}●${RESET} Hyprlock          ${MAGENTA}║${RESET}"
    echo -e "${MAGENTA}║${RESET}     ${GREEN}●${RESET} swww         ${GREEN}●${RESET} Kitty         ${GREEN}●${RESET} Waybar ${DIM}(backup)${RESET}  ${MAGENTA}║${RESET}"
    echo -e "${MAGENTA}║${RESET}                                                            ${MAGENTA}║${RESET}"
    echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
}

step() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${CYAN}${BOLD}  STEP $1${RESET}  ${WHITE}$2${RESET}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

info()    { echo -e "  ${BLUE}ℹ${RESET}  $1"; }
success() { echo -e "  ${GREEN}✔${RESET}  $1"; }
warn()    { echo -e "  ${YELLOW}⚠${RESET}  $1"; }
error()   { echo -e "  ${RED}✘${RESET}  $1"; }
doing()   { echo -e "  ${MAGENTA}➜${RESET}  $1"; }

confirm_proceed() {
    echo ""
    echo -e "${YELLOW}${BOLD}  This script will:${RESET}"
    echo -e "    ${WHITE}1.${RESET} Install packages via yay/pacman"
    echo -e "    ${WHITE}2.${RESET} Backup ~/.config → ~/.config-backup-<timestamp>"
    echo -e "    ${WHITE}3.${RESET} Deploy rice configs to ~/.config"
    echo -e "    ${WHITE}4.${RESET} Copy wallpapers to ~/Downloads/Wallpapers"
    echo -e "    ${WHITE}5.${RESET} Set up GTK symlinks and script permissions"
    echo ""
    read -rp "$(echo -e "${CYAN}  Proceed? [y/N]:${RESET} ")" response
    case "$response" in
        [yY][eE][sS]|[yY]) return 0 ;;
        *) echo -e "\n${RED}  Aborted.${RESET}"; exit 1 ;;
    esac
}

# ─── Resolve Script Directory ────────────────────────────────────────────────
# This ensures the script works regardless of where it's called from
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Verify that .config directory exists in repo
if [ ! -d "$SCRIPT_DIR/.config" ]; then
    error "Cannot find .config directory in $SCRIPT_DIR"
    error "Make sure you are running this script from the repository root."
    exit 1
fi

# ─── Package List ────────────────────────────────────────────────────────────
# Core packages (official repos)
PACMAN_PKGS=(
    hyprland
    kitty
    thunar
    btop
    brightnessctl
    playerctl
    wl-clipboard
    grim
    slurp
    jq
    rsync
    imagemagick
)

# AUR packages
AUR_PKGS=(
    fuzzel
    swaynotificationcenter
    aylurs-gtk-shell
    matugen-bin
    swww
    hyprlock
    nwg-look
    adw-gtk3
    wlogout
    rofi-wayland
    whitesur-gtk-theme-git
    whitesur-icon-theme-git
    macos-bigsur-cursor-theme-git
)

# ═════════════════════════════════════════════════════════════════════════════
# MAIN
# ═════════════════════════════════════════════════════════════════════════════
print_banner
confirm_proceed

# ──────────────────────────────────────────────────────────────────────────────
# STEP 1: Ensure yay is installed
# ──────────────────────────────────────────────────────────────────────────────
step "1/6" "Checking AUR helper (yay)"

if command -v yay &>/dev/null; then
    success "yay is already installed: $(yay --version 2>/dev/null | head -1)"
else
    warn "yay is not installed. Installing now..."

    # Install build dependencies
    doing "Installing base-devel and git..."
    sudo pacman -S --needed --noconfirm base-devel git

    # Clone and build yay
    doing "Cloning yay from AUR..."
    TEMP_YAY=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$TEMP_YAY/yay"
    cd "$TEMP_YAY/yay"
    doing "Building yay..."
    makepkg -si --noconfirm
    cd "$SCRIPT_DIR"
    rm -rf "$TEMP_YAY"

    if command -v yay &>/dev/null; then
        success "yay installed successfully!"
    else
        error "Failed to install yay. Please install it manually."
        exit 1
    fi
fi

# ──────────────────────────────────────────────────────────────────────────────
# STEP 2: Install packages
# ──────────────────────────────────────────────────────────────────────────────
step "2/6" "Installing packages"

# Official repos first
doing "Installing official repository packages..."
echo -e "  ${DIM}Packages: ${PACMAN_PKGS[*]}${RESET}"
sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}" || {
    warn "Some pacman packages may have failed. Continuing..."
}

# AUR packages
doing "Installing AUR packages via yay..."
echo -e "  ${DIM}Packages: ${AUR_PKGS[*]}${RESET}"
yay -S --needed --noconfirm "${AUR_PKGS[@]}" || {
    warn "Some AUR packages may have failed. Continuing..."
}

success "Package installation complete!"

# D-Bus and portal setup
systemctl --user enable --now xdg-desktop-portal-hyprland || true
dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=Hyprland || true

# macOS fonts/cursor
yay -S --noconfirm apple-fonts ttf-sf-pro 2>/dev/null || true
yay -S --noconfirm apple-cursor 2>/dev/null || true
mkdir -p ~/.icons/default
echo -e "[Icon Theme]\nInherits=macOS-BigSur" > ~/.icons/default/index.theme

# ensure swww daemon running
if ! pgrep -x swww-daemon > /dev/null; then
  swww-daemon --no-cache &
  sleep 1
fi

# ──────────────────────────────────────────────────────────────────────────────
# STEP 3: Backup existing config
# ──────────────────────────────────────────────────────────────────────────────
step "3/6" "Backing up existing configuration"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$HOME/.config-backup-$TIMESTAMP"

if [ -d "$HOME/.config" ]; then
    doing "Backing up ~/.config → $BACKUP_DIR"
    cp -r "$HOME/.config" "$BACKUP_DIR"

    if [ -d "$BACKUP_DIR" ]; then
        BACKUP_SIZE=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1)
        success "Backup created: $BACKUP_DIR ($BACKUP_SIZE)"
    else
        error "Backup failed!"
        exit 1
    fi
else
    info "No existing ~/.config found. Skipping backup."
    mkdir -p "$HOME/.config"
    BACKUP_DIR="(none — no existing config found)"
fi

# ──────────────────────────────────────────────────────────────────────────────
# STEP 4: Deploy config files
# ──────────────────────────────────────────────────────────────────────────────
step "4/6" "Deploying rice configuration"

doing "Syncing config files to ~/.config..."
rsync -av --progress \
    --exclude='.git' \
    --exclude='.gitignore' \
    --exclude='.gitattributes' \
    --exclude='install.sh' \
    --exclude='README.md' \
    --exclude='Wallpapers' \
    "$SCRIPT_DIR/.config/" "$HOME/.config/"

success "Config files deployed to ~/.config"

# ──────────────────────────────────────────────────────────────────────────────
# STEP 5: Copy wallpapers & set up GTK symlinks
# ──────────────────────────────────────────────────────────────────────────────
step "5/6" "Setting up wallpapers and GTK theme"

# Copy wallpapers
WALLPAPER_DEST="$HOME/Downloads/Wallpapers"
if [ -d "$SCRIPT_DIR/Wallpapers" ]; then
    doing "Copying wallpapers to $WALLPAPER_DEST..."
    mkdir -p "$WALLPAPER_DEST"
    rsync -av --progress "$SCRIPT_DIR/Wallpapers/" "$WALLPAPER_DEST/"
    success "Wallpapers installed to $WALLPAPER_DEST"
else
    warn "No Wallpapers directory found in repo. Skipping."
fi

# GTK 4.0 symlink for assets
doing "Setting up GTK 4.0 assets symlink..."
GTK4_ASSETS="$HOME/.config/gtk-4.0/assets"
GTK4_THEME="/usr/share/themes/adw-gtk3-dark/gtk-4.0/assets"

if [ -d "$GTK4_THEME" ]; then
    # Remove the placeholder file
    rm -f "$GTK4_ASSETS" 2>/dev/null || true
    ln -sf "$GTK4_THEME" "$GTK4_ASSETS"
    success "GTK 4.0 assets symlink created"
else
    warn "adw-gtk3-dark theme not found at $GTK4_THEME"
    warn "Install it with: yay -S adw-gtk3"
    info "The symlink will need to be created manually after installing the theme."
fi

# ──────────────────────────────────────────────────────────────────────────────
# STEP 6: Set permissions on scripts
# ──────────────────────────────────────────────────────────────────────────────
step "6/6" "Setting script permissions"

doing "Making all shell scripts executable..."
find ~/.config -name "*.sh" -exec chmod +x {} \;
success "All shell scripts under ~/.config are executable"

echo "=== checking for common issues ==="
command -v ags      && echo "ok: ags"      || echo "MISSING: ags"
command -v swww     && echo "ok: swww"     || echo "MISSING: swww"
command -v matugen  && echo "ok: matugen"  || echo "MISSING: matugen"
command -v fuzzel   && echo "ok: fuzzel"   || echo "MISSING: fuzzel"
command -v swaync   && echo "ok: swaync"   || echo "MISSING: swaync"
hyprctl version     && echo "ok: hyprland" || echo "MISSING: hyprland"

# ═════════════════════════════════════════════════════════════════════════════
# DONE
# ═════════════════════════════════════════════════════════════════════════════
echo ""
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${GREEN}║${RESET}                                                            ${GREEN}║${RESET}"
echo -e "${GREEN}║${RESET}   ${GREEN}${BOLD}✔  Installation Complete!${RESET}                                 ${GREEN}║${RESET}"
echo -e "${GREEN}║${RESET}                                                            ${GREEN}║${RESET}"
echo -e "${GREEN}║${RESET}   ${WHITE}Your config backup is at:${RESET}                                 ${GREEN}║${RESET}"
echo -e "${GREEN}║${RESET}   ${DIM}$BACKUP_DIR${RESET}"
echo -e "${GREEN}║${RESET}                                                            ${GREEN}║${RESET}"
echo -e "${GREEN}║${RESET}   ${WHITE}What's been set up:${RESET}                                        ${GREEN}║${RESET}"
echo -e "${GREEN}║${RESET}     ${CYAN}●${RESET} Hyprland config with elastic animations              ${GREEN}║${RESET}"
echo -e "${GREEN}║${RESET}     ${CYAN}●${RESET} AGS top bar (glassmorphism, reactive widgets)         ${GREEN}║${RESET}"
echo -e "${GREEN}║${RESET}     ${CYAN}●${RESET} Fuzzel launcher (Wayland-native)                      ${GREEN}║${RESET}"
echo -e "${GREEN}║${RESET}     ${CYAN}●${RESET} SwayNC notification center (Super+N)                  ${GREEN}║${RESET}"
echo -e "${GREEN}║${RESET}     ${CYAN}●${RESET} Matugen dynamic theming (wallpaper-based)             ${GREEN}║${RESET}"
echo -e "${GREEN}║${RESET}     ${CYAN}●${RESET} swww wallpaper engine with VM detection               ${GREEN}║${RESET}"
echo -e "${GREEN}║${RESET}                                                            ${GREEN}║${RESET}"
echo -e "${GREEN}║${RESET}   ${YELLOW}${BOLD}⟳  Please reboot your system to apply all changes.${RESET}       ${GREEN}║${RESET}"
echo -e "${GREEN}║${RESET}   ${DIM}   Or log out and select Hyprland from your login manager.${RESET}${GREEN}║${RESET}"
echo -e "${GREEN}║${RESET}                                                            ${GREEN}║${RESET}"
echo -e "${GREEN}║${RESET}   ${MAGENTA}${BOLD}🍚 Happy fried ricing! Flavour is key. 🍚${RESET}                ${GREEN}║${RESET}"
echo -e "${GREEN}║${RESET}                                                            ${GREEN}║${RESET}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${RESET}"
echo ""
