#!/bin/bash

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source window manager detection
source "$SCRIPT_DIR/detect_wm.sh"

# Detect window manager
WM=$(detect_window_manager)
echo "Detected window manager: $WM"

# Configuration directories with fallbacks
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
WALLPAPER_SOURCE="${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}"

# Copy common config files to script directory
[ -f "$CONFIG_DIR/kitty/kitty.conf" ] && cp "$CONFIG_DIR/kitty/kitty.conf" "$SCRIPT_DIR/kitty.conf"
[ -f "$HOME/.bashrc" ] && cp "$HOME/.bashrc" "$SCRIPT_DIR/bashrc"

# Copy window manager specific configs
case "$WM" in
    "hyprland")
        [ -f "$CONFIG_DIR/hypr/hyprland.conf" ] && cp "$CONFIG_DIR/hypr/hyprland.conf" "$SCRIPT_DIR/hyprland.conf"
        [ -f "$CONFIG_DIR/hypr/hyprlock.conf" ] && cp "$CONFIG_DIR/hypr/hyprlock.conf" "$SCRIPT_DIR/hyprlock.conf"
        [ -f "$CONFIG_DIR/waybar/config" ] && cp "$CONFIG_DIR/waybar/config" "$SCRIPT_DIR/waybar-config"
        [ -f "$CONFIG_DIR/waybar/style.css" ] && cp "$CONFIG_DIR/waybar/style.css" "$SCRIPT_DIR/waybar-style.css"
        [ -f "$CONFIG_DIR/mako/config" ] && cp "$CONFIG_DIR/mako/config" "$SCRIPT_DIR/mako-config"
        ;;
    "i3")
        [ -f "$CONFIG_DIR/i3/config" ] && cp "$CONFIG_DIR/i3/config" "$SCRIPT_DIR/i3-config"
        [ -f "$CONFIG_DIR/i3blocks/config" ] && cp "$CONFIG_DIR/i3blocks/config" "$SCRIPT_DIR/i3blocks-config"
        [ -f "$CONFIG_DIR/dunst/dunstrc" ] && cp "$CONFIG_DIR/dunst/dunstrc" "$SCRIPT_DIR/dunstrc"
        ;;
esac

# Sync wallpapers
if [ -d "$WALLPAPER_SOURCE" ]; then
    mkdir -p "$SCRIPT_DIR/wallpapers"
    cp "$WALLPAPER_SOURCE"/* "$SCRIPT_DIR/wallpapers/" 2>/dev/null || echo "Warning: No wallpapers found to sync"
else
    echo "Warning: $WALLPAPER_SOURCE directory not found"
fi

echo "Config files and wallpapers synced to current directory for $WM"