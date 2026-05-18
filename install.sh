#!/bin/bash
# gaby's dotfiles installer

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PINK='\033[0;35m'
NC='\033[0m'

log()     { echo -e "${BLUE}  →${NC} $1"; }
success() { echo -e "${GREEN}  ✓${NC} $1"; }
warn()    { echo -e "${YELLOW}  !${NC} $1"; }
error()   { echo -e "${RED}  ✗${NC} $1"; exit 1; }
section() { echo -e "\n${PINK}── $1 ${NC}"; }

echo -e "${PINK}"
echo "  ╭──────────────────────────────╮"
echo "  │     gaby's dotfiles          │"
echo "  │     arch + hyprland          │"
echo "  ╰──────────────────────────────╯"
echo -e "${NC}"

#  Check: not root 
[ "$EUID" -eq 0 ] && error "don't run this as root"

# Check: yay
section "Checking AUR helper"
if ! command -v yay &>/dev/null; then
    warn "yay not found, installing..."
    sudo pacman -S --needed git base-devel
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay && makepkg -si --noconfirm
    cd "$DOTFILES_DIR"
    success "yay installed"
else
    success "yay found"
fi

# Packages 
section "Installing packages"
 
PACMAN_PACKAGES=(
    # Core Hyprland
    hyprland
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
    hypridle
    hyprpicker
 
    # Audio
    pipewire
    pipewire-alsa
    pipewire-jack
    pipewire-pulse
    wireplumber
    gst-plugin-pipewire
    pavucontrol
    playerctl
    mpd
    mpc
    mpd-mpris
    cava
 
    # Wayland utils
    grim
    slurp
    swappy
    wl-clipboard
    cliphist
    wlsunset
 
    # Network & Bluetooth
    networkmanager
    network-manager-applet
    blueman
    bluez
    bluez-utils
 
    # Terminal
    kitty
    zsh
 
    # Notifications
    swaync
 
    # Quickshell
    quickshell
 
    # Theming
    python-pywal
    qt5ct
    qt6ct
    kvantum
    papirus-icon-theme
    nwg-look
    polkit-gnome
 
    # Fonts
    ttf-jetbrains-mono-nerd
    noto-fonts
    noto-fonts-emoji
 
    # System utils
    brightnessctl
    acpi
    upower
    fastfetch
    htop
    jq
    curl
    git
 
    # Apps
    nemo
    mpv
    gpu-screen-recorder
)
 
AUR_PACKAGES=(
    awww
    swaylock-effects
)

log "Installing pacman packages..."
sudo pacman -S --needed --noconfirm "${PACMAN_PACKAGES[@]}" \
    || warn "Some pacman packages failed — check manually"
success "Pacman packages done"

log "Installing AUR packages..."
yay -S --needed --noconfirm "${AUR_PACKAGES[@]}" \
    || warn "Some AUR packages failed — check manually"
success "AUR packages done"

# Directories 
section "Creating directories"

DIRS=(
    "$HOME/.config/quickshell/assets/pfps"
    "$HOME/.config/quickshell/assets/gifs"
    "$HOME/.config/quickshell/files"
    "$HOME/Pictures/Fonditos"
    "$HOME/Pictures/Screenshots"
    "$HOME/screen-recordings"
    "$HOME/wallpapers"
)

for dir in "${DIRS[@]}"; do
    mkdir -p "$dir"
    success "$dir"
done

# Copy dotfiles
section "Copying dotfiles"

copy_config() {
    local src="$DOTFILES_DIR/.config/$1"
    local dst="$HOME/.config/$1"
    if [ -e "$src" ]; then
        mkdir -p "$(dirname "$dst")"
        cp -r "$src" "$dst"
        success "$1"
    else
        warn "$1 not found in dotfiles, skipping"
    fi
}

copy_config "hypr"
copy_config "kitty"
copy_config "quickshell"
copy_config "swaync"
copy_config "cava"
copy_config "fastfetch"
copy_config "htop"
copy_config "mpv"
copy_config "wal"

# zshrc
if [ -f "$DOTFILES_DIR/.zshrc" ]; then
    cp "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
    success ".zshrc"
fi

# Scripts
if [ -d "$DOTFILES_DIR/.config/scripts" ]; then
    cp -r "$DOTFILES_DIR/.config/scripts" "$HOME/.config/scripts"
    success "scripts"
fi

# Script permissions
section "Setting script permissions"

if [ -d "$HOME/.config/scripts" ]; then
    chmod +x "$HOME/.config/scripts/"*.sh
    success "scripts are executable"
else
    warn "scripts folder not found"
fi

# Wallpapers 
section "Wallpapers"
if [ -d "$DOTFILES_DIR/Wallpapers" ] && [ "$(ls -A "$DOTFILES_DIR/Wallpapers" 2>/dev/null)" ]; then
    cp -r "$DOTFILES_DIR/Wallpapers/." "$HOME/Pictures/Fonditos/"
    success "wallpapers copied"
else
    warn "no wallpapers in repo — add them to ~/Pictures/Fonditos manually"
fi

# Default shell
section "Setting zsh as default shell"
if [ "$SHELL" != "$(which zsh)" ]; then
    chsh -s "$(which zsh)"
    success "default shell set to zsh (takes effect on next login)"
else
    success "zsh is already default"
fi

# Done
echo -e "\n${PINK}Done! :3${NC}"
echo ""
echo -e "  Things to do manually:"
echo -e "  ${YELLOW}·${NC} Add your gif to ~/.config/quickshell/assets/gifs/ (rename to the name of the gif).gif"
echo -e "  ${YELLOW}·${NC} Set up Plymouth and SDDM"
echo -e "  ${YELLOW}·${NC} Install Catppuccin GTK + cursor themes"
echo -e "  ${YELLOW}·${NC} Log out and log back in for zsh to take effect"
echo ""
echo -e "  ${GREEN}enjoy your setup! <3${NC}"
echo ""