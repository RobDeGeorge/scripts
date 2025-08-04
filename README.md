# Linux Desktop Theme Kit

🎨 A portable Linux desktop setup that automatically changes your entire system theme based on your wallpaper! Works on any Linux distro with i3wm.

## What It Does

🖼️ **Smart Wallpaper Cycling** - Automatically extracts colors from your wallpapers  
🎨 **Dynamic Theming** - Updates your entire desktop theme to match the wallpaper  
⚡ **Fully Portable** - Works on any Linux distro (Ubuntu, Arch, Fedora, etc.)  
🎯 **One-Click Setup** - Everything installs automatically

**What gets themed:**
- i3 window manager (borders, gaps, workspace colors)
- Terminal (kitty with matching colors)  
- Status bar (i3blocks with color gradients)
- Notifications (dunst styling)
- Razer keyboard RGB (if you have one)

## Quick Start

```bash
# 1. Download and make executable
chmod +x *.sh

# 2. Run setup (detects your distro automatically)
./restore-configs.sh

# 3. Add your wallpapers to ~/Pictures/Wallpapers/

# 4. Restart i3 (Mod+Shift+R) or reboot
```

That's it! Press `Mod+Shift+W` to cycle wallpapers and watch your theme change.

## How It Works

The system extracts dominant colors from each wallpaper and calculates contrast-safe color schemes for all your applications. Everything updates in real-time when you change wallpapers.

**Includes configs for:**
- `i3` - Window manager with gaps and custom keybinds
- `kitty` - Terminal emulator  
- `i3blocks` - Status bar
- `dunst` - Notifications
- `bashrc` - Shell configuration

## Compatibility

Works on any Linux distribution:
✅ Ubuntu/Debian (apt)  
✅ Arch/Manjaro (pacman)  
✅ Fedora (dnf)  
✅ openSUSE (zypper)  
✅ Alpine (apk)

## Tips

- **Backup existing configs:** The installer automatically backs up your current settings
- **Customize colors:** Edit color functions in `wallpaper-cycler.sh` 
- **Sync changes:** Use `./sync-configs.sh` to save modifications back to this folder