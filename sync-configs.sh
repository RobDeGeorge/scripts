#!/bin/bash

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Configuration directories with fallbacks
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
WALLPAPER_SOURCE="${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}"

# Copy config files to script directory
[ -f "$CONFIG_DIR/i3/config" ] && cp "$CONFIG_DIR/i3/config" "$SCRIPT_DIR/i3-config"
[ -f "$CONFIG_DIR/i3blocks/config" ] && cp "$CONFIG_DIR/i3blocks/config" "$SCRIPT_DIR/i3blocks-config"
[ -f "$CONFIG_DIR/dunst/dunstrc" ] && cp "$CONFIG_DIR/dunst/dunstrc" "$SCRIPT_DIR/dunstrc"
[ -f "$CONFIG_DIR/kitty/kitty.conf" ] && cp "$CONFIG_DIR/kitty/kitty.conf" "$SCRIPT_DIR/kitty.conf"
[ -f "$HOME/.bashrc" ] && cp "$HOME/.bashrc" "$SCRIPT_DIR/bashrc"

# Sync wallpapers
if [ -d "$WALLPAPER_SOURCE" ]; then
    mkdir -p "$SCRIPT_DIR/wallpapers"
    cp "$WALLPAPER_SOURCE"/* "$SCRIPT_DIR/wallpapers/" 2>/dev/null || echo "Warning: No wallpapers found to sync"
else
    echo "Warning: $WALLPAPER_SOURCE directory not found"
fi

echo "Config files and wallpapers synced to current directory"