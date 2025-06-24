#!/bin/bash
cliphist list | wofi --dmenu --prompt "Clipboard" | cliphist decode | wl-copy
