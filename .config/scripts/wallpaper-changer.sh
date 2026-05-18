#!/bin/bash
WALLPAPER_DIR="$HOME/Pictures/Fonditos" 
INTERVAL=1800

selected_path=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.gif' -o -iname '*.png' -o -iname '*.webp' \) ! -name ".*" | shuf -n1)

if [ -f "$selected_path" ]; then
    quickshell ipc call randomwallpaper apply "$selected_path"
fi
