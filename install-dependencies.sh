#!/bin/bash

set -e

# Get script directory (root kit directory)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIT_DIR="$SCRIPT_DIR"
VENV_DIR="$KIT_DIR/theming-engine/wallpaper-venv"

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
            command -v swaybg &> /dev/null || missing+=("swaybg")
            command -v hyprlock &> /dev/null || missing+=("hyprlock")
            command -v grim &> /dev/null || missing+=("grim")
            command -v slurp &> /dev/null || missing+=("slurp")
            command -v xrandr &> /dev/null || missing+=("xrandr")
            command -v unzip &> /dev/null || missing+=("unzip")
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
    command -v convert &> /dev/null || missing+=("imagemagick")
    
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
                    wm_packages="hyprland waybar mako-notifier swaybg hyprlock grim slurp xwayland"
                    ;;
                "pacman")
                    wm_packages="hyprland waybar mako swaybg hyprlock grim slurp xorg-xwayland xorg-xrandr unzip"
                    ;;
                "dnf"|"yum")
                    wm_packages="hyprland waybar mako swaybg hyprlock grim slurp xorg-x11-server-Xwayland"
                    ;;
                "zypper")
                    wm_packages="hyprland waybar mako swaybg hyprlock grim slurp xwayland"
                    ;;
                "apk")
                    wm_packages="hyprland waybar mako swaybg hyprlock grim slurp xwayland"
                    ;;
            esac
            ;;
        "i3")
            case "$pm" in
                "apt")
                    wm_packages="xwallpaper i3-wm i3blocks dunst scrot picom xss-lock i3lock imagemagick"
                    ;;
                "pacman")
                    wm_packages="xwallpaper i3-wm i3blocks dunst scrot picom xss-lock i3lock imagemagick"
                    ;;
                "dnf"|"yum")
                    wm_packages="xwallpaper i3 i3blocks dunst scrot picom xss-lock i3lock imagemagick"
                    ;;
                "zypper")
                    wm_packages="xwallpaper i3 i3blocks dunst scrot picom xss-lock i3lock imagemagick"
                    ;;
                "apk")
                    wm_packages="xwallpaper i3wm i3blocks dunst picom xss-lock i3lock imagemagick"
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
            "python3"|"python3-venv"|"python3-pip"|"xwallpaper"|"i3"|"i3blocks"|"dunst"|"kitty"|"scrot"|"pamixer"|"brightnessctl"|"pulseaudio-utils"|"picom"|"xss-lock"|"i3lock"|"imagemagick"|"network-manager-gnome"|"wireless-tools"|"lm-sensors"|"acpi")
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

    local need_recreate=false
    local system_python_version=$(python3 --version 2>&1 | cut -d' ' -f2 | cut -d'.' -f1,2)

    # Check if venv exists and is compatible
    if [ -d "$VENV_DIR" ]; then
        if [ -f "$VENV_DIR/bin/python" ]; then
            local venv_python_version=$("$VENV_DIR/bin/python" --version 2>&1 | cut -d' ' -f2 | cut -d'.' -f1,2 2>/dev/null || echo "unknown")

            if [ "$venv_python_version" = "$system_python_version" ]; then
                # Check if packages are installed
                if "$VENV_DIR/bin/python" -c "import PIL; import sklearn; import numpy" 2>/dev/null; then
                    echo "✓ Virtual environment exists and is compatible (Python $venv_python_version)"
                    return 0
                else
                    echo "Virtual environment exists but packages missing, reinstalling..."
                    need_recreate=false
                fi
            else
                echo "Python version mismatch (venv: $venv_python_version, system: $system_python_version)"
                need_recreate=true
            fi
        else
            echo "Virtual environment corrupted, recreating..."
            need_recreate=true
        fi
    else
        need_recreate=true
    fi

    # Remove existing venv if needed
    if [ "$need_recreate" = true ] && [ -d "$VENV_DIR" ]; then
        echo "Removing incompatible virtual environment..."
        rm -rf "$VENV_DIR"
    fi

    # Create new venv if needed
    if [ ! -d "$VENV_DIR" ]; then
        echo "Creating virtual environment (Python $system_python_version)..."
        python3 -m venv "$VENV_DIR"
    fi

    # Activate and install packages
    source "$VENV_DIR/bin/activate"

    echo "Installing Python packages..."
    pip install --upgrade pip --quiet
    pip install Pillow scikit-learn numpy --quiet

    echo "✓ Virtual environment ready at: $VENV_DIR"
    echo "  Packages: Pillow, scikit-learn, numpy"

    deactivate
}

# Check for font dependencies
check_fonts() {
    echo "Checking fonts..."
    
    local victor_found=false
    local bilbo_found=false
    
    # Check for VictorMono Nerd Font
    if fc-list | grep -i "victor.*mono.*nerd" &> /dev/null; then
        echo "✓ VictorMono Nerd Font found"
        victor_found=true
    else
        echo "Warning: VictorMono Nerd Font not found."
    fi
    
    # Check for Bilbo font
    if fc-list | grep -i "bilbo" &> /dev/null; then
        echo "✓ Bilbo font found"
        bilbo_found=true
    else
        echo "Warning: Bilbo font not found."
    fi
    
    if [ "$victor_found" = false ] || [ "$bilbo_found" = false ]; then
        return 1
    else
        return 0
    fi
}

# Install font if missing
install_fonts() {
    local pm="$1"

    echo "Installing fonts..."

    # Create fonts directory
    mkdir -p ~/.local/share/fonts

    # Install VictorMono Nerd Font
    if ! fc-list | grep -qi "victormono\|victor mono" &> /dev/null; then
        echo "Installing VictorMono Nerd Font..."

        # Try AUR first on Arch
        local font_installed=false
        if [ "$pm" = "pacman" ]; then
            if command -v yay &> /dev/null; then
                yay -S --noconfirm ttf-victor-mono-nerd 2>/dev/null && font_installed=true
            elif command -v paru &> /dev/null; then
                paru -S --noconfirm ttf-victor-mono-nerd 2>/dev/null && font_installed=true
            fi
        fi

        # Fallback to manual installation
        if [ "$font_installed" = false ]; then
            echo "Downloading VictorMono Nerd Font manually..."
            local font_tmp="/tmp/victormono_$$"
            mkdir -p "$font_tmp"
            curl -fL "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/VictorMono.zip" -o "$font_tmp/VictorMono.zip"
            if [ -f "$font_tmp/VictorMono.zip" ]; then
                unzip -qo "$font_tmp/VictorMono.zip" -d "$font_tmp"
                cp "$font_tmp"/*.ttf ~/.local/share/fonts/ 2>/dev/null || true
                rm -rf "$font_tmp"
                echo "VictorMono Nerd Font installed manually"
            else
                echo "Warning: Failed to download VictorMono Nerd Font"
            fi
        fi
    else
        echo "✓ VictorMono Nerd Font already installed"
    fi

    # Install Bilbo font
    if ! fc-list | grep -qi "bilbo" &> /dev/null; then
        echo "Installing Bilbo font..."
        curl -fL "https://github.com/google/fonts/raw/main/ofl/bilbo/Bilbo-Regular.ttf" -o ~/.local/share/fonts/Bilbo-Regular.ttf
    else
        echo "✓ Bilbo font already installed"
    fi

    # Update font cache
    echo "Updating font cache..."
    fc-cache -f

    echo "Font installation complete!"
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

# Install AUR helper (Arch Linux only)
install_aur_helper() {
    local pm="$1"

    if [ "$pm" != "pacman" ]; then
        return 0
    fi

    if command -v yay &> /dev/null; then
        echo "✓ yay (AUR helper) already installed"
        return 0
    fi

    if command -v paru &> /dev/null; then
        echo "✓ paru (AUR helper) already installed"
        return 0
    fi

    echo "Installing yay (AUR helper)..."
    sudo pacman -S --needed --noconfirm base-devel git

    local yay_tmp="/tmp/yay_install_$$"
    git clone https://aur.archlinux.org/yay.git "$yay_tmp"
    cd "$yay_tmp" && makepkg -si --noconfirm
    cd - > /dev/null
    rm -rf "$yay_tmp"

    if command -v yay &> /dev/null; then
        echo "✓ yay installed successfully"
    else
        echo "Warning: yay installation failed"
        return 1
    fi
}

# Install OpenRazer and Polychromatic (for Razer RGB devices)
install_razer_support() {
    local pm="$1"

    echo ""
    echo "Razer RGB Support"
    echo "-----------------"

    # Check if already installed
    if command -v polychromatic-cli &> /dev/null && systemctl --user is-active openrazer-daemon &> /dev/null; then
        echo "✓ OpenRazer and Polychromatic already installed and running"
        return 0
    fi

    read -p "Do you want to install Razer RGB support (OpenRazer + Polychromatic)? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping Razer RGB support"
        return 0
    fi

    case "$pm" in
        "pacman")
            if ! command -v yay &> /dev/null && ! command -v paru &> /dev/null; then
                echo "Error: AUR helper (yay/paru) required for OpenRazer on Arch"
                return 1
            fi

            local aur_helper="yay"
            command -v paru &> /dev/null && aur_helper="paru"

            echo "Installing OpenRazer and Polychromatic from AUR..."
            $aur_helper -S --noconfirm openrazer-daemon openrazer-driver-dkms polychromatic

            # Create plugdev group if it doesn't exist
            if ! getent group plugdev &> /dev/null; then
                sudo groupadd plugdev
            fi

            # Add user to required groups
            sudo gpasswd -a "$USER" plugdev
            if getent group openrazer &> /dev/null; then
                sudo gpasswd -a "$USER" openrazer
            fi

            # Enable the daemon
            systemctl --user enable openrazer-daemon

            echo ""
            echo "OpenRazer installed! You need to REBOOT for the driver to load."
            echo "After reboot, run: systemctl --user start openrazer-daemon"
            ;;
        "apt")
            echo "Adding OpenRazer PPA..."
            sudo add-apt-repository -y ppa:openrazer/stable
            sudo apt update
            sudo apt install -y openrazer-daemon openrazer-driver-dkms polychromatic
            sudo gpasswd -a "$USER" plugdev
            systemctl --user enable openrazer-daemon
            echo "OpenRazer installed! You need to REBOOT for the driver to load."
            ;;
        *)
            echo "Please install OpenRazer manually for your distro:"
            echo "https://openrazer.github.io/#download"
            ;;
    esac
}

# Main installation process
main() {
    echo "============================================="
    echo "  Linux Desktop Theme Kit - Setup Script"
    echo "============================================="
    echo ""

    # Check if running as root
    if [ "$EUID" -eq 0 ]; then
        echo "Error: Don't run this script as root (sudo will be used when needed)"
        exit 1
    fi

    # Detect package manager
    PM=$(detect_package_manager)
    echo "Detected package manager: $PM"
    echo "Detected window manager: $WM"
    echo ""

    # Install AUR helper first (Arch only) - needed for some packages
    if [ "$PM" = "pacman" ]; then
        install_aur_helper "$PM"
    fi

    # Install system packages
    echo ""
    echo "System Packages"
    echo "---------------"
    install_system_packages "$PM" "$WM"

    # Check and install fonts
    echo ""
    echo "Fonts"
    echo "-----"
    if ! check_fonts; then
        install_fonts "$PM"
    fi

    # Setup Python virtual environment
    echo ""
    echo "Python Environment"
    echo "------------------"
    setup_python_venv

    # Optional: Razer RGB support
    install_razer_support "$PM"

    # Check optional dependencies
    echo ""
    echo "Optional Dependencies"
    echo "---------------------"
    check_optional_deps

    echo ""
    echo "============================================="
    echo "  Installation Complete!"
    echo "============================================="
    echo ""
    echo "Next steps:"
    echo "  1. Run: ./restore-configs.sh"
    echo "     (Deploys your saved configs to ~/.config)"
    echo ""
    echo "  2. Test wallpaper cycling:"
    echo "     ./theming-engine/wallpaper-cycler.sh"
    echo ""
    echo "  3. Keybind (after config restore):"
    echo "     Super + Shift + W = Cycle wallpaper & theme"
    echo ""
    echo "Virtual environment: $VENV_DIR"
    echo ""
    if [ "$PM" = "pacman" ]; then
        echo "Note: If you installed OpenRazer, REBOOT is required!"
    fi
}

# Run main function
main "$@"