#!/usr/bin/env python3
import json
import sys
import os
import math
from PIL import Image

def extract_dominant_colors(image_path, num_colors=32):
    """Extracts dominant colors from an image using Pillow."""
    if not os.path.exists(image_path):
        print(f"Error: Image path '{image_path}' does not exist.")
        sys.exit(1)
        
    img = Image.open(image_path)
    img = img.resize((100, 100))
    quantized = img.quantize(colors=num_colors)
    palette = quantized.getpalette()[:num_colors*3]
    
    return [(palette[i], palette[i+1], palette[i+2]) for i in range(0, len(palette), 3)]

# --- OKLAB / RGB CONVERSION MATH ---
def rgb_to_oklch(rgb):
    r, g, b = [((c / 255.0) + 0.055 / 1.055) ** 2.4 if (c / 255.0) > 0.04045 else (c / 255.0) / 12.92 for c in rgb]
    l = 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b
    m = 0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b
    s = 0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b
    l_ = l**(1/3) if l > 0 else 0
    m_ = m**(1/3) if m > 0 else 0
    s_ = s**(1/3) if s > 0 else 0
    L = 0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_
    a = 1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_
    b_ = 0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_
    C = math.sqrt(a**2 + b_**2)
    H = math.degrees(math.atan2(b_, a))
    if H < 0: H += 360
    return L, C, H

def oklch_to_hex(L, C, H):
    H_rad = math.radians(H)
    a = C * math.cos(H_rad)
    b_ = C * math.sin(H_rad)
    l_ = L + 0.3963377774 * a + 0.2158037573 * b_
    m_ = L - 0.1055613458 * a - 0.0638541728 * b_
    s_ = L - 0.0894841775 * a - 1.2914855480 * b_
    l, m, s = l_**3, m_**3, s_**3
    r = +4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s
    g = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s
    b = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s
    rgb = []
    for c in (r, g, b):
        c_clamped = max(0.0, min(1.0, c))
        if c_clamped > 0.0031308:
            rgb.append(int((1.055 * (c_clamped ** (1.0 / 2.4)) - 0.055) * 255))
        else:
            rgb.append(int(12.92 * c_clamped * 255))
    return '#{:02x}{:02x}{:02x}'.format(rgb[0], rgb[1], rgb[2])

# --- PALETTE GENERATION ---
def generate_palette(image_path, mode="dark"):
    raw_colors = extract_dominant_colors(image_path, num_colors=32)
    oklch_colors = [rgb_to_oklch(c) for c in raw_colors]
    
    # Filter out dead grays
    vibrant_colors = [c for c in oklch_colors if c[1] > 0.04]
    if not vibrant_colors:
        vibrant_colors = oklch_colors
        
    vibrant_colors.sort(key=lambda x: x[1], reverse=True)
    accent_h, accent_c, accent_h_angle = vibrant_colors[0]
    
    secondary_candidates = [c for c in vibrant_colors if abs(c[2] - accent_h_angle) > 30]
    sec_h, sec_c, sec_h_angle = secondary_candidates[0] if secondary_candidates else (vibrant_colors[1] if len(vibrant_colors) > 1 else (accent_h, accent_c, (accent_h_angle + 45) % 360))

    # 1. System Status Colors (Slightly altered lightness depending on mode)
    status_l = 0.55 if mode == "light" else 0.65
    status_chroma = max(accent_c, 0.14)
    info = oklch_to_hex(status_l, status_chroma, 230)
    success = oklch_to_hex(status_l, status_chroma, 140)
    warning = oklch_to_hex(status_l + 0.05, status_chroma, 85)
    danger = oklch_to_hex(status_l - 0.05, status_chroma, 25)

    # 2. Setup Mode-Specific Backgrounds & Foregrounds
    if mode == "light":
        bg_chroma = min(accent_c, 0.015) # Very clean tinting for light mode
        bgBase = oklch_to_hex(0.98, bg_chroma, accent_h_angle)    # Crisp white base
        bgSurface = oklch_to_hex(0.93, bg_chroma, accent_h_angle) # Soft light gray
        bgOverlay = oklch_to_hex(0.85, bg_chroma, accent_h_angle) # Noticeably darker overlay
        
        fg_chroma = min(accent_c, 0.02)
        fgBase = oklch_to_hex(0.18, fg_chroma, accent_h_angle)    # Deep charcoal text
        fgDim = oklch_to_hex(0.38, fg_chroma, accent_h_angle)     # Muted gray text
        fgSubtle = oklch_to_hex(0.60, fg_chroma, accent_h_angle)  # Light disabled text
        
        borderInactive = oklch_to_hex(0.80, bg_chroma, accent_h_angle)
    else:
        bg_chroma = min(accent_c, 0.02)
        bgBase = oklch_to_hex(0.14, bg_chroma, accent_h_angle)
        bgSurface = oklch_to_hex(0.20, bg_chroma, accent_h_angle)
        bgOverlay = oklch_to_hex(0.28, bg_chroma, accent_h_angle)
        
        fg_chroma = min(accent_c, 0.01)
        fgBase = oklch_to_hex(0.92, fg_chroma, accent_h_angle)
        fgDim = oklch_to_hex(0.72, fg_chroma, accent_h_angle)
        fgSubtle = oklch_to_hex(0.48, fg_chroma, accent_h_angle)
        
        borderInactive = oklch_to_hex(0.24, bg_chroma, accent_h_angle)

    # 3. Accents
    accent_l_clamped = max(0.45, min(accent_h, 0.65))
    accentStrong = oklch_to_hex(accent_l_clamped, accent_c, accent_h_angle)
    
    if mode == "light":
        accentDim = oklch_to_hex(min(0.85, accent_l_clamped + 0.15), accent_c - 0.02, accent_h_angle)
        secondary = oklch_to_hex(min(0.50, sec_h), sec_c, sec_h_angle) # Pull down secondary brightness if too high
    else:
        accentDim = oklch_to_hex(max(0.25, accent_l_clamped - 0.15), accent_c, accent_h_angle)
        secondary = oklch_to_hex(max(0.55, sec_h), sec_c, sec_h_angle)

    # 4. Dynamic Contrast Guardrail for onAccent
    onAccent = "#000000" if accent_l_clamped > 0.62 else "#ffffff"
    borderActive = accentStrong

    return {
        "bgBase": bgBase, "bgSurface": bgSurface, "bgOverlay": bgOverlay,
        "fgBase": fgBase, "onAccent": onAccent, "fgDim": fgDim, "fgSubtle": fgSubtle,
        "accentStrong": accentStrong, "accentDim": accentDim, "secondary": secondary,
        "info": info, "success": success, "warning": warning, "danger": danger,
        "borderActive": borderActive, "borderInactive": borderInactive
    }

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python color_extractor.py <path_to_image> [--light]")
        sys.exit(1)
        
    img_path = sys.argv[1]
    theme_mode = "light" if "--light" in sys.argv else "dark"
    
    print(json.dumps(generate_palette(img_path, theme_mode), indent=4))
