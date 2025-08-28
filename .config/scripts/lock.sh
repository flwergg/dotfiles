#!/bin/bash

WALLPAPER=$(sed -n '2p' ~/.cache/swww/eDP-1)

# If the wallpaper file does not exist, use a default wallpaper
if [[ ! -f "$WALLPAPER" ]]; then
  WALLPAPER="/Pictures/Wallpaper/sailormoon2.jpg"
fi

# Play a sound when locking the screen
paplay ~/.config/sounds/lock.wav &

swaylock \
  --effect-blur 7x5 \
  --clock \
  --timestr "%H:%M" \
  --datestr "Hi, $USER <3" \
  --indicator \
  --indicator-radius 120 \
  --indicator-thickness 12 \
  --ring-color f5c2e7 \
  --line-color f5c2e7 \
  --inside-color 1e1e2e \
  --text-color f5c2e7 \
  --separator-color 1e1e2e \
  --ring-ver-color f5c2e7 \
  --ring-clear-color f5c2e7 \
  --ring-wrong-color f38ba8 \
  --inside-wrong-color 1e1e2e \
  --text-wrong-color f38ba8 \
  --image "$WALLPAPER" 
  --grace 2 --grace-no-mouse --grace-no-touch
