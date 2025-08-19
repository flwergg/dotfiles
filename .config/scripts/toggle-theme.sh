#!/bin/bash

# GTK themes and cursors
THEME_LIGHT="catppuccin-latte-flamingo-standard+default"
CURSOR_LIGHT="catppuccin-latte-flamingo-cursors"

THEME_DARK="catppuccin-mocha-flamingo-standard+default"
CURSOR_DARK="catppuccin-mocha-flamingo-cursors"

INDEX_PATH="$HOME/.icons/default/index.theme"

# Verify current theme
CURRENT_THEME=$(gsettings get org.gnome.desktop.interface gtk-theme | tr -d "'")

if [[ "$CURRENT_THEME" == "$THEME_LIGHT" ]]; then
    # Change to dark
    gsettings set org.gnome.desktop.interface gtk-theme "$THEME_DARK"
    gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark"
    gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR_DARK"
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    echo -e "[Icon Theme]\nInherits=$CURSOR_DARK" > "$INDEX_PATH"
    hyprctl setcursor "$CURSOR_DARK" 24
    notify-send "🌙 Night Mode On"

else
    # Change to light
    gsettings set org.gnome.desktop.interface gtk-theme "$THEME_LIGHT"
    gsettings set org.gnome.desktop.interface icon-theme "Papirus-Light"
    gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR_LIGHT"
    gsettings set org.gnome.desktop.interface color-scheme 'default'
    echo -e "[Icon Theme]\nInherits=$CURSOR_LIGHT" > "$INDEX_PATH"
    hyprctl setcursor "$CURSOR_LIGHT" 24
    notify-send "🌞 Light Mode On"
    
fi
