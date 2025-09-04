#!/bin/bash

# Get script directory (root kit directory)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIT_DIR="$SCRIPT_DIR"

# Source window manager detection
source "$SCRIPT_DIR/detect_wm.sh"

# Detect window manager
WM=$(detect_window_manager)
echo "Detected window manager: $WM"

# Configuration directories with fallbacks
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
WALLPAPER_SOURCE="${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}"

# Copy common config files to kit directory
[ -f "$CONFIG_DIR/kitty/kitty.conf" ] && cp "$CONFIG_DIR/kitty/kitty.conf" "$KIT_DIR/terminal-shell/kitty.conf"
[ -f "$HOME/.bashrc" ] && cp "$HOME/.bashrc" "$KIT_DIR/terminal-shell/bashrc"
[ -f "$CONFIG_DIR/nvim/init.vim" ] && cp "$CONFIG_DIR/nvim/init.vim" "$KIT_DIR/terminal-shell/init.vim"

# Copy window manager specific configs
case "$WM" in
    "hyprland")
        [ -f "$CONFIG_DIR/hypr/hyprland.conf" ] && cp "$CONFIG_DIR/hypr/hyprland.conf" "$KIT_DIR/hyprland-ecosystem/hyprland.conf"
        [ -f "$CONFIG_DIR/hypr/hyprlock.conf" ] && cp "$CONFIG_DIR/hypr/hyprlock.conf" "$KIT_DIR/hyprland-ecosystem/hyprlock.conf"
        [ -f "$CONFIG_DIR/waybar/config" ] && cp "$CONFIG_DIR/waybar/config" "$KIT_DIR/hyprland-ecosystem/waybar-config"
        [ -f "$CONFIG_DIR/waybar/style.css" ] && cp "$CONFIG_DIR/waybar/style.css" "$KIT_DIR/hyprland-ecosystem/waybar-style.css"
        [ -f "$CONFIG_DIR/mako/config" ] && cp "$CONFIG_DIR/mako/config" "$KIT_DIR/hyprland-ecosystem/mako-config"
        ;;
    "i3")
        [ -f "$CONFIG_DIR/i3/config" ] && cp "$CONFIG_DIR/i3/config" "$KIT_DIR/i3-ecosystem/i3-config"
        [ -f "$CONFIG_DIR/i3blocks/config" ] && cp "$CONFIG_DIR/i3blocks/config" "$KIT_DIR/i3-ecosystem/i3blocks-config"
        [ -f "$CONFIG_DIR/dunst/dunstrc" ] && cp "$CONFIG_DIR/dunst/dunstrc" "$KIT_DIR/i3-ecosystem/dunstrc"
        ;;
esac

# Sync wallpapers
if [ -d "$WALLPAPER_SOURCE" ]; then
    mkdir -p "$KIT_DIR/assets/wallpapers"
    cp "$WALLPAPER_SOURCE"/* "$KIT_DIR/assets/wallpapers/" 2>/dev/null || echo "Warning: No wallpapers found to sync"
else
    echo "Warning: $WALLPAPER_SOURCE directory not found"
fi

echo "Config files and wallpapers synced to current directory for $WM"