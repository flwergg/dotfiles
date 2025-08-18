#!/bin/bash

# Get the absolute path of the dotfiles repo
DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
HOME_DIR="$HOME"

echo "Copying dotfiles from $DOTFILES_DIR to $HOME_DIR"

# Copy config files and folders (overwriting if exist)
cp -r "$DOTFILES_DIR/.bashrc" "$HOME_DIR/.bashrc"
cp -r "$DOTFILES_DIR/.config" "$HOME_DIR/.config"

# Copy wallpapers
WALLPAPER_DIR="$HOME_DIR/Pictures/Fonditos"
mkdir -p "$WALLPAPER_DIR"
cp -r "$DOTFILES_DIR/Wallpapers/"* "$WALLPAPER_DIR/"

echo "Wallpapers copied to $WALLPAPER_DIR"
echo "Setup complete <3"
