#!/usr/bin/env python3

import os
import sys
import subprocess
import colorsys
import json
from PIL import Image
from sklearn.cluster import KMeans
import numpy as np


class ColorProcessor:
    """Advanced color extraction and theme generation system"""
    
    def __init__(self, config_paths):
        self.config_paths = config_paths
    
    def rgb_to_hex(self, r, g, b):
        """Convert RGB to hex color"""
        return f'#{r:02x}{g:02x}{b:02x}'
    
    def hex_to_rgb(self, hex_color):
        """Convert hex to RGB tuple"""
        hex_color = hex_color.lstrip('#')
        return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))
    
    def get_luminance(self, r, g, b):
        """Calculate luminance using WCAG formula"""
        def normalize(c):
            c = c / 255.0
            return c / 12.92 if c <= 0.03928 else pow((c + 0.055) / 1.055, 2.4)
        
        r, g, b = normalize(r), normalize(g), normalize(b)
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    
    def get_contrast_ratio(self, color1, color2):
        """Calculate contrast ratio between two colors"""
        lum1 = self.get_luminance(*self.hex_to_rgb(color1))
        lum2 = self.get_luminance(*self.hex_to_rgb(color2))
        lighter = max(lum1, lum2)
        darker = min(lum1, lum2)
        return (lighter + 0.05) / (darker + 0.05)
    
    def ensure_text_contrast(self, bg_color, min_contrast=4.5):
        """Ensure readable text color for background"""
        white_contrast = self.get_contrast_ratio(bg_color, '#ffffff')
        black_contrast = self.get_contrast_ratio(bg_color, '#000000')
        
        if white_contrast >= min_contrast:
            return '#ffffff'
        elif black_contrast >= min_contrast:
            return '#000000'
        else:
            return '#ffffff' if white_contrast > black_contrast else '#000000'
    
    def create_readable_text_color(self, bg_color, accent_colors, min_contrast=4.5, prefer_color=True):
        """Generate readable text color with optional color preference"""
        bg_r, bg_g, bg_b = self.hex_to_rgb(bg_color)
        bg_luminance = self.get_luminance(bg_r, bg_g, bg_b)
        
        candidates = []
        
        # Try color-based candidates if preferred
        if prefer_color and min_contrast <= 3.0:
            for accent in accent_colors:
                accent_r, accent_g, accent_b = accent
                h, l, s = colorsys.rgb_to_hls(accent_r/255.0, accent_g/255.0, accent_b/255.0)
                
                if bg_luminance < 0.3:
                    ultra_bright = colorsys.hls_to_rgb(h, 0.8, min(s * 2.0, 1.0))
                else:
                    ultra_bright = colorsys.hls_to_rgb(h, 0.2, min(s * 2.0, 1.0))
                
                candidate = self.rgb_to_hex(int(ultra_bright[0]*255), int(ultra_bright[1]*255), int(ultra_bright[2]*255))
                contrast = self.get_contrast_ratio(bg_color, candidate)
                
                if contrast >= min_contrast:
                    candidates.append((candidate, contrast, 2.0, 0.8))
        
        # Generate brightness variations
        for accent in accent_colors:
            accent_hex = self.rgb_to_hex(*accent)
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
                candidate = self.rgb_to_hex(int(r*255), int(g*255), int(b*255))
                contrast = self.get_contrast_ratio(bg_color, candidate)
                
                if contrast >= min_contrast:
                    color_distance = abs(target_l - 1.0) + abs(target_l - 0.0)
                    candidates.append((candidate, contrast, color_distance, target_l))
        
        if not candidates:
            return self.ensure_text_contrast(bg_color, min_contrast)
        
        if prefer_color:
            candidates.sort(key=lambda x: (-x[2], -x[1]))
        else:
            candidates.sort(key=lambda x: (-x[1], -x[2]))
        
        if prefer_color and len(candidates) > 3:
            top_colorful = [c for c in candidates if c[2] > 1.0]
            if top_colorful:
                return top_colorful[0][0]
        
        return candidates[0][0]
    
    def adjust_brightness(self, hex_color, factor):
        """Adjust brightness of hex color by factor"""
        hex_color = hex_color.lstrip('#')
        r, g, b = tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))
        h, l, s = colorsys.rgb_to_hls(r/255.0, g/255.0, b/255.0)
        l = max(0, min(1, l * factor))
        r, g, b = colorsys.hls_to_rgb(h, l, s)
        return self.rgb_to_hex(int(r*255), int(g*255), int(b*255))
    
    def ensure_minimum_brightness(self, hex_color, min_brightness=0.15):
        """Ensure color has minimum brightness"""
        r, g, b = self.hex_to_rgb(hex_color)
        h, l, s = colorsys.rgb_to_hls(r/255.0, g/255.0, b/255.0)
        if l < min_brightness:
            l = min_brightness
            r, g, b = colorsys.hls_to_rgb(h, l, s)
            return self.rgb_to_hex(int(r*255), int(g*255), int(b*255))
        return hex_color
    
    def extract_dominant_colors_kmeans(self, image_path, n_colors=5):
        """Extract dominant colors using k-means clustering for better performance"""
        try:
            img = Image.open(image_path)
            img = img.convert('RGB')
            
            # Resize for performance but keep reasonable quality
            img = img.resize((100, 100))
            
            # Convert to numpy array
            data = np.array(img)
            data = data.reshape((-1, 3))
            
            # Sample random pixels for very large images
            if len(data) > 10000:
                indices = np.random.choice(len(data), 10000, replace=False)
                data = data[indices]
            
            # Use k-means clustering
            kmeans = KMeans(n_clusters=n_colors, random_state=42, n_init=10)
            kmeans.fit(data)
            
            # Get cluster centers (dominant colors)
            colors = kmeans.cluster_centers_.astype(int)
            
            # Filter out blacks and whites, ensure we have good colors
            filtered_colors = []
            for color in colors:
                r, g, b = color
                # Skip blacks and whites
                if (r < 30 and g < 30 and b < 30) or (r > 225 and g > 225 and b > 225):
                    continue
                filtered_colors.append(tuple(color))
            
            # Fallback colors if not enough found
            if len(filtered_colors) < n_colors:
                fallback_colors = [(120, 80, 60), (80, 120, 100), (100, 80, 120), (90, 90, 70), (70, 90, 90)]
                filtered_colors.extend(fallback_colors[:n_colors - len(filtered_colors)])
            
            return filtered_colors[:n_colors]
            
        except Exception as e:
            print(f'Error extracting colors: {e}', file=sys.stderr)
            return [(120, 80, 60), (80, 120, 100), (100, 80, 120), (90, 90, 70), (70, 90, 90)]
    
    def update_config_safely(self, config_path, update_func, colors):
        """Update config file"""
        try:
            update_func(config_path, colors)
            return True
        except Exception as e:
            print(f'Error updating {config_path}: {e}', file=sys.stderr)
            return False
    
    def update_i3_config(self, config_path, colors):
        """Update i3 window manager config"""
        with open(config_path, 'r') as f:
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
        
        primary = self.rgb_to_hex(*most_vibrant)
        primary = self.ensure_minimum_brightness(primary, 0.25)
        secondary = self.adjust_brightness(primary, 0.7)
        tertiary = self.adjust_brightness(primary, 0.4)
        quaternary = self.adjust_brightness(primary, 0.2)
        
        focused_text = self.create_readable_text_color(primary, colors, 3.5)
        inactive_text = self.create_readable_text_color(secondary, colors, 2.5)
        unfocused_text = self.create_readable_text_color(tertiary, colors, 2.0)
        
        new_window_colors = f'''# class                 border  backgr. text    indicator child_border
client.focused          {primary} {primary} {focused_text} {primary}   {primary}
client.focused_inactive {secondary} {secondary} {inactive_text} {secondary}   {secondary}
client.unfocused        {tertiary} {tertiary} {unfocused_text} {tertiary}   {tertiary}
client.urgent           #ff4444 #ff4444 #ffffff #ff4444   #ff4444
client.placeholder      {quaternary} {quaternary} {self.create_readable_text_color(quaternary, colors, 1.8)} {quaternary}   {quaternary}'''
        
        import re
        pattern = r'# class\s+border\s+backgr\.\s+text\s+indicator\s+child_border.*?client\.placeholder.*?#[0-9a-fA-F]{6}(?:\s+#[0-9a-fA-F]{6}\s+#[0-9a-fA-F]{6}\s+#[0-9a-fA-F]{6}\s+#[0-9a-fA-F]{6})*'
        config = re.sub(pattern, new_window_colors, config, flags=re.DOTALL)
        
        bar_bg = self.adjust_brightness(primary, 0.15)
        bar_bg = self.ensure_minimum_brightness(bar_bg, 0.1)
        bar_text = self.create_readable_text_color(bar_bg, colors, 3.0)
        bar_sep = self.adjust_brightness(primary, 0.3)
        
        workspace_text = self.create_readable_text_color(primary, colors, 3.0)
        
        new_bar_colors = f'''    colors {{
        background {bar_bg}
        statusline {bar_text}
        separator {bar_sep}
        focused_workspace  {primary} {primary} {workspace_text}
        active_workspace   {secondary} {secondary} {self.create_readable_text_color(secondary, colors, 3.0)}
        inactive_workspace {tertiary} {tertiary} {self.create_readable_text_color(tertiary, colors, 2.5)}
        urgent_workspace   #f38ba8 #f38ba8 #000000
        binding_mode       #f9e2af #f9e2af #000000
    }}'''
        
        pattern = r'colors\s*\{[^}]*\}'
        config = re.sub(pattern, new_bar_colors, config, flags=re.DOTALL)
        
        with open(config_path, 'w') as f:
            f.write(config)
        
        print(f'Updated i3 config with primary color: {primary}', file=sys.stderr)
    
    def update_kitty_config(self, config_path, colors):
        """Update kitty terminal config"""
        with open(config_path, 'r') as f:
            config = f.read()
        
        primary = self.rgb_to_hex(*colors[0])
        bg_color = self.adjust_brightness(primary, 0.08)
        bg_color = self.ensure_minimum_brightness(bg_color, 0.05)
        
        fg_color = self.create_readable_text_color(bg_color, colors[1:3], 3.0, prefer_color=True)
        selection_bg = self.adjust_brightness(primary, 0.3)
        selection_bg = self.ensure_minimum_brightness(selection_bg, 0.2)
        selection_fg = self.create_readable_text_color(selection_bg, colors, 3.0)
        
        cursor_color = self.adjust_brightness(primary, 0.7)
        cursor_color = self.ensure_minimum_brightness(cursor_color, 0.4)
        
        import re
        config = re.sub(r'foreground\s+#[0-9a-fA-F]{6}', f'foreground {fg_color}', config)
        config = re.sub(r'background\s+#[0-9a-fA-F]{6}', f'background {bg_color}', config)
        config = re.sub(r'selection_background\s+#[0-9a-fA-F]{6}', f'selection_background {selection_bg}', config)
        config = re.sub(r'selection_foreground\s+#[0-9a-fA-F]{6}', f'selection_foreground {selection_fg}', config)
        config = re.sub(r'cursor\s+#[0-9a-fA-F]{6}', f'cursor {cursor_color}', config)
        
        with open(config_path, 'w') as f:
            f.write(config)
        
        print(f'Updated kitty config with contrast ratio: {self.get_contrast_ratio(bg_color, fg_color):.1f}:1', file=sys.stderr)
    
    def update_dunst_config(self, config_path, colors):
        """Update dunst notification config"""
        with open(config_path, 'r') as f:
            config = f.read()
        
        primary = self.rgb_to_hex(*colors[0])
        secondary = self.rgb_to_hex(*colors[1]) if len(colors) > 1 else self.adjust_brightness(primary, 0.8)
        
        bg_color = self.adjust_brightness(primary, 0.15)
        bg_color = self.ensure_minimum_brightness(bg_color, 0.1)
        
        fg_color = self.create_readable_text_color(bg_color, colors, 3.5, prefer_color=True)
        frame_color = self.adjust_brightness(secondary, 0.6)
        frame_color = self.ensure_minimum_brightness(frame_color, 0.3)
        
        import re
        config = re.sub(r'background\s*=\s*"#[0-9a-fA-F]{6}"', f'background = "{bg_color}"', config)
        config = re.sub(r'foreground\s*=\s*"#[0-9a-fA-F]{6}"', f'foreground = "{fg_color}"', config)
        config = re.sub(r'frame_color\s*=\s*"#[0-9a-fA-F]{6}"', f'frame_color = "{frame_color}"', config)
        
        with open(config_path, 'w') as f:
            f.write(config)
        
        print(f'Updated dunst config: bg={bg_color}, fg={fg_color}, frame={frame_color}', file=sys.stderr)
    
    def update_i3blocks_config(self, config_path, colors):
        """Update i3blocks status bar config"""
        with open(config_path, 'r') as f:
            config = f.read()
        
        # Generate gradient colors from wallpaper
        primary = self.rgb_to_hex(*colors[0])
        primary = self.ensure_minimum_brightness(primary, 0.3)
        
        # Create a smooth gradient from primary color
        gradient_colors = []
        base_h, base_l, base_s = colorsys.rgb_to_hls(*[c/255.0 for c in colors[0]])
        
        # Generate 12 colors in a gradient
        for i in range(12):
            hue_shift = (i * 30) % 360 / 360.0
            new_h = (base_h + hue_shift * 0.3) % 1.0
            new_l = 0.4 + (0.4 * (i / 11.0))
            new_s = min(base_s * 1.4, 0.9)
            
            r, g, b = colorsys.hls_to_rgb(new_h, new_l, new_s)
            color_hex = self.rgb_to_hex(int(r*255), int(g*255), int(b*255))
            gradient_colors.append(color_hex)
        
        blocks = [
            'wifi_info', 'cpu_info', 'gpu_info', 'memory_usage',
            'disk_usage', 'volume', 'brightness', 'date',
            'time', 'battery'
        ]
        
        lines = config.split('\n')
        new_lines = []
        current_block = None
        
        for line in lines:
            if line.startswith('[') and line.endswith(']'):
                current_block = line[1:-1]
            elif line.startswith('color=#') and current_block in blocks:
                block_index = blocks.index(current_block)
                if block_index < len(gradient_colors):
                    line = f'color={gradient_colors[block_index]}'
            new_lines.append(line)
        
        config = '\n'.join(new_lines)
        
        with open(config_path, 'w') as f:
            f.write(config)
        
        print(f'Updated i3blocks config with gradient from {primary}', file=sys.stderr)
    
    def update_hyprland_config(self, config_path, colors):
        """Update Hyprland window manager config"""
        with open(config_path, 'r') as f:
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
        
        primary = self.rgb_to_hex(*most_vibrant)
        primary = self.ensure_minimum_brightness(primary, 0.25)
        secondary = self.adjust_brightness(primary, 0.7)
        
        # Convert hex to rgba format for Hyprland
        def hex_to_rgba(hex_color, alpha="ee"):
            hex_color = hex_color.lstrip('#')
            return f"rgba({hex_color}{alpha})"
        
        primary_rgba = hex_to_rgba(primary, "ee")
        secondary_rgba = hex_to_rgba(secondary, "aa")
        
        import re
        
        # Update active border
        config = re.sub(r'col\.active_border\s*=\s*rgba\([0-9a-fA-F]{8}\)\s*rgba\([0-9a-fA-F]{8}\)\s*\d+deg',
                       f'col.active_border = {primary_rgba} {primary_rgba} 45deg', config)
        
        # Update inactive border  
        config = re.sub(r'col\.inactive_border\s*=\s*rgba\([0-9a-fA-F]{8}\)',
                       f'col.inactive_border = {secondary_rgba}', config)
        
        with open(config_path, 'w') as f:
            f.write(config)
        
        print(f'Updated Hyprland config with primary color: {primary}', file=sys.stderr)
    
    def update_waybar_config(self, config_path, colors):
        """Update Waybar config"""
        if not os.path.exists(config_path):
            print(f'Warning: Waybar config not found at {config_path}', file=sys.stderr)
            return
            
        try:
            with open(config_path, 'r') as f:
                waybar_config = json.load(f)
        except Exception as e:
            print(f'Warning: Could not parse Waybar config: {e}', file=sys.stderr)
            return
        
        # Update waybar config if needed
        print(f'Waybar config exists but no color updates needed (handled by CSS)', file=sys.stderr)
    
    def update_waybar_style(self, style_path, colors):
        """Update Waybar CSS style"""
        if not os.path.exists(style_path):
            print(f'Warning: Waybar style not found at {style_path}', file=sys.stderr)
            return
            
        try:
            with open(style_path, 'r') as f:
                css = f.read()
        except Exception as e:
            print(f'Warning: Could not read Waybar style: {e}', file=sys.stderr)
            return
        
        primary = self.rgb_to_hex(*colors[0])
        primary = self.ensure_minimum_brightness(primary, 0.3)
        secondary = self.adjust_brightness(primary, 0.7)
        tertiary = self.adjust_brightness(primary, 0.4)
        
        bg_color = self.adjust_brightness(primary, 0.1)
        bg_color = self.ensure_minimum_brightness(bg_color, 0.05)
        
        text_color = self.create_readable_text_color(bg_color, colors, 3.0)
        
        import re
        
        # Update CSS custom properties if they exist
        css = re.sub(r'--primary:\s*#[0-9a-fA-F]{6};', f'--primary: {primary};', css)
        css = re.sub(r'--secondary:\s*#[0-9a-fA-F]{6};', f'--secondary: {secondary};', css)
        css = re.sub(r'--background:\s*#[0-9a-fA-F]{6};', f'--background: {bg_color};', css)
        css = re.sub(r'--text:\s*#[0-9a-fA-F]{6};', f'--text: {text_color};', css)
        
        # Update common background colors
        css = re.sub(r'background-color:\s*#[0-9a-fA-F]{6};', f'background-color: {bg_color};', css)
        css = re.sub(r'background:\s*#[0-9a-fA-F]{6};', f'background: {bg_color};', css)
        css = re.sub(r'color:\s*#[0-9a-fA-F]{6};', f'color: {text_color};', css)
        
        try:
            with open(style_path, 'w') as f:
                f.write(css)
            print(f'Updated Waybar style with primary color: {primary}', file=sys.stderr)
        except Exception as e:
            print(f'Warning: Could not write Waybar style: {e}', file=sys.stderr)
    
    def update_mako_config(self, config_path, colors):
        """Update Mako notification config"""
        primary = self.rgb_to_hex(*colors[0])
        secondary = self.rgb_to_hex(*colors[1]) if len(colors) > 1 else self.adjust_brightness(primary, 0.8)
        
        bg_color = self.adjust_brightness(primary, 0.15)
        bg_color = self.ensure_minimum_brightness(bg_color, 0.1)
        
        fg_color = self.create_readable_text_color(bg_color, colors, 3.5, prefer_color=True)
        border_color = self.adjust_brightness(secondary, 0.6)
        border_color = self.ensure_minimum_brightness(border_color, 0.3)
        
        if not os.path.exists(config_path):
            # Create a basic mako config if it doesn't exist
            config_dir = os.path.dirname(config_path)
            os.makedirs(config_dir, exist_ok=True)
            
            config_content = f"""# Mako notification daemon config
background-color={bg_color}
text-color={fg_color}
border-color={border_color}
border-size=2
border-radius=5
default-timeout=5000
font=Victor Mono 11
"""
        else:
            with open(config_path, 'r') as f:
                config_content = f.read()
            
            import re
            config_content = re.sub(r'background-color\s*=\s*#[0-9a-fA-F]{6}', f'background-color={bg_color}', config_content)
            config_content = re.sub(r'text-color\s*=\s*#[0-9a-fA-F]{6}', f'text-color={fg_color}', config_content)
            config_content = re.sub(r'border-color\s*=\s*#[0-9a-fA-F]{6}', f'border-color={border_color}', config_content)
        
        with open(config_path, 'w') as f:
            f.write(config_content)
        
        print(f'Updated Mako config: bg={bg_color}, fg={fg_color}, border={border_color}', file=sys.stderr)
    
    def update_nvim_config(self, config_path, colors):
        """Update Neovim config with extracted colors"""
        with open(config_path, 'r') as f:
            config = f.read()
        
        primary = self.rgb_to_hex(*colors[0])
        secondary = self.rgb_to_hex(*colors[1]) if len(colors) > 1 else self.adjust_brightness(primary, 0.8)
        tertiary = self.rgb_to_hex(*colors[2]) if len(colors) > 2 else self.adjust_brightness(primary, 0.6)
        
        # Generate background and UI colors
        bg_color = self.adjust_brightness(primary, 0.08)
        bg_color = self.ensure_minimum_brightness(bg_color, 0.05)
        
        cursor_line_bg = self.adjust_brightness(bg_color, 1.5)
        line_nr_bg = bg_color
        
        # Generate foreground and text colors
        fg_color = self.create_readable_text_color(bg_color, colors, 3.0, prefer_color=True)
        line_nr_fg = self.adjust_brightness(primary, 0.4)
        cursor_line_nr_fg = primary
        
        # Selection colors
        selection_bg = self.adjust_brightness(primary, 0.3)
        selection_bg = self.ensure_minimum_brightness(selection_bg, 0.2)
        selection_fg = self.create_readable_text_color(selection_bg, colors, 3.0)
        
        # Search highlighting
        search_bg = primary
        search_fg = self.create_readable_text_color(search_bg, colors, 4.0, prefer_color=False)
        inc_search_bg = secondary
        inc_search_fg = self.create_readable_text_color(inc_search_bg, colors, 4.0, prefer_color=False)
        
        # UI elements
        status_line_bg = self.adjust_brightness(primary, 0.2)
        status_line_fg = self.create_readable_text_color(status_line_bg, colors, 3.0)
        status_line_nc_bg = self.adjust_brightness(bg_color, 1.2)
        status_line_nc_fg = self.adjust_brightness(primary, 0.4)
        
        vert_split_fg = selection_bg
        
        # Popup menu
        pmenu_bg = status_line_bg
        pmenu_fg = status_line_fg
        pmenu_sel_bg = selection_bg
        pmenu_sel_fg = selection_fg
        
        # Syntax highlighting colors
        comment_fg = self.adjust_brightness(primary, 0.5)
        string_fg = tertiary
        number_fg = primary
        function_fg = secondary
        keyword_fg = self.adjust_brightness(secondary, 1.2)
        type_fg = self.adjust_brightness(tertiary, 1.1)
        special_fg = primary
        
        # Error and warning colors
        error_fg = "#ff6b6b"
        error_bg = "#2a0a0a"
        warning_fg = "#ffa500" 
        warning_bg = "#2a1a00"
        
        # Build the new color scheme block
        new_colors = f'''\" Custom color scheme to match kitty Deep Space theme
highlight Normal guifg={fg_color} guibg={bg_color}
highlight CursorLine guibg={cursor_line_bg}
highlight LineNr guifg={line_nr_fg} guibg={line_nr_bg}
highlight CursorLineNr guifg={cursor_line_nr_fg} guibg={cursor_line_bg} gui=bold
highlight Visual guifg={selection_fg} guibg={selection_bg}
highlight Search guifg={search_fg} guibg={search_bg}
highlight IncSearch guifg={inc_search_fg} guibg={inc_search_bg}
highlight StatusLine guifg={status_line_fg} guibg={status_line_bg}
highlight StatusLineNC guifg={status_line_nc_fg} guibg={status_line_nc_bg}
highlight VertSplit guifg={vert_split_fg} guibg={bg_color}
highlight Pmenu guifg={pmenu_fg} guibg={pmenu_bg}
highlight PmenuSel guifg={pmenu_sel_fg} guibg={pmenu_sel_bg}
highlight Comment guifg={comment_fg} gui=italic
highlight String guifg={string_fg}
highlight Number guifg={number_fg}
highlight Function guifg={function_fg}
highlight Keyword guifg={keyword_fg} gui=bold
highlight Type guifg={type_fg}
highlight Special guifg={special_fg}
highlight Error guifg={error_fg} guibg={error_bg}
highlight Warning guifg={warning_fg} guibg={warning_bg}'''
        
        import re
        # Replace the entire color scheme block
        pattern = r'\" Custom color scheme to match kitty Deep Space theme.*?highlight Warning guifg=#[0-9a-fA-F]{6} guibg=#[0-9a-fA-F]{6}'
        config = re.sub(pattern, new_colors, config, flags=re.DOTALL)
        
        with open(config_path, 'w') as f:
            f.write(config)
        
        print(f'Updated nvim config: bg={bg_color}, fg={fg_color}, accent={primary}', file=sys.stderr)
    
    def update_razer_keyboard(self, colors):
        """Update Razer keyboard RGB colors"""
        try:
            # Turn off current effects
            subprocess.run(['polychromatic-cli', '--device', 'laptop', '--zone', 'main', '--option', 'none'],
                          capture_output=True)
            
            # Get primary colors and enhance for keyboard
            primary_raw = self.rgb_to_hex(*colors[0])
            primary_r, primary_g, primary_b = self.hex_to_rgb(primary_raw)
            primary_h, primary_l, primary_s = colorsys.rgb_to_hls(primary_r/255.0, primary_g/255.0, primary_b/255.0)
            
            deep_s = min(primary_s * 1.8, 1.0)
            deep_l = max(primary_l * 0.8, 0.25)
            
            deep_r, deep_g, deep_b = colorsys.hls_to_rgb(primary_h, deep_l, deep_s)
            primary = self.rgb_to_hex(int(deep_r*255), int(deep_g*255), int(deep_b*255))
            
            secondary_raw = self.rgb_to_hex(*colors[1]) if len(colors) > 1 else self.adjust_brightness(primary_raw, 0.7)
            secondary = self.adjust_brightness(secondary_raw, 0.6)
            secondary = self.ensure_minimum_brightness(secondary, 0.25)
            
            # Try static color first
            cmd = ['polychromatic-cli', '--device', 'laptop', '--zone', 'main',
                   '--option', 'static', '--colours', primary]
            result = subprocess.run(cmd, capture_output=True, text=True)
            
            if result.returncode == 0:
                mode = 'static'
            else:
                cmd = ['polychromatic-cli', '--device', 'laptop', '--zone', 'main',
                       '--option', 'wave', '--parameter', '1', '--colours', primary]
                subprocess.run(cmd, capture_output=True)
                mode = 'wave'
            
            # Set logo color
            cmd2 = ['polychromatic-cli', '--device', 'laptop', '--zone', 'logo',
                    '--option', 'static', '--colours', secondary]
            subprocess.run(cmd2, capture_output=True)
            
            print(f'Updated Razer keyboard: {mode} mode with {primary}, logo={secondary}', file=sys.stderr)
            
        except Exception as e:
            print(f'Error updating Razer keyboard: {e}', file=sys.stderr)
    
    def process_wallpaper(self, wallpaper_path):
        """Main method to process wallpaper and update all configs"""
        try:
            # Extract colors using improved k-means method
            colors = self.extract_dominant_colors_kmeans(wallpaper_path)
            
            # Track success/failure for each config update
            results = {}
            
            # Update each config safely with backup/rollback
            for config_name, config_path in self.config_paths.items():
                if not config_path or not os.path.exists(config_path):
                    if config_path:  # Only warn if path was specified
                        print(f'Warning: Config file not found: {config_path}', file=sys.stderr)
                    continue
                    
                if config_name == 'i3':
                    results[config_name] = self.update_config_safely(config_path, self.update_i3_config, colors)
                elif config_name == 'hyprland':
                    results[config_name] = self.update_config_safely(config_path, self.update_hyprland_config, colors)
                elif config_name == 'kitty':
                    results[config_name] = self.update_config_safely(config_path, self.update_kitty_config, colors)
                elif config_name == 'dunst':
                    results[config_name] = self.update_config_safely(config_path, self.update_dunst_config, colors)
                elif config_name == 'mako':
                    results[config_name] = self.update_config_safely(config_path, self.update_mako_config, colors)
                elif config_name == 'i3blocks':
                    results[config_name] = self.update_config_safely(config_path, self.update_i3blocks_config, colors)
                elif config_name == 'waybar':
                    results[config_name] = self.update_config_safely(config_path, self.update_waybar_config, colors)
                elif config_name == 'waybar_style':
                    results[config_name] = self.update_config_safely(config_path, self.update_waybar_style, colors)
                elif config_name == 'nvim':
                    results[config_name] = self.update_config_safely(config_path, self.update_nvim_config, colors)
            
            # Update Razer keyboard (doesn't need backup)
            try:
                self.update_razer_keyboard(colors)
                results['razer'] = True
            except Exception:
                results['razer'] = False
            
            # Report results
            successful = [k for k, v in results.items() if v]
            failed = [k for k, v in results.items() if not v]
            
            if successful:
                print(f'Successfully updated: {", ".join(successful)}', file=sys.stderr)
            if failed:
                print(f'Failed to update: {", ".join(failed)}', file=sys.stderr)
            
                
            return len(failed) == 0
            
        except Exception as e:
            print(f'Critical error processing wallpaper: {e}', file=sys.stderr)
            return False


def main():
    if len(sys.argv) < 3:
        print("Usage: color_processor.py <wallpaper_path> <wm_type> [config_paths...]", file=sys.stderr)
        print("  wm_type: 'i3' or 'hyprland'", file=sys.stderr)
        print("  For i3: <wallpaper_path> i3 <i3_config> <kitty_config> <dunst_config> <i3blocks_config>", file=sys.stderr)
        print("  For hyprland: <wallpaper_path> hyprland <hyprland_config> <kitty_config> <mako_config> [waybar_config] [waybar_style]", file=sys.stderr)
        sys.exit(1)
    
    wallpaper_path = sys.argv[1]
    wm_type = sys.argv[2]
    
    if wm_type == "i3":
        if len(sys.argv) != 8:
            print("Usage for i3: color_processor.py <wallpaper_path> i3 <i3_config> <kitty_config> <dunst_config> <i3blocks_config> <nvim_config>", file=sys.stderr)
            sys.exit(1)
        config_paths = {
            'i3': sys.argv[3],
            'kitty': sys.argv[4],
            'dunst': sys.argv[5],
            'i3blocks': sys.argv[6],
            'nvim': sys.argv[7]
        }
    elif wm_type == "hyprland":
        if len(sys.argv) < 7:
            print("Usage for hyprland: color_processor.py <wallpaper_path> hyprland <hyprland_config> <kitty_config> <mako_config> [waybar_config] [waybar_style] <nvim_config>", file=sys.stderr)
            sys.exit(1)
        config_paths = {
            'hyprland': sys.argv[3],
            'kitty': sys.argv[4],
            'mako': sys.argv[5],
            'waybar': sys.argv[6] if len(sys.argv) > 6 and sys.argv[6] != 'None' else None,
            'waybar_style': sys.argv[7] if len(sys.argv) > 7 and sys.argv[7] != 'None' else None,
            'nvim': sys.argv[8] if len(sys.argv) > 8 else (sys.argv[6] if len(sys.argv) == 7 else None)
        }
    else:
        print(f"Error: Unknown window manager type '{wm_type}'. Use 'i3' or 'hyprland'", file=sys.stderr)
        sys.exit(1)
    
    processor = ColorProcessor(config_paths)
    success = processor.process_wallpaper(wallpaper_path)
    
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()