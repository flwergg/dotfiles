#!/bin/bash
WALLPAPER_DIR="$HOME/Pictures/Fonditos" 
INTERVAL=1800
INDEX_FILE="$HOME/.config/swww_index"

change_wallpaper() {
    # Create array with images sorted alphabetically
    mapfile -t WALLPAPERS < <(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.bmp" \) | sort)
    
    if [ ${#WALLPAPERS[@]} -eq 0 ]; then
        echo "$(date): Folder is empty $WALLPAPER_DIR"
        return
    fi
    
    # Read current index
    if [ -f "$INDEX_FILE" ]; then
        CURRENT_INDEX=$(cat "$INDEX_FILE")
    else
        CURRENT_INDEX=0
    fi
    
    # Verify if index is valid
    if [ "$CURRENT_INDEX" -ge "${#WALLPAPERS[@]}" ]; then
        CURRENT_INDEX=0
    fi
    
    # Get current wallpaper
    WALLPAPER="${WALLPAPERS[$CURRENT_INDEX]}"
    
    # Change wallpaper
    swww img "$WALLPAPER" --transition-type fade --transition-duration 2
    echo "$(date): Fondo #$CURRENT_INDEX: $(basename "$WALLPAPER")"
    
    # Save next index
    NEXT_INDEX=$(( (CURRENT_INDEX + 1) % ${#WALLPAPERS[@]} ))
    echo "$NEXT_INDEX" > "$INDEX_FILE"
}

change_wallpaper

while true; do
    sleep $INTERVAL
    change_wallpaper
done
