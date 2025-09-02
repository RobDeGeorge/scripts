# Linux Desktop Theme Kit

🎨 A portable Linux desktop setup that automatically changes your entire system theme based on your wallpaper! Works on any Linux distro with **i3wm** or **Hyprland**.

## What It Does

🖼️ **Smart Wallpaper Cycling** - Automatically extracts colors from your wallpapers  
🎨 **Dynamic Theming** - Updates your entire desktop theme to match the wallpaper  
⚡ **Fully Portable** - Works on any Linux distro (Ubuntu, Arch, Fedora, etc.)  
🎯 **One-Click Setup** - Everything installs automatically

**What gets themed:**
- **i3wm**: Window borders, gaps, workspace colors, i3blocks status bar, dunst notifications
- **Hyprland**: Window borders, gaps, waybar status bar, mako notifications
- **Terminal**: kitty with matching colors  
- **Keyboard RGB**: Razer keyboard support (if you have one)

## Quick Start

```bash
# 1. Download and make executable
chmod +x *.sh

# 2. Run setup (detects your distro automatically)
./restore-configs.sh

# 3. Add your wallpapers to ~/Pictures/Wallpapers/

# 4. Restart your window manager or reboot
```

That's it! The setup automatically detects if you're using i3 or Hyprland and installs the appropriate components. Press `Mod+Shift+W` to cycle wallpapers and watch your theme change.

## How It Works

The system extracts dominant colors from each wallpaper and calculates contrast-safe color schemes for all your applications. Everything updates in real-time when you change wallpapers.

**Includes configs for:**
- **Window Managers**: `i3` or `hyprland` with gaps and custom keybinds
- **Terminal**: `kitty` emulator  
- **Status Bars**: `i3blocks` (i3) or `waybar` (Hyprland)
- **Notifications**: `dunst` (i3) or `mako` (Hyprland)
- **Shell**: `bashrc` configuration

## Compatibility

Works on any Linux distribution:
✅ Ubuntu/Debian (apt)  
✅ Arch/Manjaro (pacman)  
✅ Fedora (dnf)  
✅ openSUSE (zypper)  
✅ Alpine (apk)

## Tips

- **Automatic detection:** The system detects i3 or Hyprland and sets up accordingly
- **Backup existing configs:** The installer automatically backs up your current settings  
- **Customize colors:** Edit color functions in `wallpaper-cycler.sh`
- **Sync changes:** Use `./sync-configs.sh` to save modifications back to this folder