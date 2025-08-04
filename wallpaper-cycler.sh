#!/bin/bash

# Get script directory for relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="${VENV_DIR:-$SCRIPT_DIR/wallpaper-venv}"

# Configuration with fallbacks
WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}"
INDEX_FILE="${INDEX_FILE:-${HOME}/.wallpaper_index}"
I3_CONFIG="${I3_CONFIG:-${HOME}/.config/i3/config}"
I3BLOCKS_CONFIG="${I3BLOCKS_CONFIG:-${HOME}/.config/i3blocks/config}"
KITTY_CONFIG="${KITTY_CONFIG:-${HOME}/.config/kitty/kitty.conf}"
DUNST_CONFIG="${DUNST_CONFIG:-${HOME}/.config/dunst/dunstrc}"

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
    
    python3 -c "
import os
import sys
import subprocess
from PIL import Image
import colorsys

def rgb_to_hex(r, g, b):
    return f'#{r:02x}{g:02x}{b:02x}'

def hex_to_rgb(hex_color):
    hex_color = hex_color.lstrip('#')
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))

def get_luminance(r, g, b):
    def normalize(c):
        c = c / 255.0
        return c / 12.92 if c <= 0.03928 else pow((c + 0.055) / 1.055, 2.4)
    
    r, g, b = normalize(r), normalize(g), normalize(b)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b

def get_contrast_ratio(color1, color2):
    lum1 = get_luminance(*hex_to_rgb(color1))
    lum2 = get_luminance(*hex_to_rgb(color2))
    lighter = max(lum1, lum2)
    darker = min(lum1, lum2)
    return (lighter + 0.05) / (darker + 0.05)

def ensure_text_contrast(bg_color, min_contrast=4.5):
    white_contrast = get_contrast_ratio(bg_color, '#ffffff')
    black_contrast = get_contrast_ratio(bg_color, '#000000')
    
    if white_contrast >= min_contrast:
        return '#ffffff'
    elif black_contrast >= min_contrast:
        return '#000000'
    else:
        return '#ffffff' if white_contrast > black_contrast else '#000000'

def create_readable_text_color(bg_color, accent_colors, min_contrast=4.5, prefer_color=True):
    bg_r, bg_g, bg_b = hex_to_rgb(bg_color)
    bg_luminance = get_luminance(bg_r, bg_g, bg_b)
    
    candidates = []
    
    if prefer_color and min_contrast <= 3.0:
        for accent in accent_colors:
            accent_r, accent_g, accent_b = accent
            h, l, s = colorsys.rgb_to_hls(accent_r/255.0, accent_g/255.0, accent_b/255.0)
            
            if bg_luminance < 0.3:
                ultra_bright = colorsys.hls_to_rgb(h, 0.8, min(s * 2.0, 1.0))
            else:
                ultra_bright = colorsys.hls_to_rgb(h, 0.2, min(s * 2.0, 1.0))
            
            candidate = rgb_to_hex(int(ultra_bright[0]*255), int(ultra_bright[1]*255), int(ultra_bright[2]*255))
            contrast = get_contrast_ratio(bg_color, candidate)
            
            if contrast >= min_contrast:
                candidates.append((candidate, contrast, 2.0, 0.8))
    
    for accent in accent_colors:
        accent_hex = rgb_to_hex(*accent)
        accent_r, accent_g, accent_b = accent
        h, l, s = colorsys.rgb_to_hls(accent_r/255.0, accent_g/255.0, accent_b/255.0)
        
        brightness_range = [0.95, 0.9, 0.85, 0.8, 0.75, 0.7, 0.65, 0.6, 0.55, 0.5, 0.45, 0.4, 0.35, 0.3, 0.25, 0.2, 0.15, 0.1, 0.05]
        
        for brightness in brightness_range:
            if bg_luminance < 0.3:
                target_l = max(brightness, 0.4)
            elif bg_luminance < 0.7:
                target_l = brightness
            else:
                target_l = min(brightness, 0.3)
            
            boosted_s = min(s * 1.6, 1.0)
            r, g, b = colorsys.hls_to_rgb(h, target_l, boosted_s)
            candidate = rgb_to_hex(int(r*255), int(g*255), int(b*255))
            contrast = get_contrast_ratio(bg_color, candidate)
            
            if contrast >= min_contrast:
                color_distance = abs(target_l - 1.0) + abs(target_l - 0.0)
                candidates.append((candidate, contrast, color_distance, target_l))
        
        for brightness in brightness_range:
            candidate = adjust_brightness(accent_hex, brightness)
            contrast = get_contrast_ratio(bg_color, candidate)
            
            if contrast >= min_contrast:
                color_distance = abs(brightness - 1.0) + abs(brightness - 0.0)
                candidates.append((candidate, contrast, color_distance, brightness))
    
    if not candidates:
        return ensure_text_contrast(bg_color, min_contrast)
    
    if prefer_color:
        candidates.sort(key=lambda x: (-x[2], -x[1]))
    else:
        candidates.sort(key=lambda x: (-x[1], -x[2]))
    
    if prefer_color and len(candidates) > 3:
        top_colorful = [c for c in candidates if c[2] > 1.0]
        if top_colorful:
            return top_colorful[0][0]
    
    return candidates[0][0]

def adjust_brightness(hex_color, factor):
    hex_color = hex_color.lstrip('#')
    r, g, b = tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))
    h, l, s = colorsys.rgb_to_hls(r/255.0, g/255.0, b/255.0)
    l = max(0, min(1, l * factor))
    r, g, b = colorsys.hls_to_rgb(h, l, s)
    return rgb_to_hex(int(r*255), int(g*255), int(b*255))

def ensure_minimum_brightness(hex_color, min_brightness=0.15):
    r, g, b = hex_to_rgb(hex_color)
    h, l, s = colorsys.rgb_to_hls(r/255.0, g/255.0, b/255.0)
    if l < min_brightness:
        l = min_brightness
        r, g, b = colorsys.hls_to_rgb(h, l, s)
        return rgb_to_hex(int(r*255), int(g*255), int(b*255))
    return hex_color

def extract_dominant_colors(image_path):
    try:
        img = Image.open(image_path)
        img = img.convert('RGB')
        img = img.resize((150, 150))
        
        colors = img.getcolors(maxcolors=256*256*256)
        colors = sorted(colors, key=lambda x: x[0], reverse=True)
        
        dominant_colors = []
        for count, color in colors:
            r, g, b = color
            # Skip blacks and whites
            if (r < 30 and g < 30 and b < 30) or (r > 225 and g > 225 and b > 225):
                continue
            
            dominant_colors.append(color)
            if len(dominant_colors) >= 5:
                break
                
        # Simple fallback
        if len(dominant_colors) < 5:
            dominant_colors.extend([(120, 80, 60), (80, 120, 100), (100, 80, 120), (90, 90, 70), (70, 90, 90)])
        
        return dominant_colors[:5]
    except Exception as e:
        print(f'Error extracting colors: {e}', file=sys.stderr)
        return [(120, 80, 60), (80, 120, 100), (100, 80, 120), (90, 90, 70), (70, 90, 90)]

def update_i3_config(colors):
    try:
        i3_config_path = '$I3_CONFIG'
        
        with open(i3_config_path, 'r') as f:
            config = f.read()
        
        # Find most vibrant color for focused window
        most_vibrant = colors[0]
        max_vibrancy = 0
        
        for color in colors:
            r, g, b = color
            color_range = max(r, g, b) - min(r, g, b)
            brightness = (r + g + b) / 3
            vibrancy = color_range * (brightness / 255.0)
            
            if vibrancy > max_vibrancy:
                max_vibrancy = vibrancy
                most_vibrant = color
        
        primary = rgb_to_hex(*most_vibrant)
        primary = ensure_minimum_brightness(primary, 0.25)
        secondary = adjust_brightness(primary, 0.7)
        tertiary = adjust_brightness(primary, 0.4) 
        quaternary = adjust_brightness(primary, 0.2)
        
        focused_text = create_readable_text_color(primary, colors, 3.5)
        inactive_text = create_readable_text_color(secondary, colors, 2.5)
        unfocused_text = create_readable_text_color(tertiary, colors, 2.0)
        
        new_window_colors = f'''# class                 border  backgr. text    indicator child_border
client.focused          {primary} {primary} {focused_text} {primary}   {primary}
client.focused_inactive {secondary} {secondary} {inactive_text} {secondary}   {secondary}
client.unfocused        {tertiary} {tertiary} {unfocused_text} {tertiary}   {tertiary}
client.urgent           #ff4444 #ff4444 #ffffff #ff4444   #ff4444
client.placeholder      {quaternary} {quaternary} {create_readable_text_color(quaternary, colors, 1.8)} {quaternary}   {quaternary}'''
        
        import re
        pattern = r'# class\s+border\s+backgr\.\s+text\s+indicator\s+child_border.*?client\.placeholder.*?#[0-9a-fA-F]{6}(?:\s+#[0-9a-fA-F]{6}\s+#[0-9a-fA-F]{6}\s+#[0-9a-fA-F]{6}\s+#[0-9a-fA-F]{6})*'
        config = re.sub(pattern, new_window_colors, config, flags=re.DOTALL)
        
        bar_bg = adjust_brightness(primary, 0.15)
        bar_bg = ensure_minimum_brightness(bar_bg, 0.1)
        bar_text = create_readable_text_color(bar_bg, colors, 3.0)
        bar_sep = adjust_brightness(primary, 0.3)
        
        workspace_text = create_readable_text_color(primary, colors, 3.0)
        
        new_bar_colors = f'''    colors {{
        background {bar_bg}
        statusline {bar_text}
        separator {bar_sep}
        focused_workspace  {primary} {primary} {workspace_text}
        active_workspace   {secondary} {secondary} {create_readable_text_color(secondary, colors, 3.0)}
        inactive_workspace {tertiary} {tertiary} {create_readable_text_color(tertiary, colors, 2.5)}
        urgent_workspace   #f38ba8 #f38ba8 #000000
        binding_mode       #f9e2af #f9e2af #000000
    }}'''
        
        pattern = r'colors\s*\{[^}]*\}'
        config = re.sub(pattern, new_bar_colors, config, flags=re.DOTALL)
        
        with open(i3_config_path, 'w') as f:
            f.write(config)
            
        print(f'Updated i3 config with primary color: {primary} (contrast-safe)', file=sys.stderr)
        
    except Exception as e:
        print(f'Error updating i3 config: {e}', file=sys.stderr)

def update_kitty_config(colors):
    try:
        kitty_config_path = '$KITTY_CONFIG'
        
        with open(kitty_config_path, 'r') as f:
            config = f.read()
        
        primary = rgb_to_hex(*colors[0])
        bg_color = adjust_brightness(primary, 0.08)
        bg_color = ensure_minimum_brightness(bg_color, 0.05)
        
        fg_color = create_readable_text_color(bg_color, colors[1:3], 3.0, prefer_color=True)
        selection_bg = adjust_brightness(primary, 0.3)
        selection_bg = ensure_minimum_brightness(selection_bg, 0.2)
        selection_fg = create_readable_text_color(selection_bg, colors, 3.0)
        
        cursor_color = adjust_brightness(primary, 0.7)
        cursor_color = ensure_minimum_brightness(cursor_color, 0.4)
        
        import re
        
        config = re.sub(r'foreground\s+#[0-9a-fA-F]{6}', f'foreground {fg_color}', config)
        config = re.sub(r'background\s+#[0-9a-fA-F]{6}', f'background {bg_color}', config)
        config = re.sub(r'selection_background\s+#[0-9a-fA-F]{6}', f'selection_background {selection_bg}', config)
        config = re.sub(r'selection_foreground\s+#[0-9a-fA-F]{6}', f'selection_foreground {selection_fg}', config)
        config = re.sub(r'cursor\s+#[0-9a-fA-F]{6}', f'cursor {cursor_color}', config)
        
        with open(kitty_config_path, 'w') as f:
            f.write(config)
            
        print(f'Updated kitty config with contrast ratio: {get_contrast_ratio(bg_color, fg_color):.1f}:1', file=sys.stderr)
        
    except Exception as e:
        print(f'Error updating kitty config: {e}', file=sys.stderr)

def update_dunst_config(colors):
    try:
        dunst_config_path = '$DUNST_CONFIG'
        
        with open(dunst_config_path, 'r') as f:
            config = f.read()
        
        primary = rgb_to_hex(*colors[0])
        secondary = rgb_to_hex(*colors[1]) if len(colors) > 1 else adjust_brightness(primary, 0.8)
        
        bg_color = adjust_brightness(primary, 0.15)
        bg_color = ensure_minimum_brightness(bg_color, 0.1)
        
        fg_color = create_readable_text_color(bg_color, colors, 3.5, prefer_color=True)
        frame_color = adjust_brightness(secondary, 0.6)
        frame_color = ensure_minimum_brightness(frame_color, 0.3)
        
        import re
        
        config = re.sub(r'background\s*=\s*\"#[0-9a-fA-F]{6}\"', f'background = \"{bg_color}\"', config)
        config = re.sub(r'foreground\s*=\s*\"#[0-9a-fA-F]{6}\"', f'foreground = \"{fg_color}\"', config)
        config = re.sub(r'frame_color\s*=\s*\"#[0-9a-fA-F]{6}\"', f'frame_color = \"{frame_color}\"', config)
        
        with open(dunst_config_path, 'w') as f:
            f.write(config)
            
        print(f'Updated dunst config with colors: bg={bg_color}, fg={fg_color}, frame={frame_color}', file=sys.stderr)
        
    except Exception as e:
        print(f'Error updating dunst config: {e}', file=sys.stderr)

def update_razer_keyboard(colors):
    try:
        import subprocess
        
        # Turn off any current effects first
        subprocess.run(['polychromatic-cli', '--device', 'laptop', '--zone', 'main', '--option', 'none'], 
                      capture_output=True)
        
        # Get primary colors and make them deeper/more saturated for low brightness
        primary_raw = rgb_to_hex(*colors[0])
        primary_r, primary_g, primary_b = hex_to_rgb(primary_raw)
        primary_h, primary_l, primary_s = colorsys.rgb_to_hls(primary_r/255.0, primary_g/255.0, primary_b/255.0)
        
        # Boost saturation and use deeper color for keyboard
        deep_s = min(primary_s * 1.8, 1.0)  # Much more saturated
        deep_l = max(primary_l * 0.8, 0.25)  # Deeper but still visible
        
        deep_r, deep_g, deep_b = colorsys.hls_to_rgb(primary_h, deep_l, deep_s)
        primary = rgb_to_hex(int(deep_r*255), int(deep_g*255), int(deep_b*255))
        
        # Secondary color for logo
        secondary_raw = rgb_to_hex(*colors[1]) if len(colors) > 1 else adjust_brightness(primary_raw, 0.7)
        secondary = adjust_brightness(secondary_raw, 0.6)
        secondary = ensure_minimum_brightness(secondary, 0.25)
        
        # Try static color first (single color across keyboard)
        cmd = ['polychromatic-cli', '--device', 'laptop', '--zone', 'main', 
               '--option', 'static', '--colours', primary]
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode == 0:
            mode = 'static'
        else:
            # Fallback: try wave effect with primary color
            cmd = ['polychromatic-cli', '--device', 'laptop', '--zone', 'main', 
                   '--option', 'wave', '--parameter', '1', '--colours', primary]
            subprocess.run(cmd, capture_output=True)
            mode = 'wave'
        
        # Set logo to secondary color for contrast
        cmd2 = ['polychromatic-cli', '--device', 'laptop', '--zone', 'logo', 
                '--option', 'static', '--colours', secondary]
        subprocess.run(cmd2, capture_output=True)
        
        print(f'Updated Razer keyboard: {mode} mode with {primary}, logo={secondary}', file=sys.stderr)
        
    except Exception as e:
        print(f'Error updating Razer keyboard: {e}', file=sys.stderr)

def update_i3blocks_config(colors):
    try:
        i3blocks_config_path = '$I3BLOCKS_CONFIG'
        
        with open(i3blocks_config_path, 'r') as f:
            config = f.read()
        
        # Generate gradient colors from wallpaper
        primary = rgb_to_hex(*colors[0])
        primary = ensure_minimum_brightness(primary, 0.3)
        
        # Create a smooth gradient from primary color
        gradient_colors = []
        base_h, base_l, base_s = colorsys.rgb_to_hls(*[c/255.0 for c in colors[0]])
        
        # Generate 12 colors in a gradient (for 12 blocks)
        for i in range(12):
            # Shift hue slightly and vary lightness/saturation
            hue_shift = (i * 30) % 360 / 360.0  # 30 degree shifts
            new_h = (base_h + hue_shift * 0.3) % 1.0  # Subtle hue variations
            
            # Vary lightness between 0.4 and 0.8 for visibility
            new_l = 0.4 + (0.4 * (i / 11.0))
            # Keep saturation high for vibrancy
            new_s = min(base_s * 1.4, 0.9)
            
            r, g, b = colorsys.hls_to_rgb(new_h, new_l, new_s)
            color_hex = rgb_to_hex(int(r*255), int(g*255), int(b*255))
            gradient_colors.append(color_hex)
        
        # Define the blocks in order as they appear in the config
        blocks = [
            'wifi_info', 'cpu_info', 'gpu_info', 'memory_usage', 
            'disk_usage', 'volume', 'brightness', 'date', 
            'time', 'battery'
        ]
        
        # Update each block's color using simple string replacement
        import re
        lines = config.split('\\n')
        new_lines = []
        current_block = None
        
        for line in lines:
            if line.startswith('[') and line.endswith(']'):
                current_block = line[1:-1]  # Extract block name
            elif line.startswith('color=#') and current_block in blocks:
                block_index = blocks.index(current_block)
                if block_index < len(gradient_colors):
                    line = f'color={gradient_colors[block_index]}'
            new_lines.append(line)
        
        config = '\\n'.join(new_lines)
        
        with open(i3blocks_config_path, 'w') as f:
            f.write(config)
            
        print(f'Updated i3blocks config with wallpaper-based gradient starting from {primary}', file=sys.stderr)
        
    except Exception as e:
        print(f'Error updating i3blocks config: {e}', file=sys.stderr)

wallpaper_path = sys.argv[1]
colors = extract_dominant_colors(wallpaper_path)
update_i3_config(colors)
update_i3blocks_config(colors)
update_kitty_config(colors)
update_dunst_config(colors)
update_razer_keyboard(colors)
" "$wallpaper_path"
}

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

if [ $? -ne 0 ] || [ -z "$WALLPAPER" ]; then
    echo "Error: Failed to get wallpaper" >&2
    exit 1
fi

echo "Setting wallpaper: $WALLPAPER" >&2
echo "Extracting colors and updating configs..." >&2

extract_colors_and_update_configs "$WALLPAPER"

xwallpaper --zoom "$WALLPAPER" &

# Restart i3 to pick up new i3blocks colors (equivalent to $mod+Shift+r)
i3-msg restart >/dev/null 2>&1

pkill dunst >/dev/null 2>&1
dunst &

notify-send "Wallpaper Updated" "New color scheme applied! 🎨" >/dev/null 2>&1 &

echo "Wallpaper and color scheme updated successfully" >&2

# Deactivate virtual environment
deactivate

exit 0