#!/usr/bin/env python3
import argparse
import json
import math
import os
import sys

# ==============================================================================
# COLOR SPACE MATH (sRGB <-> XYZ <-> Oklab <-> Okhsl)
# ==============================================================================

def srgb_to_linear(c):
    return c / 12.92 if c <= 0.04045 else math.pow((c + 0.055) / 1.055, 2.4)

def linear_to_srgb(c):
    return 12.92 * c if c <= 0.0031308 else 1.055 * math.pow(c, 1.0 / 2.4) - 0.055

def hex_to_rgb(hex_str):
    hex_str = hex_str.lstrip('#')
    return tuple(int(hex_str[i:i+2], 16) for i in (0, 2, 4))

def rgb_to_hex(rgb):
    return f"#{rgb[0]:02x}{rgb[1]:02x}{rgb[2]:02x}"

def rgb_to_oklab(rgb):
    r = srgb_to_linear(rgb[0] / 255.0)
    g = srgb_to_linear(rgb[1] / 255.0)
    b = srgb_to_linear(rgb[2] / 255.0)

    l_ = 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b
    m_ = 0.2119034982 * r + 0.6806995451 * g + 0.1073972632 * b
    s_ = 0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b

    l_ = math.pow(max(0, l_), 1.0 / 3.0)
    m_ = math.pow(max(0, m_), 1.0 / 3.0)
    s_ = math.pow(max(0, s_), 1.0 / 3.0)

    L = 0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_
    a = 1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_
    b = 0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_

    return L, a, b

def oklab_to_rgb(L, a, b):
    l_ = L + 0.3963377774 * a + 0.2158037573 * b
    m_ = L - 0.1055613458 * a - 0.0638541728 * b
    s_ = L - 0.0894841775 * a - 1.2914855480 * b

    l_ = l_ * l_ * l_
    m_ = m_ * m_ * m_
    s_ = s_ * s_ * s_

    r = +4.0767416621 * l_ - 3.3077115913 * m_ + 0.2309699292 * s_
    g = -1.2684380046 * l_ + 2.6097574011 * m_ - 0.3413193965 * s_
    b = -0.0041960863 * l_ - 0.7034186147 * m_ + 1.7076147010 * s_

    R = int(max(0, min(255, round(linear_to_srgb(r) * 255))))
    G = int(max(0, min(255, round(linear_to_srgb(g) * 255))))
    B = int(max(0, min(255, round(linear_to_srgb(b) * 255))))

    return R, G, B

def oklab_to_lch(L, a, b):
    C = math.sqrt(a * a + b * b)
    H = math.atan2(b, a)
    if H < 0:
        H += 2 * math.pi
    return L, C, H

def lch_to_oklab(L, C, H):
    return L, C * math.cos(H), C * math.sin(H)

# ==============================================================================
# CONVERSION ENGINE
# ==============================================================================

def clamp(val, min_val, max_val):
    return max(min_val, min(val, max_val))

def finalize(lch):
    return rgb_to_hex(oklab_to_rgb(*lch_to_oklab(*lch)))

def convert_theme_to_light(theme_dict):
    """Processes a dark palette map and converts structural elements to light mode pastels."""
    # Find original key hue based on accentStrong
    accent_rgb = hex_to_rgb(theme_dict["accentStrong"])
    _, _, base_hue = oklab_to_lch(*rgb_to_oklab(accent_rgb))
    
    # Grab secondary hue
    secondary_rgb = hex_to_rgb(theme_dict["secondary"])
    _, sec_raw_C, sec_hue = oklab_to_lch(*rgb_to_oklab(secondary_rgb))

    # Initialize Structural Layers (Soft Tinted Pastel Paper Sheet)
    bgBase      = (0.94, 0.015, base_hue)
    bgSurface_L = 0.93
    bgSurface   = (bgSurface_L, 0.020, base_hue)
    bgOverlay   = (0.87, 0.025, base_hue)

    fgBase      = (0.25, 0.030, base_hue)
    fgDim       = (0.42, 0.025, base_hue)
    fgSubtle    = (0.60, 0.020, base_hue)

    # Transform Accents directly into the target Light Pastel Envelope
    accent_strong = (0.62, 0.12, base_hue)
    secondary     = (0.66, clamp(sec_raw_C, 0.08, 0.13), sec_hue)

    # Maintain spacing between accent and secondary if they collide
    if abs(secondary[0] - accent_strong[0]) < 0.04:
        secondary = (secondary[0] + 0.05, secondary[1], secondary[2])

    # Handle text over accent
    onAccent = (0.98, 0.005, base_hue) if accent_strong[0] < 0.65 else (0.18, 0.030, base_hue)
    
    accentDim = (accent_strong[0] - 0.10, accent_strong[1] * 0.9, base_hue)
    borderInactive = (0.78, 0.020, base_hue)

    # Map existing utility hues into the light pastel ecosystem
    utils = ["info", "success", "warning", "danger"]
    util_palette = {}
    for u in utils:
        u_rgb = hex_to_rgb(theme_dict[u])
        _, _, u_hue = oklab_to_lch(*rgb_to_oklab(u_rgb))
        
        # Apply light mode constant baseline weights to utility lines
        if u == "warning":
            util_palette[u] = finalize((0.69, 0.10, u_hue))
        elif u == "danger" or u == "info":
            util_palette[u] = finalize((0.63, 0.11, u_hue))
        else: # success
            util_palette[u] = finalize((0.65, 0.09, u_hue))

    return {
        "name": theme_dict.get("name", "Unnamed Theme"),
        "description": theme_dict.get("description", "Converted to Pastel Light Mode."),
        "bgBase": finalize(bgBase),
        "bgSurface": finalize(bgSurface),
        "bgOverlay": finalize(bgOverlay),
        "fgBase": finalize(fgBase),
        "onAccent": finalize(onAccent),
        "fgDim": finalize(fgDim),
        "fgSubtle": finalize(fgSubtle),
        "accentStrong": finalize(accent_strong),
        "accentDim": finalize(accentDim),
        "secondary": finalize(secondary),
        "info": util_palette["info"],
        "success": util_palette["success"],
        "warning": util_palette["warning"],
        "danger": util_palette["danger"],
        "borderActive": finalize(accent_strong),
        "borderInactive": finalize(borderInactive),
    }

def main():
    parser = argparse.ArgumentParser(description="Convert colors.json layouts based on targeted modes.")
    parser.add_argument("file", help="Path to your colors.json database file")
    
    # Force mutually exclusive required tags
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--light", action="store_true", help="Transform themes into pastel light mode")
    group.add_argument("--dark", action="store_true", help="Preserve exact original dark layout configurations")
    
    args = parser.parse_args()

    if not os.path.exists(args.file):
        print(f"Error: Database file '{args.file}' not found.", file=sys.stderr)
        sys.exit(1)

    with open(args.file, "r") as f:
        try:
            data = json.load(f)
        except json.JSONDecodeError:
            print("Error: Invalid JSON formatting in target file.", file=sys.stderr)
            sys.exit(1)

    output = {}
    for theme_key, theme_content in data.items():
        if args.dark:
            # Leave completely untouched as per rules
            output[theme_key] = theme_content
        elif args.light:
            # Re-generate architectural elements to fit light pastels
            output[theme_key] = convert_theme_to_light(theme_content)

    print(json.dumps(output, indent=2))

if __name__ == "__main__":
    main()
