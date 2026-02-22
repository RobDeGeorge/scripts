#!/bin/bash
# Click handler for Waybar WireGuard/WBS module
# Brings up WireGuard if needed, then triggers the automount

# Check if WireGuard is up
if ! ip link show wg0 &>/dev/null; then
    # Use systemctl which has proper polkit integration
    systemctl start wg-quick@wg0
    if [ $? -ne 0 ]; then
        notify-send "WBS Drive" "Failed to start WireGuard — try: sudo systemctl start wg-quick@wg0" -u critical
        exit 1
    fi
    notify-send "WBS Drive" "WireGuard connected"
    sleep 2
fi

# Trigger the automount by accessing the mount point
if ! mountpoint -q /mnt/wbsolutions 2>/dev/null; then
    ls /mnt/wbsolutions &>/dev/null
    sleep 2
    if mountpoint -q /mnt/wbsolutions 2>/dev/null; then
        notify-send "WBS Drive" "Drive mounted successfully"
    else
        notify-send "WBS Drive" "Failed to mount drive — WireGuard may still be connecting" -u critical
        exit 1
    fi
else
    notify-send "WBS Drive" "Already connected"
fi
