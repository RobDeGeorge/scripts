#!/bin/bash

# Window Manager Detection Library
# Detects which window manager is currently running or installed

detect_window_manager() {
    # Check currently running window manager
    if [ -n "$WAYLAND_DISPLAY" ]; then
        # Wayland session
        if pgrep -x "Hyprland" >/dev/null 2>&1 || pgrep -x "hyprland" >/dev/null 2>&1; then
            echo "hyprland"
            return 0
        elif pgrep -x "sway" >/dev/null 2>&1; then
            echo "sway"
            return 0
        fi
    else
        # X11 session
        if pgrep -x "i3" >/dev/null 2>&1; then
            echo "i3"
            return 0
        elif pgrep -x "bspwm" >/dev/null 2>&1; then
            echo "bspwm"
            return 0
        fi
    fi
    
    # Fallback: check which configs exist
    if [ -f "$HOME/.config/hypr/hyprland.conf" ]; then
        echo "hyprland"
        return 0
    elif [ -f "$HOME/.config/i3/config" ]; then
        echo "i3"
        return 0
    fi
    
    # Final fallback: check session type
    case "$XDG_SESSION_TYPE" in
        "wayland")
            echo "hyprland"  # Assume Hyprland for Wayland
            ;;
        "x11")
            echo "i3"        # Assume i3 for X11
            ;;
        *)
            echo "unknown"
            return 1
            ;;
    esac
}

# Get window manager specific commands
get_wm_commands() {
    local wm="$1"
    
    case "$wm" in
        "hyprland")
            echo "RELOAD_CMD=hyprctl reload"
            echo "WALLPAPER_CMD=hyprpaper"
            echo "NOTIFICATION_CMD=mako"
            echo "TERMINAL_CMD=kitty"
            echo "BAR_CMD=waybar"
            ;;
        "i3")
            echo "RELOAD_CMD=i3-msg reload"
            echo "WALLPAPER_CMD=xwallpaper"
            echo "NOTIFICATION_CMD=dunst"
            echo "TERMINAL_CMD=kitty"
            echo "BAR_CMD=i3blocks"
            ;;
        *)
            echo "RELOAD_CMD=echo"
            echo "WALLPAPER_CMD=echo"
            echo "NOTIFICATION_CMD=echo"
            echo "TERMINAL_CMD=kitty"
            echo "BAR_CMD=echo"
            ;;
    esac
}

# Get config paths for window manager
get_config_paths() {
    local wm="$1"
    local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
    
    case "$wm" in
        "hyprland")
            echo "WM_CONFIG=$config_dir/hypr/hyprland.conf"
            echo "BAR_CONFIG=$config_dir/waybar/config"
            echo "BAR_STYLE_CONFIG=$config_dir/waybar/style.css"
            echo "NOTIFICATION_CONFIG=$config_dir/mako/config"
            echo "TERMINAL_CONFIG=$config_dir/kitty/kitty.conf"
            ;;
        "i3")
            echo "WM_CONFIG=$config_dir/i3/config"
            echo "BAR_CONFIG=$config_dir/i3blocks/config"
            echo "BAR_STYLE_CONFIG="
            echo "NOTIFICATION_CONFIG=$config_dir/dunst/dunstrc"
            echo "TERMINAL_CONFIG=$config_dir/kitty/kitty.conf"
            ;;
        *)
            echo "WM_CONFIG="
            echo "BAR_CONFIG="
            echo "BAR_STYLE_CONFIG="
            echo "NOTIFICATION_CONFIG="
            echo "TERMINAL_CONFIG=$config_dir/kitty/kitty.conf"
            ;;
    esac
}

# Get package names for window manager
get_wm_packages() {
    local wm="$1"
    local pm="$2"
    
    case "$wm" in
        "hyprland")
            case "$pm" in
                "apt")
                    echo "hyprland waybar mako-notifier hyprpaper kitty"
                    ;;
                "pacman")
                    echo "hyprland waybar mako hyprpaper kitty"
                    ;;
                "dnf"|"yum")
                    echo "hyprland waybar mako hyprpaper kitty"
                    ;;
                *)
                    echo "hyprland waybar mako hyprpaper kitty"
                    ;;
            esac
            ;;
        "i3")
            case "$pm" in
                "apt")
                    echo "i3-wm i3blocks dunst xwallpaper kitty"
                    ;;
                "pacman")
                    echo "i3-wm i3blocks dunst xwallpaper kitty"
                    ;;
                "dnf"|"yum")
                    echo "i3 i3blocks dunst xwallpaper kitty"
                    ;;
                *)
                    echo "i3 i3blocks dunst xwallpaper kitty"
                    ;;
            esac
            ;;
        *)
            echo ""
            ;;
    esac
}

# Export functions if sourced
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    export -f detect_window_manager
    export -f get_wm_commands
    export -f get_config_paths
    export -f get_wm_packages
fi