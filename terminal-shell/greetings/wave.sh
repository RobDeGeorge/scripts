#!/bin/bash

# Animated ocean wave greeting

system_greeting() {
    local blue1="\033[38;2;20;60;90m"
    local blue2="\033[38;2;30;90;130m"
    local blue3="\033[38;2;50;120;160m"
    local blue4="\033[38;2;80;150;190m"
    local foam="\033[38;2;200;220;230m"
    local reset="\033[0m"

    # Get terminal width, cap at 80
    local width=$(tput cols)
    [[ $width -gt 80 ]] && width=80

    # Wave characters
    local w1="▁"
    local w2="▂"
    local w3="▃"
    local w4="▄"
    local w5="▅"
    local w6="▆"

    # Hide cursor during animation
    tput civis

    # Animation frames
    local frames=12
    local delay=0.12

    for frame in $(seq 0 $frames); do
        # Move cursor to top
        echo -ne "\033[H"

        echo ""

        # Draw 4 wave layers with phase offsets
        for layer in 1 2 3 4; do
            local line=""
            local phase=$((frame + layer * 2))

            # Pick color based on layer
            local color
            case $layer in
                1) color=$blue4 ;;
                2) color=$blue3 ;;
                3) color=$blue2 ;;
                4) color=$blue1 ;;
            esac

            for ((x=0; x<width; x++)); do
                # Create wave pattern using modulo
                local pos=$(( (x + phase) % 12 ))
                local char
                case $pos in
                    0|11) char=$w1 ;;
                    1|10) char=$w2 ;;
                    2|9)  char=$w3 ;;
                    3|8)  char=$w4 ;;
                    4|7)  char=$w5 ;;
                    5|6)  char=$w6 ;;
                esac

                # Add foam to top layer occasionally
                if [[ $layer -eq 1 ]] && [[ $pos -eq 5 || $pos -eq 6 ]] && (( RANDOM % 3 == 0 )); then
                    line+="${foam}${char}"
                else
                    line+="${color}${char}"
                fi
            done
            echo -e "${line}${reset}"
        done

        sleep $delay
    done

    # Show cursor again
    tput cnorm

    # Final static frame with a message
    echo ""
}

system_greeting
