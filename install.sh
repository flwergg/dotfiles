#!/bin/bash

# Get the absolute path of the dotfiles repo
DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
HOME_DIR="$HOME"

echo "🔗 Creating symbolic links from $DOTFILES_DIR to $HOME_DIR"

# Symlink config files and folders
ln -sf "$DOTFILES_DIR/.bashrc" "$HOME_DIR/.bashrc"
ln -sf "$DOTFILES_DIR/.config" "$HOME_DIR/.config"

# Copy wallpapers
WALLPAPER_DIR="$HOME_DIR/Pictures/Fonditos"
mkdir -p "$WALLPAPER_DIR"
cp -r "$DOTFILES_DIR/Wallpapers/"* "$WALLPAPER_DIR/"

echo "🖼️ Wallpapers copied to $WALLPAPER_DIR"
echo "✅ Setup complete."
