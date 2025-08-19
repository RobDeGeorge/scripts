# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias octave='git clone https://github.com/waybetterengineering/octave.git'

#chromium
alias homeassistant='chromium http://homeassistant.local:8123/dashboard-michgan/0 --new-window'
alias youtube='chromium http://www.youtube.com --new-window'
alias reddit='chromium http://www.reddit.com --new-window'
alias gmail='chromium http://gmail.com --new-window'
alias perplexity='chromium https://www.perplexity.ai/ --new-window'
alias discord='chromium https://www.discord.com --new-window'
alias web='chromium https://google.com --new-window'
alias github='chromium https://github.com --new-window'

#games
alias gameboy='__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia mgba-qt'
alias osrs='DRI_PRIME=1 $HOME/Downloads/RuneLite.AppImage'

# GPU Control Aliases
alias gpu-on='sudo prime-select nvidia && echo "GPU switched to NVIDIA. Reboot required."'
alias gpu-off='sudo prime-select intel && echo "GPU switched to Intel. Reboot required."'
alias gpu-auto='sudo prime-select on-demand && echo "GPU set to on-demand mode. Reboot required."'
alias gpu-status='echo "Prime mode: $(prime-select query)" && echo "GPU power: $(cat /sys/bus/pci/devices/0000:01:00.0/power/control)" && echo "bbswitch: $(cat /proc/acpi/bbswitch 2>/dev/null || echo not-available)"'

# Wayland GPU
export WLR_NO_HARDWARE_CURSORS=1
export LIBVA_DRIVER_NAME=nvidia
export XDG_SESSION_TYPE=wayland
export GBM_BACKEND=nvidia-drm
export __GLX_VENDOR_LIBRARY_NAME=nvidia


# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# Colorful version
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
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            
# Function to show tree on demand
alias tree='system_greeting'

# Only show tree automatically on first shell startup
if [ -z "$SYSTEM_GREETING_SHOWN" ]; then
    export SYSTEM_GREETING_SHOWN=1
    system_greeting
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion