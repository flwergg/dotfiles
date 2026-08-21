#!/bin/bash
INTERVAL=1800
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"$SCRIPT_DIR/change_wallpaper_once.sh"

while true; do
    sleep $INTERVAL
    "$SCRIPT_DIR/change_wallpaper_once.sh"
done
