#!/bin/bash

# Get script directory for relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="${VENV_DIR:-$SCRIPT_DIR/wallpaper-venv}"

# Configuration with fallbacks - detect if running from ~/.config/scripts or original location
WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}"
INDEX_FILE="${INDEX_FILE:-${HOME}/.wallpaper_index}"

# Check if we're running from ~/.config/scripts/ (i3 keybind) or original scripts folder
if [[ "$SCRIPT_DIR" == *"/.config/scripts"* ]]; then
    # Running from ~/.config/scripts, use the live config files directly
    I3_CONFIG="${I3_CONFIG:-${HOME}/.config/i3/config}"
    I3BLOCKS_CONFIG="${I3BLOCKS_CONFIG:-${HOME}/.config/i3blocks/config}"
    KITTY_CONFIG="${KITTY_CONFIG:-${HOME}/.config/kitty/kitty.conf}"
    DUNST_CONFIG="${DUNST_CONFIG:-${HOME}/.config/dunst/dunstrc}"
    SKIP_RESTORE=true
else
    # Running from original scripts folder, use local copies
    I3_CONFIG="${I3_CONFIG:-$SCRIPT_DIR/i3-config}"
    I3BLOCKS_CONFIG="${I3BLOCKS_CONFIG:-$SCRIPT_DIR/i3blocks-config}"
    KITTY_CONFIG="${KITTY_CONFIG:-$SCRIPT_DIR/kitty.conf}"
    DUNST_CONFIG="${DUNST_CONFIG:-$SCRIPT_DIR/dunstrc}"
    SKIP_RESTORE=false
fi

# Parse command line arguments
DRY_RUN=false
SPECIFIC_WALLPAPER=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --wallpaper)
            SPECIFIC_WALLPAPER="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --dry-run           Test color extraction without applying changes"
            echo "  --wallpaper FILE    Use specific wallpaper file instead of cycling"
            echo "  --help              Show this help message"
            echo ""
            echo "Environment Variables:"
            echo "  WALLPAPER_DIR       Directory containing wallpapers (default: ~/Pictures/Wallpapers)"
            echo "  VENV_DIR           Python virtual environment path"
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            echo "Use --help for usage information" >&2
            exit 1
            ;;
    esac
done

# Check if virtual environment exists
if [ ! -d "$VENV_DIR" ]; then
    echo "Error: Virtual environment not found at $VENV_DIR" >&2
    echo "Run ./install-dependencies.sh first to set up dependencies" >&2
    exit 1
fi

# Activate virtual environment
source "$VENV_DIR/bin/activate"

if [ ! -d "$WALLPAPER_DIR" ]; then
    echo "Error: Wallpaper directory $WALLPAPER_DIR does not exist" >&2
    exit 1
fi

if ! command -v xwallpaper &> /dev/null; then
    echo "Error: xwallpaper command not found" >&2
    exit 1
fi

extract_colors_and_update_configs() {
    local wallpaper_path="$1"
    local dry_run="$2"
    
    if [ "$dry_run" = "true" ]; then
        echo "DRY RUN: Would extract colors from: $wallpaper_path" >&2
        echo "DRY RUN: Would update local configs in scripts folder, then apply to system" >&2
        # Just test color extraction without updating configs
        python3 -c "
import sys
sys.path.insert(0, '$SCRIPT_DIR')
from color_processor import ColorProcessor

config_paths = {
    'i3': '$I3_CONFIG',
    'kitty': '$KITTY_CONFIG', 
    'dunst': '$DUNST_CONFIG',
    'i3blocks': '$I3BLOCKS_CONFIG'
}

processor = ColorProcessor(config_paths)
colors = processor.extract_dominant_colors_kmeans('$wallpaper_path')
print(f'Extracted colors: {[processor.rgb_to_hex(*c) for c in colors]}', file=sys.stderr)
"
        return 0
    else
        # Use the new color processor script
        python3 "$SCRIPT_DIR/color_processor.py" "$wallpaper_path" "$I3_CONFIG" "$KITTY_CONFIG" "$DUNST_CONFIG" "$I3BLOCKS_CONFIG"
        
        if [ $? -ne 0 ]; then
            echo "Error: Color processing failed. Some configs may not have been updated." >&2
            return 1
        fi
    fi
}

# Handle wallpaper selection
if [ -n "$SPECIFIC_WALLPAPER" ]; then
    # Use specific wallpaper file
    if [ ! -f "$SPECIFIC_WALLPAPER" ]; then
        echo "Error: Wallpaper file not found: $SPECIFIC_WALLPAPER" >&2
        exit 1
    fi
    WALLPAPER="$SPECIFIC_WALLPAPER"
else
    # Cycle through wallpapers in directory
    WALLPAPER=$(python3 -c "
import os
import sys

wallpaper_dir = sys.argv[1]
index_file = sys.argv[2]

image_extensions = {'.jpg', '.jpeg', '.png', '.gif', '.bmp', '.tiff', '.webp'}

try:
    wallpapers = sorted([f for f in os.listdir(wallpaper_dir) 
                        if os.path.isfile(os.path.join(wallpaper_dir, f)) 
                        and any(f.lower().endswith(ext) for ext in image_extensions)])
    
    if not wallpapers:
        print('Error: No image files found in wallpaper directory', file=sys.stderr)
        sys.exit(1)
    
    if not os.path.exists(index_file):
        with open(index_file, 'w') as f:
            f.write('0')
    
    with open(index_file) as f:
        idx = int(f.read().strip())
    
    if idx >= len(wallpapers):
        idx = 0
    
    wallpaper = wallpapers[idx]
    next_idx = (idx + 1) % len(wallpapers)
    
    with open(index_file, 'w') as f:
        f.write(str(next_idx))
    
    print(os.path.join(wallpaper_dir, wallpaper))
    
except Exception as e:
    print(f'Error: {e}', file=sys.stderr)
    sys.exit(1)
" "$WALLPAPER_DIR" "$INDEX_FILE")
fi

if [ $? -ne 0 ] || [ -z "$WALLPAPER" ]; then
    echo "Error: Failed to get wallpaper" >&2
    exit 1
fi

echo "Setting wallpaper: $WALLPAPER" >&2

if [ "$DRY_RUN" = "true" ]; then
    echo "DRY RUN: Extracting colors (no changes will be made)..." >&2
    extract_colors_and_update_configs "$WALLPAPER" true
    echo "DRY RUN: Complete. No changes were made to your system." >&2
else
    echo "Extracting colors and updating configs..." >&2
    extract_colors_and_update_configs "$WALLPAPER" false
    
    if [ $? -eq 0 ]; then
        # Apply the updated configs to the system
        if [ "$SKIP_RESTORE" = "true" ]; then
            # Running from ~/.config/scripts, configs already updated in place
            echo "Configs updated directly in system locations" >&2
        else
            # Running from scripts folder, need to copy to system locations
            echo "Applying config changes to system..." >&2
            "$SCRIPT_DIR/restore-configs.sh" --skip-deps > /dev/null 2>&1
            
            if [ $? -ne 0 ]; then
                echo "Error: Failed to apply config changes to system" >&2
                exit 1
            fi
        fi
        
        xwallpaper --zoom "$WALLPAPER" &
        
        # First kill i3blocks before reloading i3
        pkill i3blocks >/dev/null 2>&1
        sleep 0.2
        
        # Reload i3 config which should restart i3blocks with new config
        i3-msg reload >/dev/null 2>&1
        
        # If i3blocks didn't restart automatically, start it manually
        sleep 0.5
        if ! pgrep i3blocks >/dev/null 2>&1; then
            i3blocks &
        fi
        
        pkill dunst >/dev/null 2>&1
        dunst &
        
        notify-send "Wallpaper Updated" "New color scheme applied! 🎨" >/dev/null 2>&1 &
        
        echo "Wallpaper and color scheme updated successfully" >&2
    else
        echo "Color processing failed. Wallpaper not changed." >&2
        exit 1
    fi
fi

# Deactivate virtual environment
deactivate

exit 0