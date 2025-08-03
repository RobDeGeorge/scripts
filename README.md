# Linux Configuration Kit

A collection of configuration files and scripts for setting up a personalized Linux desktop environment with i3 window manager, dynamic theming, and automated wallpaper cycling.

## Contents

### Configuration Files
- **`bashrc`** - Custom bash configuration with enhanced features
- **`i3-config`** - i3 window manager configuration with gaps, keybindings, and custom styling
- **`i3blocks-config`** - Status bar configuration for i3blocks
- **`kitty.conf`** - Kitty terminal emulator configuration
- **`dunstrc`** - Dunst notification daemon configuration

### Scripts
- **`restore-configs.sh`** - Deploy all configuration files to their proper locations
- **`sync-configs.sh`** - Backup current configs to this directory
- **`wallpaper-cycler.sh`** - Advanced wallpaper manager with dynamic color extraction and theme updates

## Features

### Dynamic Theming System
The wallpaper cycler script provides:
- Automatic color extraction from wallpapers using Python/PIL
- Dynamic theme updates for i3wm, kitty, dunst, and i3blocks
- Contrast-safe color calculations for readability
- Razer keyboard RGB integration (if available)
- Smooth color gradients across UI elements

### Quick Setup
```bash
# Deploy configurations
./restore-configs.sh

# Backup current configurations
./sync-configs.sh
```

### Wallpaper Management
```bash
# Cycle wallpaper and update theme
./wallpaper-cycler.sh
# Or use the i3 keybinding: Mod+Shift+w
```

## Requirements

### Essential Packages
```bash
# Core components
sudo apt install i3-wm i3blocks dunst kitty picom xwallpaper

# Python dependencies for color extraction
pip3 install Pillow colorsys

# Optional: Razer keyboard support
sudo apt install polychromatic
```

### Directory Structure
Create wallpaper directory:
```bash
mkdir -p ~/Pictures/Wallpapers
```

## Installation

1. Clone this repository to your preferred location
2. Make scripts executable:
   ```bash
   chmod +x *.sh
   ```
3. Run the restore script:
   ```bash
   ./restore-configs.sh
   ```
4. Add wallpapers to `~/Pictures/Wallpapers/`
5. Restart i3 or reboot

## Customization

### Modifying Paths
Update wallpaper directory in `wallpaper-cycler.sh`:
```bash
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
```

### Adding New Configs
1. Add config file to this directory
2. Update `sync-configs.sh` to backup the file
3. Update `restore-configs.sh` to deploy the file

### Color Theme Adjustments
Edit the color calculation functions in `wallpaper-cycler.sh` to adjust:
- Brightness levels
- Contrast ratios
- Saturation levels
- Color harmonies

## Compatibility

Tested on:
- Ubuntu 20.04+
- Debian 11+
- Arch Linux
- Any distribution with i3wm support

## Notes

- The wallpaper cycler requires Python 3 and PIL (Pillow)
- Razer keyboard features require polychromatic-cli
- Backup your existing configs before running restore script
- Some hardcoded paths may need adjustment for your username/setup