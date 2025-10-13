#!/bin/bash

# Constellation space scene greeting
system_greeting() {
    clear

    # Read current theme colors from kitty config
    current_bg=$(grep "^background" ~/.config/kitty/kitty.conf 2>/dev/null | head -1 | awk '{print $2}' | sed 's/#//')
    current_fg=$(grep "^foreground" ~/.config/kitty/kitty.conf 2>/dev/null | head -1 | awk '{print $2}' | sed 's/#//')

    # Space colors - deep purples, blues, and blacks
    space_colors=(
        "\033[38;2;25;25;112m"   # Midnight blue
        "\033[38;2;72;61;139m"   # Dark slate blue
        "\033[38;2;75;0;130m"    # Indigo
        "\033[38;2;138;43;226m"  # Blue violet
        "\033[38;2;30;30;80m"    # Deep space
        "\033[38;2;20;20;60m"    # Darker space
    )

    # Star colors - whites, yellows, light blues
    star_colors=(
        "\033[38;2;255;255;255m"  # White
        "\033[38;2;255;255;224m"  # Light yellow
        "\033[38;2;255;250;205m"  # Lemon chiffon
        "\033[38;2;173;216;230m"  # Light blue
        "\033[38;2;240;248;255m"  # Alice blue
        "\033[38;2;255;239;213m"  # Papaya whip
    )

    # Connection line colors - subtle blues and purples
    line_colors=(
        "\033[38;2;100;149;237m"  # Cornflower blue
        "\033[38;2;135;206;250m"  # Light sky blue
        "\033[38;2;147;112;219m"  # Medium purple
        "\033[38;2;176;196;222m"  # Light steel blue
    )

    # Array of different constellations
    constellations=(
        # Orion - The Hunter
        "ORION_THE_HUNTER

                    ✦


            ★-------✧-------✯
                 /     \\
                /       \\
               /         \\
              ✦           ★
             /             \\
            /               \\
           ★                 ✧
                                    "

        # Ursa Major - The Big Dipper
        "URSA_MAJOR_BIG_DIPPER

        ★
         \\
          \\
           ✧--------★
                     \\
                      \\
                       ★
                      /
                     /
                   ✦
                  /
                 ★
                                    "

        # Cassiopeia - The Queen
        "CASSIOPEIA_THE_QUEEN


          ★
           \\
            \\
             ✧
            /  \\
           /    \\
          ★      ✦
                  \\
                   \\
                    ★
                                    "

        # Lyra - The Harp
        "LYRA_THE_HARP

              ★
             / \\
            /   \\
           ✦     ✧
            \\   /
             \\ /
              ★
              |
              |
              ✯
                                    "

        # Cygnus - The Swan
        "CYGNUS_THE_SWAN

                  ★
                  |
                  |
      ✧-----------✦-----------✯
                  |
                  |
                  |
                  ★
                                    "

        # Draco - The Dragon
        "DRACO_THE_DRAGON

    ★
     \\
      ✧------✦
            /  \\
           /    ★
          /      \\
         ✯        ✧
          \\      /
           \\    /
            ★--✦
                                    "
    )

    # Pick a random constellation
    selected="${constellations[$RANDOM % ${#constellations[@]}]}"
    constellation_name=$(echo "$selected" | head -1)
    constellation_art=$(echo "$selected" | tail -n +2)

    # Convert name from SNAKE_CASE to Title Case
    display_name=$(echo "$constellation_name" | tr '_' ' ' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2));}1')

    # Add some random background stars
    echo
    for i in {1..3}; do
        spaces=$((RANDOM % 80))
        star_char=("." "·" "˚" "✦" "✧")
        random_star="${star_char[$RANDOM % ${#star_char[@]}]}"
        star_color="${star_colors[$RANDOM % ${#star_colors[@]}]}"
        printf "%${spaces}s" ""
        echo -e "${star_color}${random_star}\033[0m"
    done

    echo

    # Print the constellation with colors
    while IFS= read -r line; do
        for (( i=0; i<${#line}; i++ )); do
            char="${line:$i:1}"
            case "$char" in
                ★|✦|✧|✯)
                    # Main stars - bright colors
                    star_color="${star_colors[$RANDOM % ${#star_colors[@]}]}"
                    echo -n -e "${star_color}${char}\033[0m"
                    ;;
                /|\\|\|)
                    # Connection lines - subtle colors
                    line_color="${line_colors[$RANDOM % ${#line_colors[@]}]}"
                    echo -n -e "${line_color}${char}\033[0m"
                    ;;
                -)
                    # Horizontal lines
                    line_color="${line_colors[$RANDOM % ${#line_colors[@]}]}"
                    echo -n -e "${line_color}${char}\033[0m"
                    ;;
                *)
                    # Spaces and other characters
                    echo -n "$char"
                    ;;
            esac
        done
        echo
    done <<< "$constellation_art"

    # Add more background stars after constellation
    for i in {1..3}; do
        spaces=$((RANDOM % 80))
        star_char=("." "·" "˚" "✦" "✧")
        random_star="${star_char[$RANDOM % ${#star_char[@]}]}"
        star_color="${star_colors[$RANDOM % ${#star_colors[@]}]}"
        printf "%${spaces}s" ""
        echo -e "${star_color}${random_star}\033[0m"
    done

    echo

    # Display constellation name in a elegant way
    name_color="\033[38;2;147;112;219m"  # Medium purple
    echo -e "        ${name_color}✧ ${display_name} ✧\033[0m"

    echo
    echo
}

# Call the greeting function
system_greeting
