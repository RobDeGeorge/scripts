#!/bin/bash

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse arguments
SKIP_DEPS=false
if [[ "$1" == "--skip-deps" ]]; then
    SKIP_DEPS=true
fi

# Configuration directories with fallbacks
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
WALLPAPER_TARGET="${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}"

# Create config directories if they don't exist
mkdir -p "$CONFIG_DIR/i3"
mkdir -p "$CONFIG_DIR/i3blocks"
mkdir -p "$CONFIG_DIR/dunst"
mkdir -p "$CONFIG_DIR/kitty"
mkdir -p "$CONFIG_DIR/scripts"

# Create wallpaper directory if it doesn't exist
mkdir -p "$WALLPAPER_TARGET"

# Create restore point backup before overwriting existing configs
create_restore_point() {
    echo "Creating restore point before config restore..."
    
    # Copy the backup manager if it exists
    if [ -f "$SCRIPT_DIR/backup_manager.py" ]; then
        local temp_backup_manager="/tmp/backup_manager_temp.py"
        cp "$SCRIPT_DIR/backup_manager.py" "$temp_backup_manager"
        
        # Create restore point using Python backup manager
        python3 -c "
import sys
sys.path.insert(0, '/tmp')
from backup_manager_temp import BackupManager

backup_manager = BackupManager('$SCRIPT_DIR/backups')

config_files = {
    'i3-config': '$CONFIG_DIR/i3/config',
    'i3blocks-config': '$CONFIG_DIR/i3blocks/config', 
    'dunstrc': '$CONFIG_DIR/dunst/dunstrc',
    'kitty.conf': '$CONFIG_DIR/kitty/kitty.conf',
    'bashrc': '$HOME/.bashrc'
}

# Filter to only existing files
existing_configs = {name: path for name, path in config_files.items() if os.path.exists(path)}

if existing_configs:
    backup_manager.backup_multiple_configs(
        existing_configs, 
        'restore-points', 
        'Pre-restore backup created by restore-configs.sh'
    )
    print(f'Created restore point for {len(existing_configs)} config files')
else:
    print('No existing config files found to backup')
" 2>/dev/null
        
        # Clean up temp file
        rm -f "$temp_backup_manager"
    else
        echo "Warning: backup_manager.py not found, skipping restore point creation"
    fi
}

# Create restore point if not in skip mode
if [ "$SKIP_DEPS" = "false" ]; then
    create_restore_point
fi

# Copy config files back to their correct locations
echo "Copying config files..."
[ -f "$SCRIPT_DIR/i3-config" ] && cp "$SCRIPT_DIR/i3-config" "$CONFIG_DIR/i3/config"
[ -f "$SCRIPT_DIR/i3blocks-config" ] && cp "$SCRIPT_DIR/i3blocks-config" "$CONFIG_DIR/i3blocks/config"
[ -f "$SCRIPT_DIR/dunstrc" ] && cp "$SCRIPT_DIR/dunstrc" "$CONFIG_DIR/dunst/dunstrc"
[ -f "$SCRIPT_DIR/kitty.conf" ] && cp "$SCRIPT_DIR/kitty.conf" "$CONFIG_DIR/kitty/kitty.conf"
[ -f "$SCRIPT_DIR/bashrc" ] && cp "$SCRIPT_DIR/bashrc" "$HOME/.bashrc"

# Copy scripts to ~/.config/scripts/
[ -f "$SCRIPT_DIR/wallpaper-cycler.sh" ] && cp "$SCRIPT_DIR/wallpaper-cycler.sh" "$CONFIG_DIR/scripts/"
[ -f "$SCRIPT_DIR/color_processor.py" ] && cp "$SCRIPT_DIR/color_processor.py" "$CONFIG_DIR/scripts/"
[ -f "$SCRIPT_DIR/backup_manager.py" ] && cp "$SCRIPT_DIR/backup_manager.py" "$CONFIG_DIR/scripts/"
[ -f "$SCRIPT_DIR/install-dependencies.sh" ] && cp "$SCRIPT_DIR/install-dependencies.sh" "$CONFIG_DIR/scripts/"

# Make scripts executable
chmod +x "$CONFIG_DIR/scripts/wallpaper-cycler.sh" 2>/dev/null
chmod +x "$CONFIG_DIR/scripts/color_processor.py" 2>/dev/null
chmod +x "$CONFIG_DIR/scripts/backup_manager.py" 2>/dev/null
chmod +x "$CONFIG_DIR/scripts/install-dependencies.sh" 2>/dev/null

# Copy wallpaper-venv directory if it exists
if [ -d "$SCRIPT_DIR/wallpaper-venv" ] && [ ! -d "$CONFIG_DIR/scripts/wallpaper-venv" ]; then
    echo "Copying Python virtual environment..."
    cp -r "$SCRIPT_DIR/wallpaper-venv" "$CONFIG_DIR/scripts/"
fi

# Install wallpaper cycler dependencies only if not skipping
if [ "$SKIP_DEPS" = "false" ]; then
    echo "Setting up wallpaper cycler dependencies..."
    if [ -f "$CONFIG_DIR/scripts/install-dependencies.sh" ]; then
        cd "$CONFIG_DIR/scripts"
        ./install-dependencies.sh
        cd - > /dev/null
    else
        echo "Warning: install-dependencies.sh not found, skipping dependency setup"
    fi
else
    echo "Skipping dependency installation (--skip-deps flag)"
fi

# Restore wallpapers with error handling
if [ -d "$SCRIPT_DIR/wallpapers" ]; then
    if [ "$(ls -A "$SCRIPT_DIR/wallpapers" 2>/dev/null)" ]; then
        cp "$SCRIPT_DIR/wallpapers"/* "$WALLPAPER_TARGET/" 2>/dev/null || echo "Warning: Failed to copy some wallpapers"
        echo "Wallpapers restored to $WALLPAPER_TARGET/"
    else
        echo "Warning: wallpapers directory is empty"
    fi
else
    echo "Warning: $SCRIPT_DIR/wallpapers directory not found - skipping wallpaper restoration"
fi

echo "Config files restored to ~/.config/"
echo ""
echo "=== Setup Complete! ==="
echo "✓ Config files restored"
echo "✓ Wallpapers installed"  
echo "✓ Dependencies installed"
echo "✓ Scripts ready at ~/.config/scripts/"
echo ""
echo "You can now:"
echo "- Run ~/.config/scripts/wallpaper-cycler.sh to test"
echo "- Use Mod+Shift+W in i3 to cycle wallpapers"
echo "- Restart i3 (Mod+Shift+R) to load new configs"