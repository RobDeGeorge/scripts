#!/bin/bash

# Colorful tree greeting
system_greeting() {
    clear
    
    # Try to read current wallpaper colors from kitty config
    current_bg=$(grep "^background" ~/.config/kitty/kitty.conf 2>/dev/null | head -1 | awk '{print $2}' | sed 's/#//')
    current_fg=$(grep "^foreground" ~/.config/kitty/kitty.conf 2>/dev/null | head -1 | awk '{print $2}' | sed 's/#//')
    cursor_color=$(grep "^cursor" ~/.config/kitty/kitty.conf 2>/dev/null | head -1 | awk '{print $2}' | sed 's/#//')
    
    # Convert hex to RGB and create vibrant green variations
    if [[ -n "$current_fg" && ${#current_fg} -eq 6 ]]; then
        # Extract RGB values from foreground color
        r=$((16#${current_fg:0:2}))
        g=$((16#${current_fg:2:2}))
        b=$((16#${current_fg:4:2}))
        
        # Calculate brightness to determine if we should use accent colors or force greens
        brightness=$(((r + g + b) / 3))
        
        # If foreground is too dull/gray, force vibrant greens with accent hinting
        if [[ $brightness -lt 80 || $((r + 20)) -gt $g || $((b + 20)) -gt $g ]]; then
            # Force vibrant greens with subtle accent hinting
            accent_r=$((r > 30 ? r / 3 : 10))
            accent_b=$((b > 30 ? b / 3 : 10))
            
            greens=(
                "\033[38;2;$((accent_r + 20));$((180 + accent_r / 2));$((accent_b + 30))m"
                "\033[38;2;$((accent_r + 30));$((200 + accent_r / 3));$((accent_b + 20))m"
                "\033[38;2;$((accent_r + 15));$((160 + accent_r / 2));$((accent_b + 40))m"
                "\033[38;2;$((accent_r + 40));$((220 + accent_r / 4));$((accent_b + 15))m"
                "\033[38;2;$((accent_r + 25));$((190 + accent_r / 3));$((accent_b + 25))m"
                "\033[38;2;$((accent_r + 10));$((170 + accent_r / 2));$((accent_b + 35))m"
                "\033[38;2;$((accent_r + 35));$((210 + accent_r / 4));$((accent_b + 20))m"
                "\033[38;2;$((accent_r + 20));$((185 + accent_r / 3));$((accent_b + 30))m"
                "\033[38;2;$((accent_r + 45));$((240 + accent_r / 5));$((accent_b + 10))m"
            )
        else
            # Use enhanced foreground colors but ensure green dominance
            enhanced_g=$((g * 130 / 100 > 255 ? 255 : g * 130 / 100))
            
            greens=(
                "\033[38;2;$((r*80/100));$((enhanced_g));$((b*70/100))m"
                "\033[38;2;$((r*85/100));$((enhanced_g + 20 > 255 ? 255 : enhanced_g + 20));$((b*75/100))m"
                "\033[38;2;$((r*75/100));$((enhanced_g - 10));$((b*65/100))m"
                "\033[38;2;$((r*90/100));$((enhanced_g + 10 > 255 ? 255 : enhanced_g + 10));$((b*80/100))m"
                "\033[38;2;$((r*70/100));$((enhanced_g + 30 > 255 ? 255 : enhanced_g + 30));$((b*60/100))m"
                "\033[38;2;$((r*95/100));$((enhanced_g - 5));$((b*85/100))m"
                "\033[38;2;$((r*65/100));$((enhanced_g + 15 > 255 ? 255 : enhanced_g + 15));$((b*55/100))m"
                "\033[38;2;$((r*100/100));$((enhanced_g + 5 > 255 ? 255 : enhanced_g + 5));$((b*90/100))m"
                "\033[38;2;$((r*60/100));$((enhanced_g + 40 > 255 ? 255 : enhanced_g + 40));$((b*50/100))m"
            )
        fi
    else
        # Fallback to original vibrant greens if color reading fails
        greens=("\033[32m" "\033[92m" "\033[38;5;22m" "\033[38;5;28m" "\033[38;5;34m" "\033[38;5;40m" "\033[38;5;46m" "\033[38;5;82m" "\033[38;5;118m")
    fi
    
    # Always use consistent brown colors for the bark
    browns=(
        "\033[38;2;101;67;33m"    # Dark brown
        "\033[38;2;139;69;19m"    # Saddle brown  
        "\033[38;2;160;82;45m"    # Sienna
        "\033[38;2;210;180;140m"  # Tan
        "\033[38;2;222;184;135m"  # Burlywood
        "\033[38;2;205;133;63m"   # Peru
        "\033[38;2;92;51;23m"     # Dark chocolate
        "\033[38;2;118;85;43m"    # Medium brown
    )
    
    # Leaves section
    leaves="                                            
                   +-                   
                  ++--                  
                 -+++-.                 
                .+++++...               
               -++-++--..               
             -+++++++-++-.              
              .++#++++++-.              
            +++++++#++++--.             
              .+#++++++----..           
          .++++#####+++-+#+.            
            -++++++--+++++.             
         ..-.+++++####+-+-+++-.         
         -+#+#####+#+++++++-..          
          .++++#+++++#++++..            
           ..++++++++++#+------.        
        -+++++++########+++++-+.        
         --.++#++##+++++++-.-.          
           ++#+####+++#+++----..        
        +++++++++##++######+-+++.       
         .+.-++++#+--++++++-+. .        
           +++#-+##--#..+++++ .         
         .+++-.++++--+-+#+-.+++.        
          ..  --..+-....+++.            "
    
    while IFS= read -r line; do
        for (( i=0; i<${#line}; i++ )); do
            char="${line:$i:1}"
            if [[ "$char" =~ [+#-] ]]; then
                # Tree character - use random green
                green_color=${greens[$RANDOM % ${#greens[@]}]}
                echo -n -e "${green_color}${char}"
            else
                # Space or other - just print normally
                echo -n "$char"
            fi
        done
        echo
    done <<< "$leaves"
    
    # Trunk section
    trunk="                 .+--.                 
                 .+---                  
                 .++.-                  
                 -+---                  
                 ++-.+                  
                 +++-+.                 
                ++#+-+-                 
              .++++++-+--               
                                        "
    
    while IFS= read -r line; do
        for (( i=0; i<${#line}; i++ )); do
            char="${line:$i:1}"
            if [[ "$char" =~ [+#.-] ]]; then
                # Trunk character - use random brown
                brown_color=${browns[$RANDOM % ${#browns[@]}]}
                echo -n -e "${brown_color}${char}"
            else
                # Space - just print normally
                echo -n "$char"
            fi
        done
        echo
    done <<< "$trunk"
    
    echo -e "\033[0m"
    printf '\n'
}

# Call the greeting function
system_greeting