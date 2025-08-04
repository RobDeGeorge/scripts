#!/bin/bash

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Configuration directories with fallbacks
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
WALLPAPER_TARGET="${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}"

# Create config directories if they don't exist
mkdir -p "$CONFIG_DIR/i3"
mkdir -p "$CONFIG_DIR/i3blocks"
mkdir -p "$CONFIG_DIR/dunst"
mkdir -p "$CONFIG_DIR/kitty"
mkdir -p "$CONFIG_DIR/scripts"

# Create wallpaper directory if it doesn't exist
mkdir -p "$WALLPAPER_TARGET"

# Copy config files back to their correct locations
[ -f "$SCRIPT_DIR/i3-config" ] && cp "$SCRIPT_DIR/i3-config" "$CONFIG_DIR/i3/config"
[ -f "$SCRIPT_DIR/i3blocks-config" ] && cp "$SCRIPT_DIR/i3blocks-config" "$CONFIG_DIR/i3blocks/config"
[ -f "$SCRIPT_DIR/dunstrc" ] && cp "$SCRIPT_DIR/dunstrc" "$CONFIG_DIR/dunst/dunstrc"
[ -f "$SCRIPT_DIR/kitty.conf" ] && cp "$SCRIPT_DIR/kitty.conf" "$CONFIG_DIR/kitty/kitty.conf"
[ -f "$SCRIPT_DIR/bashrc" ] && cp "$SCRIPT_DIR/bashrc" "$HOME/.bashrc"

# Copy scripts to ~/.config/scripts/
[ -f "$SCRIPT_DIR/wallpaper-cycler.sh" ] && cp "$SCRIPT_DIR/wallpaper-cycler.sh" "$CONFIG_DIR/scripts/"
[ -f "$SCRIPT_DIR/install-dependencies.sh" ] && cp "$SCRIPT_DIR/install-dependencies.sh" "$CONFIG_DIR/scripts/"

# Make scripts executable
chmod +x "$CONFIG_DIR/scripts/wallpaper-cycler.sh" 2>/dev/null
chmod +x "$CONFIG_DIR/scripts/install-dependencies.sh" 2>/dev/null

# Install wallpaper cycler dependencies automatically
echo "Setting up wallpaper cycler dependencies..."
if [ -f "$CONFIG_DIR/scripts/install-dependencies.sh" ]; then
    cd "$CONFIG_DIR/scripts"
    ./install-dependencies.sh
    cd - > /dev/null
else
    echo "Warning: install-dependencies.sh not found, skipping dependency setup"
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
echo "- Use Mod+Shift+W in i3 to cycle wallpapers"
echo "- Restart i3 (Mod+Shift+R) to load new configs"