#!/bin/bash

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/wallpaper-venv"

# Source window manager detection
source "$SCRIPT_DIR/detect_wm.sh"

echo "Installing wallpaper cycler dependencies..."

# Detect current window manager
WM=$(detect_window_manager)
echo "Detected window manager: $WM"

# Detect package manager and distro
detect_package_manager() {
    if command -v apt &> /dev/null; then
        echo "apt"
    elif command -v pacman &> /dev/null; then
        echo "pacman"
    elif command -v dnf &> /dev/null; then
        echo "dnf"
    elif command -v yum &> /dev/null; then
        echo "yum"
    elif command -v zypper &> /dev/null; then
        echo "zypper"
    elif command -v apk &> /dev/null; then
        echo "apk"
    else
        echo "unknown"
    fi
}

# Check if packages are already installed
check_system_packages() {
    local wm="$1"
    local missing=()
    
    # Core system packages
    command -v python3 &> /dev/null || missing+=("python3")
    command -v kitty &> /dev/null || missing+=("kitty")
    
    # Window manager specific packages
    case "$wm" in
        "hyprland")
            command -v hyprland &> /dev/null || missing+=("hyprland")
            command -v waybar &> /dev/null || missing+=("waybar")
            command -v mako &> /dev/null || missing+=("mako")
            command -v hyprpaper &> /dev/null || missing+=("hyprpaper")
            command -v grim &> /dev/null || missing+=("grim")
            command -v slurp &> /dev/null || missing+=("slurp")
            ;;
        "i3")
            command -v xwallpaper &> /dev/null || missing+=("xwallpaper")
            command -v i3 &> /dev/null || missing+=("i3")
            command -v i3blocks &> /dev/null || missing+=("i3blocks")
            command -v dunst &> /dev/null || missing+=("dunst")
            command -v scrot &> /dev/null || missing+=("scrot")
            ;;
    esac
    
    # Audio and system controls
    command -v pamixer &> /dev/null || missing+=("pamixer")
    command -v brightnessctl &> /dev/null || missing+=("brightnessctl")
    command -v pactl &> /dev/null || missing+=("pulseaudio-utils")
    
    # Graphics and display
    command -v picom &> /dev/null || missing+=("picom")
    command -v xss-lock &> /dev/null || missing+=("xss-lock")
    command -v i3lock &> /dev/null || missing+=("i3lock")
    
    # Network tools
    command -v nm-applet &> /dev/null || missing+=("network-manager-gnome")
    command -v iwgetid &> /dev/null || missing+=("wireless-tools")
    
    # System monitoring
    command -v sensors &> /dev/null || missing+=("lm-sensors")
    command -v acpi &> /dev/null || missing+=("acpi")
    
    # Python tools
    python3 -c "import venv" 2>/dev/null || missing+=("python3-venv")
    python3 -c "import pip" 2>/dev/null || missing+=("python3-pip")
    
    if [ ${#missing[@]} -eq 0 ]; then
        echo "✓ All system packages already installed"
        return 0
    else
        echo "Missing packages: ${missing[*]}"
        export MISSING_PACKAGES=("${missing[@]}")
        return 1
    fi
}

# Map package names for different distros
get_package_names() {
    local pm="$1"
    local wm="$2"
    
    # Base packages for all systems
    local base_packages=""
    case "$pm" in
        "apt")
            base_packages="python3 python3-venv python3-pip kitty pamixer brightnessctl pulseaudio-utils network-manager-gnome wireless-tools lm-sensors acpi"
            ;;
        "pacman")
            base_packages="python python-pip kitty pamixer brightnessctl pulseaudio network-manager-applet wireless_tools lm_sensors acpi"
            ;;
        "dnf"|"yum")
            base_packages="python3 python3-venv python3-pip kitty pamixer brightnessctl pulseaudio-utils NetworkManager-gnome wireless-tools lm_sensors acpi"
            ;;
        "zypper")
            base_packages="python3 python3-venv python3-pip kitty pamixer brightnessctl pulseaudio-utils NetworkManager-gnome wireless-tools sensors acpi"
            ;;
        "apk")
            base_packages="python3 py3-venv py3-pip kitty pamixer brightnessctl pulseaudio networkmanager-gtk wireless-tools lm-sensors acpi"
            ;;
    esac
    
    # Window manager specific packages
    local wm_packages=""
    case "$wm" in
        "hyprland")
            case "$pm" in
                "apt")
                    wm_packages="hyprland waybar mako-notifier hyprpaper grim slurp"
                    ;;
                "pacman")
                    wm_packages="hyprland waybar mako hyprpaper grim slurp"
                    ;;
                "dnf"|"yum")
                    wm_packages="hyprland waybar mako hyprpaper grim slurp"
                    ;;
                "zypper")
                    wm_packages="hyprland waybar mako hyprpaper grim slurp"
                    ;;
                "apk")
                    wm_packages="hyprland waybar mako hyprpaper grim slurp"
                    ;;
            esac
            ;;
        "i3")
            case "$pm" in
                "apt")
                    wm_packages="xwallpaper i3-wm i3blocks dunst scrot picom xss-lock i3lock"
                    ;;
                "pacman")
                    wm_packages="xwallpaper i3-wm i3blocks dunst scrot picom xss-lock i3lock"
                    ;;
                "dnf"|"yum")
                    wm_packages="xwallpaper i3 i3blocks dunst scrot picom xss-lock i3lock"
                    ;;
                "zypper")
                    wm_packages="xwallpaper i3 i3blocks dunst scrot picom xss-lock i3lock"
                    ;;
                "apk")
                    wm_packages="xwallpaper i3wm i3blocks dunst scrot picom xss-lock i3lock"
                    ;;
            esac
            ;;
    esac
    
    echo "$base_packages $wm_packages"
}

# Install only missing packages
install_missing_packages() {
    local pm="$1"
    local wm="$2"
    local missing_packages=("${MISSING_PACKAGES[@]}")
    local all_packages=($(get_package_names "$pm" "$wm"))
    local to_install=()
    
    # Map missing commands to package names
    for missing in "${missing_packages[@]}"; do
        case "$missing" in
            "python3"|"python3-venv"|"python3-pip"|"xwallpaper"|"i3"|"i3blocks"|"dunst"|"kitty"|"scrot"|"pamixer"|"brightnessctl"|"pulseaudio-utils"|"picom"|"xss-lock"|"i3lock"|"network-manager-gnome"|"wireless-tools"|"lm-sensors"|"acpi")
                # Find the corresponding package in the distro list
                for pkg in "${all_packages[@]}"; do
                    if [[ "$pkg" == *"$missing"* ]] || [[ "$missing" == "i3" && "$pkg" == "i3-wm" ]] || [[ "$missing" == "python3" && "$pkg" == "python" ]] || [[ "$missing" == "pulseaudio-utils" && ("$pkg" == "pulseaudio" || "$pkg" == "pulseaudio-utils") ]]; then
                        to_install+=("$pkg")
                        break
                    fi
                done
                ;;
        esac
    done
    
    # Remove duplicates
    local unique_packages=($(printf "%s\n" "${to_install[@]}" | sort -u))
    
    if [ ${#unique_packages[@]} -eq 0 ]; then
        echo "✓ No packages need to be installed"
        return 0
    fi
    
    echo "Installing missing packages: ${unique_packages[*]}"
    
    case "$pm" in
        "apt")
            sudo apt update
            sudo apt install -y "${unique_packages[@]}"
            # Install dev packages if python3 was missing
            if [[ " ${missing_packages[*]} " =~ " python3 " ]]; then
                sudo apt install -y python3-dev libjpeg-dev zlib1g-dev
            fi
            ;;
        "pacman")
            sudo pacman -Sy --noconfirm "${unique_packages[@]}"
            if [[ " ${missing_packages[*]} " =~ " python3 " ]]; then
                sudo pacman -S --noconfirm base-devel libjpeg-turbo zlib
            fi
            ;;
        "dnf")
            sudo dnf install -y "${unique_packages[@]}"
            if [[ " ${missing_packages[*]} " =~ " python3 " ]]; then
                sudo dnf install -y python3-devel libjpeg-turbo-devel zlib-devel
            fi
            ;;
        "yum")
            sudo yum install -y "${unique_packages[@]}"
            if [[ " ${missing_packages[*]} " =~ " python3 " ]]; then
                sudo yum install -y python3-devel libjpeg-turbo-devel zlib-devel
            fi
            ;;
        "zypper")
            sudo zypper install -y "${unique_packages[@]}"
            if [[ " ${missing_packages[*]} " =~ " python3 " ]]; then
                sudo zypper install -y python3-devel libjpeg8-devel zlib-devel
            fi
            ;;
        "apk")
            sudo apk add "${unique_packages[@]}"
            if [[ " ${missing_packages[*]} " =~ " python3 " ]]; then
                sudo apk add python3-dev jpeg-dev zlib-dev
            fi
            ;;
        *)
            echo "Unknown package manager. Please install manually:"
            printf " - %s\n" "${unique_packages[@]}"
            read -p "Press Enter when dependencies are installed..."
            ;;
    esac
}

# Install system packages
install_system_packages() {
    local pm="$1"
    local wm="$2"
    
    # Check which packages are missing
    if check_system_packages "$wm"; then
        return 0
    fi
    
    # Install only missing packages
    install_missing_packages "$pm" "$wm"
}

# Create Python virtual environment
setup_python_venv() {
    echo "Setting up Python virtual environment..."
    
    # Remove existing venv if it exists
    if [ -d "$VENV_DIR" ]; then
        echo "Removing existing virtual environment..."
        rm -rf "$VENV_DIR"
    fi
    
    # Create new venv
    python3 -m venv "$VENV_DIR"
    
    # Activate and install packages
    source "$VENV_DIR/bin/activate"
    
    echo "Installing Python packages..."
    pip install --upgrade pip
    pip install Pillow scikit-learn numpy
    
    echo "Virtual environment created at: $VENV_DIR"
    echo "Python packages installed: $(pip list --format=columns)"
    
    deactivate
}

# Check for font dependencies
check_fonts() {
    echo "Checking fonts..."
    
    # Check for VictorMono Nerd Font
    if ! fc-list | grep -i "victor.*mono.*nerd" &> /dev/null; then
        echo "Warning: VictorMono Nerd Font not found."
        echo "Download from: https://github.com/ryanoasis/nerd-fonts/releases"
        echo "Or install via: sudo apt install fonts-victor-mono (if available)"
        return 1
    else
        echo "✓ VictorMono Nerd Font found"
        return 0
    fi
}

# Install font if missing
install_fonts() {
    local pm="$1"
    
    echo "Installing fonts..."
    case "$pm" in
        "apt")
            # Try to install nerd fonts if available
            sudo apt update
            if apt-cache search fonts-nerd &> /dev/null; then
                sudo apt install -y fonts-nerd-font-victor-mono 2>/dev/null || echo "Nerd fonts not available in repository"
            fi
            ;;
        "pacman")
            # AUR might have nerd fonts
            if command -v yay &> /dev/null; then
                yay -S --noconfirm ttf-victor-mono-nerd 2>/dev/null || echo "Font not available via AUR"
            elif command -v paru &> /dev/null; then
                paru -S --noconfirm ttf-victor-mono-nerd 2>/dev/null || echo "Font not available via AUR"
            fi
            ;;
    esac
    
    echo "Manual font installation may be required:"
    echo "1. Download VictorMono Nerd Font from https://github.com/ryanoasis/nerd-fonts/releases"
    echo "2. Extract to ~/.local/share/fonts/ or /usr/share/fonts/"
    echo "3. Run: fc-cache -fv"
}

# Check for optional dependencies
check_optional_deps() {
    echo "Checking optional dependencies..."
    
    # Check for Node.js (referenced in bashrc)
    if ! command -v node &> /dev/null && [ -d "$HOME/.nvm" ]; then
        echo "Warning: Node.js not found but NVM is installed."
        echo "Run: nvm install --lts && nvm use --lts"
    elif command -v node &> /dev/null; then
        echo "✓ Node.js found: $(node --version)"
    fi
    
    # Check for GPU tools
    if ! command -v nvidia-smi &> /dev/null; then
        echo "Warning: nvidia-smi not found. GPU monitoring will show 'Integrated'."
        echo "Install NVIDIA drivers if you have an NVIDIA GPU."
    else
        echo "✓ nvidia-smi found"
    fi
    
    if ! command -v prime-select &> /dev/null; then
        echo "Warning: prime-select not found. GPU switching aliases won't work."
        echo "Install nvidia-prime for GPU switching on laptops."
    else
        echo "✓ prime-select found"
    fi
    
    if ! command -v polychromatic-cli &> /dev/null; then
        echo "Warning: polychromatic-cli not found. Razer keyboard RGB effects will be skipped."
        echo "To install: https://polychromatic.app/download/"
    else
        echo "✓ polychromatic-cli found"
    fi
    
    if ! command -v notify-send &> /dev/null; then
        echo "Warning: notify-send not found. Desktop notifications will be skipped."
        echo "Install libnotify-bin (apt) or libnotify (pacman) for notifications."
    else
        echo "✓ notify-send found"
    fi
    
    # Check for chromium-browser (referenced in bashrc aliases)
    if ! command -v chromium-browser &> /dev/null && ! command -v chromium &> /dev/null; then
        echo "Warning: chromium-browser not found. Web aliases won't work."
        echo "Install: sudo apt install chromium-browser"
    else
        echo "✓ Chromium browser found"
    fi
}

# Main installation process
main() {
    echo "Wallpaper Cycler Dependency Installer"
    echo "====================================="
    
    # Check if running as root
    if [ "$EUID" -eq 0 ]; then
        echo "Error: Don't run this script as root (sudo will be used when needed)"
        exit 1
    fi
    
    # Detect package manager
    PM=$(detect_package_manager)
    echo "Detected package manager: $PM"
    
    # Install system packages
    install_system_packages "$PM" "$WM"
    
    # Check and install fonts
    if ! check_fonts; then
        install_fonts "$PM"
    fi
    
    # Setup Python virtual environment
    setup_python_venv
    
    # Check optional dependencies
    check_optional_deps
    
    echo "Installation complete!"
    echo "Virtual environment created at: $VENV_DIR"
    echo "Run ./wallpaper-cycler.sh to test the setup"
}

# Run main function
main "$@"