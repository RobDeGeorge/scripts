#!/bin/bash

# Copy config files to current directory
cp ~/.config/i3/config ./i3-config
cp ~/.config/i3blocks/config ./i3blocks-config
cp ~/.config/dunst/dunstrc ./dunstrc
cp ~/.config/kitty/kitty.conf ./kitty.conf
cp ~/.bashrc ./bashrc

echo "Config files synced to current directory"