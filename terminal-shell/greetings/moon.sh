#!/bin/bash

# Moon phase greeting with countdowns to notable lunar events

system_greeting() {
    # Subtle moon colors
    local moon_bright="\033[38;2;255;255;240m"    # Ivory
    local moon_shadow="\033[38;2;60;60;70m"       # Deep shadow
    local text_dim="\033[38;2;140;140;160m"       # Muted text
    local text_accent="\033[38;2;200;200;220m"    # Brighter text
    local reset="\033[0m"

    # Calculate moon phase using synodic month (29.53059 days)
    # Reference: Jan 11, 2024 was a new moon
    local ref_new_moon=1704931200  # Jan 11, 2024 00:00 UTC
    local synodic_seconds=2551443  # 29.53059 days in seconds
    local now=$(date +%s)
    local since_new=$(( (now - ref_new_moon) % synodic_seconds ))

    # Phase percentage (0-1000 for precision, representing 0-100%)
    local phase_pct_1000=$(( since_new * 1000 / synodic_seconds ))

    # Determine phase index (0-7), each phase is 12.5% = 125 in our scale
    local phase_idx=$(( phase_pct_1000 / 125 ))
    [[ $phase_idx -gt 7 ]] && phase_idx=7

    local phase_names=("New Moon" "Waxing Crescent" "First Quarter" "Waxing Gibbous" "Full Moon" "Waning Gibbous" "Last Quarter" "Waning Crescent")
    local phase_name="${phase_names[$phase_idx]}"

    # Days until next full moon (at 50% = 500 in our scale)
    local days_to_full
    if (( phase_pct_1000 < 500 )); then
        days_to_full=$(( (500 - phase_pct_1000) * 2953 / 100000 ))
    else
        days_to_full=$(( (1000 - phase_pct_1000 + 500) * 2953 / 100000 ))
    fi
    [[ $days_to_full -eq 0 ]] && days_to_full=1

    # Days until next new moon (at 0%/100%)
    local days_to_new=$(( (1000 - phase_pct_1000) * 2953 / 100000 ))
    [[ $days_to_new -eq 0 ]] && days_to_new=1

    # Moon art - wider to compensate for terminal char aspect ratio (chars are ~2x tall as wide)
    local moon_art
    case $phase_idx in
        0) # New Moon
            moon_art=(
                "      ${moon_shadow}███████${reset}      "
                "   ${moon_shadow}█████████████${reset}   "
                "  ${moon_shadow}███████████████${reset}  "
                "  ${moon_shadow}███████████████${reset}  "
                "   ${moon_shadow}█████████████${reset}   "
                "      ${moon_shadow}███████${reset}      "
            ) ;;
        1) # Waxing Crescent
            moon_art=(
                "      ${moon_shadow}█████${moon_bright}██${reset}      "
                "   ${moon_shadow}████████${moon_bright}█████${reset}   "
                "  ${moon_shadow}█████████${moon_bright}██████${reset}  "
                "  ${moon_shadow}█████████${moon_bright}██████${reset}  "
                "   ${moon_shadow}████████${moon_bright}█████${reset}   "
                "      ${moon_shadow}█████${moon_bright}██${reset}      "
            ) ;;
        2) # First Quarter
            moon_art=(
                "      ${moon_shadow}███${moon_bright}████${reset}      "
                "   ${moon_shadow}██████${moon_bright}███████${reset}   "
                "  ${moon_shadow}███████${moon_bright}████████${reset}  "
                "  ${moon_shadow}███████${moon_bright}████████${reset}  "
                "   ${moon_shadow}██████${moon_bright}███████${reset}   "
                "      ${moon_shadow}███${moon_bright}████${reset}      "
            ) ;;
        3) # Waxing Gibbous
            moon_art=(
                "      ${moon_shadow}█${moon_bright}██████${reset}      "
                "   ${moon_shadow}██${moon_bright}███████████${reset}   "
                "  ${moon_shadow}██${moon_bright}█████████████${reset}  "
                "  ${moon_shadow}██${moon_bright}█████████████${reset}  "
                "   ${moon_shadow}██${moon_bright}███████████${reset}   "
                "      ${moon_shadow}█${moon_bright}██████${reset}      "
            ) ;;
        4) # Full Moon
            moon_art=(
                "      ${moon_bright}███████${reset}      "
                "   ${moon_bright}█████████████${reset}   "
                "  ${moon_bright}███████████████${reset}  "
                "  ${moon_bright}███████████████${reset}  "
                "   ${moon_bright}█████████████${reset}   "
                "      ${moon_bright}███████${reset}      "
            ) ;;
        5) # Waning Gibbous
            moon_art=(
                "      ${moon_bright}██████${moon_shadow}█${reset}      "
                "   ${moon_bright}███████████${moon_shadow}██${reset}   "
                "  ${moon_bright}█████████████${moon_shadow}██${reset}  "
                "  ${moon_bright}█████████████${moon_shadow}██${reset}  "
                "   ${moon_bright}███████████${moon_shadow}██${reset}   "
                "      ${moon_bright}██████${moon_shadow}█${reset}      "
            ) ;;
        6) # Last Quarter
            moon_art=(
                "      ${moon_bright}████${moon_shadow}███${reset}      "
                "   ${moon_bright}███████${moon_shadow}██████${reset}   "
                "  ${moon_bright}████████${moon_shadow}███████${reset}  "
                "  ${moon_bright}████████${moon_shadow}███████${reset}  "
                "   ${moon_bright}███████${moon_shadow}██████${reset}   "
                "      ${moon_bright}████${moon_shadow}███${reset}      "
            ) ;;
        7) # Waning Crescent
            moon_art=(
                "      ${moon_bright}██${moon_shadow}█████${reset}      "
                "   ${moon_bright}█████${moon_shadow}████████${reset}   "
                "  ${moon_bright}██████${moon_shadow}█████████${reset}  "
                "  ${moon_bright}██████${moon_shadow}█████████${reset}  "
                "   ${moon_bright}█████${moon_shadow}████████${reset}   "
                "      ${moon_bright}██${moon_shadow}█████${reset}      "
            ) ;;
    esac

    # Notable lunar events (update these periodically)
    local events=(
        "2025-03-14|Total Lunar Eclipse"
        "2025-05-26|Supermoon"
        "2025-09-07|Total Lunar Eclipse"
        "2025-10-06|Supermoon"
        "2025-12-31|Blue Moon"
        "2026-03-03|Total Lunar Eclipse"
        "2026-08-28|Partial Lunar Eclipse"
    )

    local today_sec=$(date +%s)
    local next_event=""
    local next_event_days=999

    for event in "${events[@]}"; do
        local event_date="${event%%|*}"
        local event_name="${event##*|}"
        local event_sec=$(date -d "$event_date" +%s 2>/dev/null)
        if [[ -n "$event_sec" ]] && (( event_sec > today_sec )); then
            local diff_days=$(( (event_sec - today_sec) / 86400 ))
            if (( diff_days < next_event_days )); then
                next_event_days=$diff_days
                next_event="$event_name"
            fi
        fi
    done

    # Build info lines to display alongside moon (6 lines to match art)
    local event_line=""
    if [[ -n "$next_event" ]] && (( next_event_days <= 90 )); then
        event_line="${text_dim}${next_event} in ${text_accent}${next_event_days}${text_dim}d${reset}"
    fi

    local info_lines=(
        "${text_accent}${phase_name}${reset}"
        ""
        "${text_dim}Full moon in ${text_accent}${days_to_full}${text_dim} days${reset}"
        "${text_dim}New moon in ${text_accent}${days_to_new}${text_dim} days${reset}"
        ""
        "${event_line}"
    )

    # Print moon art alongside info
    echo
    for i in {0..5}; do
        echo -e "  ${moon_art[$i]} ${info_lines[$i]:-}"
    done
    echo
}

system_greeting
