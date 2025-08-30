#!/bin/bash

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
mkdir -p "$CONFIG_DIR/scripts"
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
[ -f "$SCRIPT_DIR/kitty.conf" ] && cp "$SCRIPT_DIR/kitty.conf" "$CONFIG_DIR/kitty/kitty.conf"
[ -f "$SCRIPT_DIR/bashrc" ] && cp "$SCRIPT_DIR/bashrc" "$HOME/.bashrc"

# Copy window manager specific configs
case "$WM" in
    "hyprland")
        [ -f "$SCRIPT_DIR/hyprland.conf" ] && cp "$SCRIPT_DIR/hyprland.conf" "$CONFIG_DIR/hypr/hyprland.conf"
        [ -f "$SCRIPT_DIR/hyprlock.conf" ] && cp "$SCRIPT_DIR/hyprlock.conf" "$CONFIG_DIR/hypr/hyprlock.conf"
        [ -f "$SCRIPT_DIR/waybar-config" ] && cp "$SCRIPT_DIR/waybar-config" "$CONFIG_DIR/waybar/config"
        [ -f "$SCRIPT_DIR/waybar-style.css" ] && cp "$SCRIPT_DIR/waybar-style.css" "$CONFIG_DIR/waybar/style.css"
        [ -f "$SCRIPT_DIR/mako-config" ] && cp "$SCRIPT_DIR/mako-config" "$CONFIG_DIR/mako/config"
        ;;
    "i3")
        [ -f "$SCRIPT_DIR/i3-config" ] && cp "$SCRIPT_DIR/i3-config" "$CONFIG_DIR/i3/config"
        [ -f "$SCRIPT_DIR/i3blocks-config" ] && cp "$SCRIPT_DIR/i3blocks-config" "$CONFIG_DIR/i3blocks/config"
        [ -f "$SCRIPT_DIR/dunstrc" ] && cp "$SCRIPT_DIR/dunstrc" "$CONFIG_DIR/dunst/dunstrc"
        ;;
esac

# Copy scripts to ~/.config/scripts/
[ -f "$SCRIPT_DIR/wallpaper-cycler.sh" ] && cp "$SCRIPT_DIR/wallpaper-cycler.sh" "$CONFIG_DIR/scripts/"
[ -f "$SCRIPT_DIR/startup-wallpaper.sh" ] && cp "$SCRIPT_DIR/startup-wallpaper.sh" "$CONFIG_DIR/scripts/"
[ -f "$SCRIPT_DIR/color_processor.py" ] && cp "$SCRIPT_DIR/color_processor.py" "$CONFIG_DIR/scripts/"
[ -f "$SCRIPT_DIR/install-dependencies.sh" ] && cp "$SCRIPT_DIR/install-dependencies.sh" "$CONFIG_DIR/scripts/"
[ -f "$SCRIPT_DIR/detect_wm.sh" ] && cp "$SCRIPT_DIR/detect_wm.sh" "$CONFIG_DIR/scripts/"

# Make scripts executable
chmod +x "$CONFIG_DIR/scripts/wallpaper-cycler.sh" 2>/dev/null
chmod +x "$CONFIG_DIR/scripts/startup-wallpaper.sh" 2>/dev/null
chmod +x "$CONFIG_DIR/scripts/color_processor.py" 2>/dev/null
chmod +x "$CONFIG_DIR/scripts/install-dependencies.sh" 2>/dev/null
chmod +x "$CONFIG_DIR/scripts/detect_wm.sh" 2>/dev/null

# Copy wallpaper-venv directory if it exists
if [ -d "$SCRIPT_DIR/wallpaper-venv" ] && [ ! -d "$CONFIG_DIR/scripts/wallpaper-venv" ]; then
    echo "Copying Python virtual environment..."
    cp -r "$SCRIPT_DIR/wallpaper-venv" "$CONFIG_DIR/scripts/"
fi

# Install wallpaper cycler dependencies only if not skipping
if [ "$SKIP_DEPS" = "false" ]; then
    echo "Setting up wallpaper cycler dependencies..."
    if [ -f "$CONFIG_DIR/scripts/install-dependencies.sh" ]; then
        cd "$CONFIG_DIR/scripts"
        ./install-dependencies.sh
        cd - > /dev/null
    else
        echo "Warning: install-dependencies.sh not found, skipping dependency setup"
    fi
else
    echo "Skipping dependency installation (--skip-deps flag)"
fi

# Restore wallpapers with error handling
if [ -d "$SCRIPT_DIR/wallpapers" ]; then
    if [ "$(ls -A "$SCRIPT_DIR/wallpapers" 2>/dev/null)" ]; then
        cp "$SCRIPT_DIR/wallpapers"/* "$WALLPAPER_TARGET/" 2>/dev/null || echo "Warning: Failed to copy some wallpapers"
        echo "Wallpapers restored to $WALLPAPER_TARGET/"
    else
        echo "Warning: wallpapers directory is empty"
    fi
else
    echo "Warning: $SCRIPT_DIR/wallpapers directory not found - skipping wallpaper restoration"
fi

echo "Config files restored to ~/.config/"
echo ""
echo "=== Setup Complete! ==="
echo "✓ Config files restored"
echo "✓ Wallpapers installed"  
echo "✓ Dependencies installed"
echo "✓ Scripts ready at ~/.config/scripts/"
echo ""
echo "You can now:"
echo "- Run ~/.config/scripts/wallpaper-cycler.sh to test"
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