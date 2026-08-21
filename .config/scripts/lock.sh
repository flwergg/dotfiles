#!/bin/bash

WALLPAPER="$HOME/Pictures/Fonditos/current"

# Play a sound when locking the screen
paplay ~/.config/sounds/lock.wav &

swaylock \
  --effect-blur 7x5 \
  --effect-vignette 0.5:0.5 \
  --clock \
  --timestr "%H:%M" \
  --datestr "Hi, $USER <3" \
  --indicator \
  --indicator-radius 120 \
  --indicator-thickness 12 \
  --indicator-caps-lock \
  --separator-color 00000000 \
  --ring-color f5c2e7 \
  --line-color 00000000 \
  --inside-color 1e1e2e \
  --text-color f5c2e7 \
  --ring-ver-color 89b4fa \
  --line-ver-color 00000000 \
  --inside-ver-color 1e1e2e \
  --text-ver-color 89b4fa \
  --ring-clear-color a6e3a1 \
  --line-clear-color 00000000 \
  --inside-clear-color 1e1e2e \
  --text-clear-color a6e3a1 \
  --ring-wrong-color f38ba8 \
  --line-wrong-color 00000000 \
  --inside-wrong-color 1e1e2e \
  --text-wrong-color f38ba8 \
  --key-hl-color a6e3a1 \
  --bs-hl-color eba0ac \
  --caps-lock-key-hl-color f9e2af \
  --caps-lock-bs-hl-color eba0ac \
  --image "$WALLPAPER" \
  --grace 0 --grace-no-mouse --grace-no-touch