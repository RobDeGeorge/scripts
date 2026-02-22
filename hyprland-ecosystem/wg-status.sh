#!/bin/bash
# WireGuard + Samba mount status for Waybar

wg_up=false
mount_up=false

# Check WireGuard
if ip link show wg0 &>/dev/null; then
    wg_up=true
fi

# Check Samba mount
if mountpoint -q /mnt/wbsolutions 2>/dev/null; then
    mount_up=true
fi

# Build output
if $wg_up && $mount_up; then
    echo '{"text": "󰖂 WBS", "tooltip": "WireGuard: Connected\nDrive: /mnt/wbsolutions mounted", "class": "connected"}'
elif $wg_up; then
    echo '{"text": "󰖂 WBS 󰋊✗", "tooltip": "WireGuard: Connected\nDrive: NOT mounted", "class": "partial"}'
else
    echo '{"text": "󰖃 WBS", "tooltip": "WireGuard: Disconnected\nDrive: NOT mounted", "class": "disconnected"}'
fi
