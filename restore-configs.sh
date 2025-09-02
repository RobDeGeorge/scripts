#!/bin/bash

# Get script directory (root kit directory)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIT_DIR="$SCRIPT_DIR"

# Source window manager detection
source "$SCRIPT_DIR/detect_wm.sh"

# Parse arguments
SKIP_DEPS=false
if [[ "$1" == "--skip-deps" ]]; then
    SKIP_DEPS=true
fi

# Detect window manager
WM=$(detect_window_manager)
echo "Detected window manager: $WM"

# Configuration directories with fallbacks
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
WALLPAPER_TARGET="${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}"

# Create config directories based on window manager
mkdir -p "$CONFIG_DIR/kitty"
mkdir -p ~/.cache/betterlockscreen/current

case "$WM" in
    "hyprland")
        mkdir -p "$CONFIG_DIR/hypr"
        mkdir -p "$CONFIG_DIR/waybar"
        mkdir -p "$CONFIG_DIR/mako"
        ;;
    "i3")
        mkdir -p "$CONFIG_DIR/i3"
        mkdir -p "$CONFIG_DIR/i3blocks"
        mkdir -p "$CONFIG_DIR/dunst"
        ;;
esac

# Create wallpaper directory if it doesn't exist
mkdir -p "$WALLPAPER_TARGET"


# Copy config files back to their correct locations
echo "Copying config files for $WM..."

# Copy common configs
[ -f "$KIT_DIR/terminal-shell/kitty.conf" ] && cp "$KIT_DIR/terminal-shell/kitty.conf" "$CONFIG_DIR/kitty/kitty.conf"
[ -f "$KIT_DIR/terminal-shell/bashrc" ] && cp "$KIT_DIR/terminal-shell/bashrc" "$HOME/.bashrc"

# Copy window manager specific configs
case "$WM" in
    "hyprland")
        [ -f "$KIT_DIR/hyprland-ecosystem/hyprland.conf" ] && cp "$KIT_DIR/hyprland-ecosystem/hyprland.conf" "$CONFIG_DIR/hypr/hyprland.conf"
        [ -f "$KIT_DIR/hyprland-ecosystem/hyprlock.conf" ] && cp "$KIT_DIR/hyprland-ecosystem/hyprlock.conf" "$CONFIG_DIR/hypr/hyprlock.conf"
        [ -f "$KIT_DIR/hyprland-ecosystem/waybar-config" ] && cp "$KIT_DIR/hyprland-ecosystem/waybar-config" "$CONFIG_DIR/waybar/config"
        [ -f "$KIT_DIR/hyprland-ecosystem/waybar-style.css" ] && cp "$KIT_DIR/hyprland-ecosystem/waybar-style.css" "$CONFIG_DIR/waybar/style.css"
        [ -f "$KIT_DIR/hyprland-ecosystem/mako-config" ] && cp "$KIT_DIR/hyprland-ecosystem/mako-config" "$CONFIG_DIR/mako/config"
        ;;
    "i3")
        [ -f "$KIT_DIR/i3-ecosystem/i3-config" ] && cp "$KIT_DIR/i3-ecosystem/i3-config" "$CONFIG_DIR/i3/config"
        [ -f "$KIT_DIR/i3-ecosystem/i3blocks-config" ] && cp "$KIT_DIR/i3-ecosystem/i3blocks-config" "$CONFIG_DIR/i3blocks/config"
        [ -f "$KIT_DIR/i3-ecosystem/dunstrc" ] && cp "$KIT_DIR/i3-ecosystem/dunstrc" "$CONFIG_DIR/dunst/dunstrc"
        ;;
esac

# Install wallpaper cycler dependencies only if not skipping
if [ "$SKIP_DEPS" = "false" ]; then
    echo "Setting up wallpaper cycler dependencies..."
    cd "$SCRIPT_DIR"
    ./install-dependencies.sh
    cd - > /dev/null
else
    echo "Skipping dependency installation (--skip-deps flag)"
fi

# Restore wallpapers with error handling
if [ -d "$KIT_DIR/assets/wallpapers" ]; then
    if [ "$(ls -A "$KIT_DIR/assets/wallpapers" 2>/dev/null)" ]; then
        cp "$KIT_DIR/assets/wallpapers"/* "$WALLPAPER_TARGET/" 2>/dev/null || echo "Warning: Failed to copy some wallpapers"
        echo "Wallpapers restored to $WALLPAPER_TARGET/"
    else
        echo "Warning: wallpapers directory is empty"
    fi
else
    echo "Warning: $KIT_DIR/assets/wallpapers directory not found - skipping wallpaper restoration"
fi

echo "Config files restored to ~/.config/"
echo ""
echo "=== Setup Complete! ==="
echo "✓ Config files restored"
echo "✓ Wallpapers installed"  
echo "✓ Dependencies installed"
echo "✓ Scripts ready in kit directory"
echo ""
echo "You can now:"
echo "- Run $SCRIPT_DIR/theming-engine/wallpaper-cycler.sh to test"
case "$WM" in
    "hyprland")
        echo "- Use Mod+Shift+W in Hyprland to cycle wallpapers"
        echo "- Restart Hyprland or reload config to apply changes"
        ;;
    "i3")
        echo "- Use Mod+Shift+W in i3 to cycle wallpapers"
        echo "- Restart i3 (Mod+Shift+R) to load new configs"
        ;;
esac