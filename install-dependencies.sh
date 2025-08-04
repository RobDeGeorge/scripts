#!/bin/bash

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/wallpaper-venv"

echo "Installing wallpaper cycler dependencies..."

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

# Check if essential packages are already installed
check_system_packages() {
    local missing=()
    
    command -v python3 &> /dev/null || missing+=("python3")
    command -v xwallpaper &> /dev/null || missing+=("xwallpaper")
    command -v i3 &> /dev/null || missing+=("i3")
    
    if [ ${#missing[@]} -eq 0 ]; then
        echo "✓ Essential system packages already installed"
        return 0
    else
        echo "Missing packages: ${missing[*]}"
        return 1
    fi
}

# Install system packages
install_system_packages() {
    local pm="$1"
    
    # Check if packages are already installed
    if check_system_packages; then
        return 0
    fi
    
    echo "Installing system packages using $pm..."
    
    case "$pm" in
        "apt")
            sudo apt update
            sudo apt install -y python3 python3-venv python3-pip xwallpaper i3-wm i3blocks dunst kitty
            # Optional: Pillow dependencies for better image support
            sudo apt install -y python3-dev libjpeg-dev zlib1g-dev
            ;;
        "pacman")
            sudo pacman -Sy --noconfirm python python-pip xwallpaper i3-wm i3blocks dunst kitty
            # Pillow dependencies
            sudo pacman -S --noconfirm base-devel libjpeg-turbo zlib
            ;;
        "dnf")
            sudo dnf install -y python3 python3-venv python3-pip xwallpaper i3 i3blocks dunst kitty
            # Pillow dependencies
            sudo dnf install -y python3-devel libjpeg-turbo-devel zlib-devel
            ;;
        "yum")
            sudo yum install -y python3 python3-venv python3-pip xwallpaper i3 i3blocks dunst kitty
            # Pillow dependencies
            sudo yum install -y python3-devel libjpeg-turbo-devel zlib-devel
            ;;
        "zypper")
            sudo zypper install -y python3 python3-venv python3-pip xwallpaper i3 i3blocks dunst kitty
            # Pillow dependencies
            sudo zypper install -y python3-devel libjpeg8-devel zlib-devel
            ;;
        "apk")
            sudo apk add python3 py3-venv py3-pip xwallpaper i3wm i3blocks dunst kitty
            # Pillow dependencies
            sudo apk add python3-dev jpeg-dev zlib-dev
            ;;
        *)
            echo "Unknown package manager. Please install manually:"
            echo "- python3, python3-venv, python3-pip"
            echo "- xwallpaper"
            echo "- i3-wm, i3blocks, dunst, kitty"
            echo "- Development packages for Python image processing (libjpeg, zlib)"
            read -p "Press Enter when dependencies are installed..."
            ;;
    esac
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
    pip install Pillow
    
    echo "Virtual environment created at: $VENV_DIR"
    echo "Python packages installed: $(pip list --format=columns)"
    
    deactivate
}

# Check for optional dependencies
check_optional_deps() {
    echo "Checking optional dependencies..."
    
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
    install_system_packages "$PM"
    
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