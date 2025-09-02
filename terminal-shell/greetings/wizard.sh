#!/bin/bash

# Colorful wizard greeting
system_greeting() {
    clear
    
    # Define specific colors for wizard parts
    hat_colors=(
        "\033[38;2;34;139;34m"    # Forest green
        "\033[38;2;0;128;0m"      # Green
        "\033[38;2;50;205;50m"    # Lime green
        "\033[38;2;46;125;50m"    # Sea green
    )
    robe_colors=(
        "\033[38;2;255;192;203m"  # Pink
        "\033[38;2;255;20;147m"   # Deep pink
        "\033[38;2;199;21;133m"   # Medium violet red
        "\033[38;2;219;112;147m"  # Pale violet red
    )
    staff_colors=(
        "\033[38;2;230;230;250m"  # Lavender
        "\033[38;2;221;160;221m"  # Plum
        "\033[38;2;216;191;216m"  # Thistle
        "\033[38;2;186;85;211m"   # Medium orchid
    )
    
    # Pick random colors for this display
    hat_color="${hat_colors[$RANDOM % ${#hat_colors[@]}]}"
    robe_color="${robe_colors[$RANDOM % ${#robe_colors[@]}]}"
    staff_color="${staff_colors[$RANDOM % ${#staff_colors[@]}]}"
    
    # Line 1: Hat + Staff composite
    echo -e "${staff_color}                          :                                                               \033[0m"
    echo -e "${staff_color}                         :░                                                                        \033[0m"
    echo -e "${staff_color}                        .▒█.\033[0m"
    echo -e "${staff_color}                        &▓█&.\033[0m"
    echo -e "${staff_color}                       +-+#▒#\033[0m"
    echo -e "${staff_color}                      -▒= =█@.${hat_color}                       .:%####%***.                                     \033[0m"
    echo -e "${staff_color}                      :░##▓█*${hat_color}                   .-=+▓█████▓@%-                                      \033[0m"
    echo -e "${staff_color}                       -███▒${hat_color}                   =-.:░███▓*-                                          \033[0m"
    echo -e "${staff_color}                        ▒██+${hat_color}                 :+:.=▒▓███▒                                            \033[0m"
    echo -e "${staff_color}                        @▒█:${hat_color}               .=#::+&░▓███▓:                                           \033[0m"
    echo -e "${staff_color}                        *██:${hat_color}            .  .   ...:+@███@-.                                         \033[0m"
    echo -e "${staff_color}                        =██:${hat_color}         :=*&@░▒██████████▓███▒&=                                       \033[0m"
    echo -e "${staff_color}                         ▓█:${hat_color}       %@██████████▒${robe_color}@${hat_color}█▓██████████▓&:\033[0m"
    echo -e "${staff_color}                         ▒█*${hat_color}       ░█████████${robe_color}+::*▒-#${hat_color}▓██▓████████\033[0m"
    echo -e "${staff_color}                         ▓█&${hat_color}       .&▓████${robe_color}*░█@.=@▒*▓███%@${hat_color}██████&\033[0m"
    echo -e "${staff_color}                         ▓█&${robe_color}          .-+## ▓%.***░%&███&*███▒+.\033[0m"
    echo -e "${staff_color}                         ▓█&${robe_color}              . =#. =..=░%&▓█▓░%████%:\033[0m"
    echo -e "${staff_color}                         ▓█&${robe_color}          .=*=:▓. .    %::███░*████▓@=.\033[0m"
    echo -e "${robe_color}                        .%@#..     -+=%█%+#        =-▓██*████████▒*.\033[0m"
    echo -e "${robe_color}                       .=-&#@&    -#.+*▓░%*       -:@%███░▓█████████%.\033[0m"
    echo -e "${robe_color}                      :..-@██ &    &░░░███#-       +=+░▓███▓██████████:\033[0m"
    echo -e "${robe_color}                       -=%░██ ▒: .&*.▓▓███▓-:+  .- ▒.&███████████████░.\033[0m"
    echo -e "${robe_color}                       .░${staff_color}▓█*${robe_color}███░*░+ -██████=++ :=▒ █*▓███████████████▒.\033[0m"
    echo -e "${robe_color}                        ▒${staff_color}▓█*${robe_color}████░██▓███████#+:+&-▒.█▓█████████████████%\033[0m"
    echo -e "${robe_color}                        ▒${staff_color}▓█*${robe_color}████████████████▓=&@░▒████████████████████▓\033[0m"
    echo -e "${robe_color}                        ▒${staff_color}▓█*${robe_color}█████████████████▒#░███████████████████████@\033[0m"
    
    echo
}

# Call the greeting function
system_greeting