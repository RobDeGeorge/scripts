#!/bin/bash

# Copy config files to current directory
cp ~/.config/i3/config ./i3-config
cp ~/.config/i3blocks/config ./i3blocks-config
cp ~/.config/dunst/dunstrc ./dunstrc
cp ~/.config/kitty/kitty.conf ./kitty.conf
cp ~/.bashrc ./bashrc

# Sync wallpapers
if [ -d ~/Pictures/Wallpapers ]; then
    mkdir -p ./wallpapers
    cp ~/Pictures/Wallpapers/* ./wallpapers/ 2>/dev/null || echo "Warning: No wallpapers found to sync"
else
    echo "Warning: ~/Pictures/Wallpapers directory not found"
fi

echo "Config files and wallpapers synced to current directory"