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
    b_ = 0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_

    return L, a, b_

def oklab_to_rgb(L, a, b):
    l_ = L + 0.3963377774 * a + 0.2158037573 * b
    m_ = L - 0.1055613458 * a - 0.0638541728 * b
    s_ = L - 0.0894841775 * a - 1.2914855480 * b

    l_ = l_ * l_ * l_
    m_ = m_ * m_ * m_
    s_ = s_ * s_ * s_

    r = +4.0767416621 * l_ - 3.3077115913 * m_ + 0.2309699292 * s_
    g = -1.2684380046 * l_ + 2.6097574011 * m_ - 0.3413193965 * s_
    b_ = -0.0041960863 * l_ - 0.7034186147 * m_ + 1.7076147010 * s_

    R = int(max(0, min(255, round(linear_to_srgb(r) * 255))))
    G = int(max(0, min(255, round(linear_to_srgb(g) * 255))))
    B = int(max(0, min(255, round(linear_to_srgb(b_) * 255))))

    return R, G, B

def oklab_to_lch(L, a, b):
    C = math.sqrt(a * a + b * b)
    H = math.atan2(b, a) % (2 * math.pi)
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

def scale_to_pastel(lch, is_light_mode):
    """Dynamic clamping that allows grayscale to remain grayscale."""
    L, C, H = lch
    min_C = min(C, 0.08 if is_light_mode else 0.10)
    max_C = 0.14 if is_light_mode else 0.16
    
    new_L = clamp(L, 0.55, 0.70) if is_light_mode else clamp(L, 0.45, 0.60)
    new_C = clamp(C, min_C, max_C)
    
    return (new_L, new_C, H)

def convert_theme_to_light(theme_dict):
    # 1. Extract raw data from dark mode
    acc_rgb = hex_to_rgb(theme_dict["accentStrong"])
    acc_raw_L, acc_raw_C, base_hue = oklab_to_lch(*rgb_to_oklab(acc_rgb))
    
    sec_rgb = hex_to_rgb(theme_dict["secondary"])
    sec_raw_L, sec_raw_C, sec_hue = oklab_to_lch(*rgb_to_oklab(sec_rgb))

    # 2. Desaturation Multiplier for Grayscale Themes
    bg_C_scale = min(1.0, acc_raw_C / 0.05)

    # 3. Structural Layers (Matches extractor's light mode exactly)
    bgBase    = (0.70, 0.015 * bg_C_scale, base_hue)
    bgSurface = (0.93, 0.020 * bg_C_scale, base_hue)
    bgOverlay = (0.87, 0.025 * bg_C_scale, base_hue)
    fgBase    = (0.25, 0.030 * bg_C_scale, base_hue)
    fgDim     = (0.42, 0.025 * bg_C_scale, base_hue)
    fgSubtle  = (0.60, 0.020 * bg_C_scale, base_hue)

    # 4. Transform Accents
    accent_strong = scale_to_pastel((acc_raw_L, acc_raw_C, base_hue), True)
    secondary     = scale_to_pastel((sec_raw_L, sec_raw_C, sec_hue), True)

    # Separation offset (-0.05 L for light mode)
    if abs(secondary[0] - accent_strong[0]) < 0.04:
        secondary = (clamp(secondary[0] - 0.05, 0.45, 0.75), secondary[1], secondary[2])

    onAccent = (0.98, 0.005, base_hue) if accent_strong[0] < 0.65 else (0.18, 0.030, base_hue)
    accentDim = (
        clamp(accent_strong[0] - 0.10, 0.30, 0.90),
        accent_strong[1] * 0.9,
        accent_strong[2],
    )
    borderInactive = (0.78, 0.020, base_hue)

    # 5. Utility Colors (Extract original hue, apply fixed L/C, blend with base_hue)
    util_L = 0.65
    util_C = 0.20

    def blend_hue_local(target, weight=0.15):
        x = (1 - weight) * math.cos(target) + weight * math.cos(base_hue)
        y = (1 - weight) * math.sin(target) + weight * math.sin(base_hue)
        return math.atan2(y, x)

    util_palette = {}
    for u in ["info", "success", "warning", "danger"]:
        u_rgb = hex_to_rgb(theme_dict[u])
        _, _, u_hue = oklab_to_lch(*rgb_to_oklab(u_rgb))
        
        if u == "danger":
            u_lch = (util_L - 0.02, util_C + 0.02, blend_hue_local(u_hue))
        elif u == "warning":
            u_lch = (util_L + 0.04, util_C + 0.01, blend_hue_local(u_hue))
        elif u == "success":
            u_lch = (util_L,        util_C - 0.05, blend_hue_local(u_hue))
        else: # info
            u_lch = (util_L - 0.02, util_C - 0.01, blend_hue_local(u_hue))
            
        util_palette[u] = finalize(u_lch)

    return {
        "name": theme_dict.get("name", "Unnamed Theme") + " (Light)",
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
            output[theme_key] = theme_content
        elif args.light:
            output[theme_key] = convert_theme_to_light(theme_content)

    print(json.dumps(output, indent=2))

if __name__ == "__main__":
    main()
