#!/bin/bash

# Create config directories if they don't exist
mkdir -p ~/.config/i3
mkdir -p ~/.config/i3blocks
mkdir -p ~/.config/dunst
mkdir -p ~/.config/kitty

# Create Pictures/Wallpapers directory if it doesn't exist
mkdir -p ~/Pictures/Wallpapers

# Copy config files back to their correct locations
cp ./i3-config ~/.config/i3/config
cp ./i3blocks-config ~/.config/i3blocks/config
cp ./dunstrc ~/.config/dunst/dunstrc
cp ./kitty.conf ~/.config/kitty/kitty.conf
cp ./bashrc ~/.bashrc

# Restore wallpapers with error handling
if [ -d ./wallpapers ]; then
    if [ "$(ls -A ./wallpapers 2>/dev/null)" ]; then
        cp ./wallpapers/* ~/Pictures/Wallpapers/ 2>/dev/null || echo "Warning: Failed to copy some wallpapers"
        echo "Wallpapers restored to ~/Pictures/Wallpapers/"
    else
        echo "Warning: wallpapers directory is empty"
    fi
else
    echo "Warning: ./wallpapers directory not found - skipping wallpaper restoration"
fi

echo "Config files restored to ~/.config/"