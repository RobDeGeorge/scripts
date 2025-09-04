# Linux Desktop Theme Kit

A comprehensive Linux desktop theming system that automatically generates color schemes from wallpapers and applies them across your entire desktop environment. Supports both i3wm and Hyprland window managers with intelligent color extraction and contrast-safe theme generation.

## Installation

### Prerequisites

- Linux distribution with package manager (apt, pacman, dnf, yum, zypper, or apk)
- Python 3.6+ with venv support
- Either i3wm or Hyprland window manager

### Quick Setup

```bash
# Clone or download the repository
git clone <repository-url>
cd scripts

# Make scripts executable
chmod +x *.sh theming-engine/*.sh

# Install dependencies and setup (auto-detects your distro and window manager)
./install-dependencies.sh

# Deploy configuration files
./restore-configs.sh
```

### Manual Installation

```bash
# Install system dependencies based on your package manager
# Ubuntu/Debian:
sudo apt install python3 python3-venv python3-pip kitty pamixer brightnessctl

# Arch Linux:
sudo pacman -S python python-pip kitty pamixer brightnessctl

# For i3wm users, also install:
sudo apt install i3-wm i3blocks dunst xwallpaper scrot  # Ubuntu/Debian
sudo pacman -S i3-wm i3blocks dunst xwallpaper scrot    # Arch

# For Hyprland users, also install:
sudo apt install hyprland waybar mako-notifier hyprpaper  # Ubuntu/Debian
sudo pacman -S hyprland waybar mako hyprpaper             # Arch

# Setup Python virtual environment
cd theming-engine
python3 -m venv wallpaper-venv
source wallpaper-venv/bin/activate
pip install Pillow scikit-learn numpy
deactivate
```

## Usage

### Basic Usage

```bash
# Cycle to next wallpaper and update theme
./theming-engine/wallpaper-cycler.sh

# Use specific wallpaper
./theming-engine/wallpaper-cycler.sh --wallpaper /path/to/image.jpg

# Test color extraction without applying changes
./theming-engine/wallpaper-cycler.sh --dry-run
```

### Keyboard Shortcuts

Add these keybindings to your window manager config:

**i3wm:**
```
bindsym $mod+Shift+w exec /path/to/scripts/theming-engine/wallpaper-cycler.sh
```

**Hyprland:**
```
bind = $mainMod SHIFT, W, exec, /path/to/scripts/theming-engine/wallpaper-cycler.sh
```

### Environment Variables

```bash
export WALLPAPER_DIR="$HOME/Pictures/Wallpapers"  # Wallpaper directory
export VENV_DIR="/path/to/wallpaper-venv"         # Python virtual environment
```

## API Documentation

### Core Components

#### ColorProcessor Class

Located in `theming-engine/color_processor.py:13`

```python
processor = ColorProcessor(config_paths)
colors = processor.extract_dominant_colors_kmeans(image_path, n_colors=5)
success = processor.process_wallpaper(wallpaper_path)
```

**Key Methods:**
- `extract_dominant_colors_kmeans()` - Extract dominant colors using k-means clustering
- `process_wallpaper()` - Main method to process wallpaper and update all configs
- `ensure_text_contrast()` - Generate WCAG-compliant text colors
- `update_i3_config()` - Update i3 window manager configuration
- `update_hyprland_config()` - Update Hyprland window manager configuration

#### Window Manager Detection

Located in `detect_wm.sh:6`

```bash
source detect_wm.sh
WM=$(detect_window_manager)
eval "$(get_wm_commands "$WM")"
eval "$(get_config_paths "$WM")"
```

### Configuration Management

The system automatically detects and configures:

- **Window Manager**: i3wm or Hyprland borders, gaps, workspaces
- **Status Bar**: i3blocks or Waybar with gradient color schemes  
- **Terminal**: Kitty with matching background/foreground colors
- **Notifications**: Dunst (i3) or Mako (Hyprland) with themed colors
- **Lock Screen**: Updates hyprlock wallpaper and cached lock images
- **RGB Peripherals**: Razer keyboard support via polychromatic-cli

## Configuration

### Wallpaper Directory

Place wallpapers in `~/Pictures/Wallpapers/` or set custom directory:

```bash
export WALLPAPER_DIR="/path/to/wallpapers"
```

Supported formats: JPG, JPEG, PNG, GIF, BMP, TIFF, WebP

### Config File Locations

The system manages these configuration files:

```
~/.config/i3/config                 # i3 window manager
~/.config/i3blocks/config           # i3 status bar  
~/.config/dunst/dunstrc             # i3 notifications
~/.config/hypr/hyprland.conf        # Hyprland window manager
~/.config/hypr/hyprlock.conf        # Hyprland lock screen
~/.config/waybar/config             # Waybar status bar
~/.config/waybar/style.css          # Waybar styling
~/.config/mako/config               # Mako notifications
~/.config/kitty/kitty.conf          # Terminal emulator
~/.bashrc                           # Shell configuration
```

### Customization

Color generation parameters can be modified in `theming-engine/color_processor.py`:

- `min_contrast` levels for text readability (lines 45, 57, 220)
- Color brightness adjustments (lines 122, 266, 384)
- K-means clustering parameters (line 159)

## Dependencies and Requirements

### System Requirements

- Linux operating system
- X11 or Wayland display server
- i3wm or Hyprland window manager
- Python 3.6+ with venv and pip

### System Packages

**Core Dependencies:**
- `python3`, `python3-venv`, `python3-pip`
- `kitty` terminal emulator
- `pamixer` for audio control
- `brightnessctl` for brightness control

**i3wm Dependencies:**
- `i3-wm` window manager
- `i3blocks` status bar
- `dunst` notification daemon
- `xwallpaper` wallpaper utility
- `scrot` screenshot tool
- `picom` compositor
- `i3lock` screen locker

**Hyprland Dependencies:**
- `hyprland` window manager
- `waybar` status bar
- `mako` notification daemon
- `hyprpaper` wallpaper utility
- `grim` and `slurp` screenshot tools

**Python Dependencies:**
- `Pillow` for image processing
- `scikit-learn` for k-means clustering
- `numpy` for numerical operations

### Optional Dependencies

- `polychromatic-cli` for Razer RGB keyboard support
- `nvidia-smi` for GPU monitoring
- `prime-select` for GPU switching
- `notify-send` for desktop notifications
- VictorMono Nerd Font and Bilbo font for styling

## Contributing

### Development Setup

```bash
# Install development dependencies
./install-dependencies.sh

# Sync current configs to development directory
./sync-configs.sh

# Test changes
./theming-engine/wallpaper-cycler.sh --dry-run

# Apply changes back to system
./restore-configs.sh
```

### Code Structure

- `detect_wm.sh` - Window manager detection and configuration
- `install-dependencies.sh` - Automated dependency installation
- `restore-configs.sh` - Deploy configurations to system
- `sync-configs.sh` - Backup current system configurations
- `theming-engine/` - Core color processing and theme generation
- `terminal-shell/` - Shell and terminal configurations
- `i3-ecosystem/` - i3wm specific configurations
- `hyprland-ecosystem/` - Hyprland specific configurations

### Adding New Window Managers

1. Add detection logic to `detect_wm.sh:6`
2. Implement config update methods in `theming-engine/color_processor.py`
3. Add package mappings to `install-dependencies.sh:112`
4. Create configuration templates in appropriate ecosystem directory

## License

This project is provided as-is for educational and personal use. Individual configuration files may be subject to their respective application licenses.