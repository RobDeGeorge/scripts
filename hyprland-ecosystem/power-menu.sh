#!/bin/bash
# Power menu for Waybar — uses wofi

choice=$(printf "⏻  Shutdown\n  Restart\n󰒲  Sleep\n󰍃  Logout" | wofi --dmenu --prompt "Power" --width 200 --height 200 --location 3 --yoffset 36 --xoffset -8 --cache-file /dev/null)

case "$choice" in
    "⏻  Shutdown") systemctl poweroff ;;
    "  Restart")  systemctl reboot ;;
    "󰒲  Sleep")    systemctl suspend ;;
    "󰍃  Logout")   hyprctl dispatch exit ;;
esac
