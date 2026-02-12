#!/bin/bash

# Startup wallpaper and theme initialization script
# This ensures a wallpaper is loaded and theme is applied on login
# Also syncs local config changes back to the scripts folder

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIT_DIR="$(dirname "$SCRIPT_DIR")"
WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}"

# Force correct DBus session for OpenRazer communication (systemd user session)
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"

# Wait for desktop environment to be ready
sleep 2

# Sync local config changes back to the scripts folder
# This captures any modifications made since last login
if [ -x "$KIT_DIR/sync-configs.sh" ]; then
    echo "Syncing local configs to backpack..." >&2
    "$KIT_DIR/sync-configs.sh" >&2
fi

# Wait for openrazer-daemon to be ready (for keyboard RGB sync)
# The daemon may take a moment to initialize after login
if systemctl --user list-unit-files openrazer-daemon.service &>/dev/null; then
    echo "Waiting for openrazer-daemon..." >&2
    for i in {1..15}; do
        if systemctl --user is-active --quiet openrazer-daemon 2>/dev/null; then
            # Give the daemon a moment to fully initialize DBus interface
            sleep 2
            echo "openrazer-daemon is ready" >&2
            break
        fi
        sleep 1
    done
fi

# Check if wallpapers directory exists and has images
if [ ! -d "$WALLPAPER_DIR" ] || [ -z "$(ls -A "$WALLPAPER_DIR" 2>/dev/null)" ]; then
    echo "No wallpapers found in $WALLPAPER_DIR, skipping wallpaper setup" >&2
    exit 0
fi

# Get a random wallpaper
FIRST_WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.bmp" \) | shuf | head -1)

if [ -n "$FIRST_WALLPAPER" ]; then
    echo "Loading startup wallpaper: $FIRST_WALLPAPER" >&2
    # Use specific wallpaper to ensure immediate loading
    "$SCRIPT_DIR/wallpaper-cycler.sh" --wallpaper "$FIRST_WALLPAPER"
else
    echo "No valid wallpaper files found, using default cycler" >&2
    # Fallback to default cycling
    "$SCRIPT_DIR/wallpaper-cycler.sh"
fi