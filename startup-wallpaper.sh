#!/bin/bash

# Startup wallpaper and theme initialization script
# This ensures a wallpaper is loaded and theme is applied on login

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}"

# Wait for desktop environment to be ready
sleep 2

# Check if wallpapers directory exists and has images
if [ ! -d "$WALLPAPER_DIR" ] || [ -z "$(ls -A "$WALLPAPER_DIR" 2>/dev/null)" ]; then
    echo "No wallpapers found in $WALLPAPER_DIR, skipping wallpaper setup" >&2
    exit 0
fi

# Get the first available wallpaper
FIRST_WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.bmp" \) | head -1)

if [ -n "$FIRST_WALLPAPER" ]; then
    echo "Loading startup wallpaper: $FIRST_WALLPAPER" >&2
    # Use specific wallpaper to ensure immediate loading
    "$SCRIPT_DIR/wallpaper-cycler.sh" --wallpaper "$FIRST_WALLPAPER"
else
    echo "No valid wallpaper files found, using default cycler" >&2
    # Fallback to default cycling
    "$SCRIPT_DIR/wallpaper-cycler.sh"
fi