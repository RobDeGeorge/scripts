#!/bin/bash

# Minimal techy fetch greeting

system_greeting() {
    local dim="\033[38;2;180;180;190m"
    local accent="\033[38;2;220;225;230m"
    local bar_fill="\033[38;2;200;210;220m"
    local bar_empty="\033[38;2;80;85;95m"
    local reset="\033[0m"

    # Bar drawing function (width 10)
    draw_bar() {
        local pct=$1
        local width=10
        local filled=$(( pct * width / 100 ))
        local empty=$(( width - filled ))
        local bar="${bar_fill}"
        for ((i=0; i<filled; i++)); do bar+="█"; done
        bar+="${bar_empty}"
        for ((i=0; i<empty; i++)); do bar+="░"; done
        bar+="${reset}"
        echo -e "${bar}"
    }

    # Uptime
    local uptime=$(uptime -p 2>/dev/null | sed 's/up //' || echo "unknown")

    # Memory
    local mem_pct=$(free 2>/dev/null | awk '/Mem:/ {printf "%.0f", $3/$2*100}')
    [[ -z "$mem_pct" ]] && mem_pct=0
    local mem_bar=$(draw_bar $mem_pct)

    # Disk
    local disk_pct=$(df / 2>/dev/null | awk 'NR==2 {gsub("%",""); print $5}')
    [[ -z "$disk_pct" ]] && disk_pct=0
    local disk_bar=$(draw_bar $disk_pct)

    # Battery
    local bat_pct=""
    local bat_bar=""
    local bat_icon=""
    if [[ -f /sys/class/power_supply/BAT0/capacity ]]; then
        bat_pct=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null)
        local bat_status=$(cat /sys/class/power_supply/BAT0/status 2>/dev/null)
        [[ "$bat_status" == "Charging" ]] && bat_icon=" +"
        [[ "$bat_status" == "Discharging" ]] && bat_icon=" -"
    elif [[ -f /sys/class/power_supply/BAT1/capacity ]]; then
        bat_pct=$(cat /sys/class/power_supply/BAT1/capacity 2>/dev/null)
        local bat_status=$(cat /sys/class/power_supply/BAT1/status 2>/dev/null)
        [[ "$bat_status" == "Charging" ]] && bat_icon=" +"
        [[ "$bat_status" == "Discharging" ]] && bat_icon=" -"
    fi
    [[ -n "$bat_pct" ]] && bat_bar=$(draw_bar $bat_pct)

    # Date/time
    local now=$(date '+%a %b %d, %H:%M')

    # Kernel
    local kernel=$(uname -r | cut -d'-' -f1)

    echo ""
    echo -e "  ${dim}up${reset}    ${accent}${uptime}${reset}"
    echo -e "  ${dim}mem${reset}   ${mem_bar}  ${dim}${mem_pct}%${reset}"
    echo -e "  ${dim}disk${reset}  ${disk_bar}  ${dim}${disk_pct}%${reset}"
    [[ -n "$bat_pct" ]] && echo -e "  ${dim}bat${reset}   ${bat_bar}  ${dim}${bat_pct}%${bat_icon}${reset}"
    echo -e "  ${dim}kern${reset}  ${accent}${kernel}${reset}"
    echo ""
    echo -e "  ${dim}${now}${reset}"
    echo ""
}

system_greeting
