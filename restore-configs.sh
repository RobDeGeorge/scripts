#!/bin/bash

# Create config directories if they don't exist
mkdir -p ~/.config/i3
mkdir -p ~/.config/i3blocks
mkdir -p ~/.config/dunst
mkdir -p ~/.config/kitty

# Copy config files back to their correct locations
cp ./i3-config ~/.config/i3/config
cp ./i3blocks-config ~/.config/i3blocks/config
cp ./dunstrc ~/.config/dunst/dunstrc
cp ./kitty.conf ~/.config/kitty/kitty.conf

echo "Config files restored to ~/.config/"