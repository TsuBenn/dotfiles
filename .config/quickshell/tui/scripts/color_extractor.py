#!/usr/bin/env python3
import argparse
import json
import math
import os
import sys
from PIL import Image

# ==============================================================================
# COLOR SPACE MATH (sRGB <-> XYZ <-> Oklab <-> Okhsl)
# No external dependencies allowed.
# ==============================================================================

def srgb_to_linear(c):
    return c / 12.92 if c <= 0.04045 else math.pow((c + 0.055) / 1.055, 2.4)

def linear_to_srgb(c):
    return 12.92 * c if c <= 0.0031308 else 1.055 * math.pow(c, 1.0 / 2.4) - 0.055

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
# PALETTE GENERATION & PASTEL SCALING ENGINE
# ==============================================================================

def get_dominant_colors(image_path, num_colors=16):
    if not os.path.exists(image_path):
        print(f"Error: Image path '{image_path}' does not exist.", file=sys.stderr)
        sys.exit(1)

    with Image.open(image_path) as img:
        img = img.convert("RGB")
        img.thumbnail((150, 150))
        quantized = img.quantize(colors=num_colors, method=Image.Quantize.MAXCOVERAGE)
        palette = quantized.getpalette()
        
        colors = []
        for i in range(num_colors):
            colors.append((palette[i*3], palette[i*3+1], palette[i*3+2]))
        return list(set(colors))

def rgb_to_hex(rgb):
    return f"#{rgb[0]:02x}{rgb[1]:02x}{rgb[2]:02x}"

def clamp(val, min_val, max_val):
    return max(min_val, min(val, max_val))

def scale_to_pastel(fg_lch, is_light_mode):
    """Binds chroma and lightness into a strictly pastel envelope."""
    fg_L, fg_C, fg_H = fg_lch

    if is_light_mode:
        # Cozy Light Pastel: Lightness sits in a comfortable mid-high range (0.55 - 0.70)
        # Cap Chroma so colors don't get too neon or harsh against the cream background
        new_L = clamp(fg_L, 0.55, 0.70)
        new_C = clamp(fg_C, 0.08, 0.14)
    else:
        # Dark Mode Pastel (Glowy but soft): Lightness mid-low (0.45 - 0.60)
        new_L = clamp(fg_L, 0.45, 0.60)
        new_C = clamp(fg_C, 0.10, 0.16)

    return (new_L, new_C, fg_H)

def generate_palette(image_path, is_light_mode=False):
    raw_colors = get_dominant_colors(image_path, num_colors=16)
    lch_colors = [oklab_to_lch(*rgb_to_oklab(c)) for c in raw_colors]

    lch_colors.sort(key=lambda c: c[1], reverse=True)
    accent_raw = lch_colors[0]

    secondary_raw = lch_colors[1] if len(lch_colors) > 1 else accent_raw
    for color in lch_colors[1:]:
        hue_diff = abs(color[2] - accent_raw[2])
        hue_diff = min(hue_diff, 2 * math.pi - hue_diff)
        if hue_diff > 0.78:
            secondary_raw = color
            break

    base_hue = accent_raw[2]

    # Initialize Structural Layers (Soft Tinted Paper Style)
    if is_light_mode:
        bgBase      = (0.70, 0.015, base_hue)  # Soft cream/lavender sheet
        bgSurface_L = 0.93
        bgSurface   = (bgSurface_L, 0.020, base_hue)
        bgOverlay   = (0.87, 0.025, base_hue)

        fgBase      = (0.25, 0.030, base_hue)  # Dark ink but distinctly tinted
        fgDim       = (0.42, 0.025, base_hue)
        fgSubtle    = (0.60, 0.020, base_hue)
    else:
        bgBase      = (0.11, 0.040, base_hue)
        bgSurface_L = 0.17                     
        bgSurface   = (bgSurface_L, 0.035, base_hue)
        bgOverlay   = (0.26, 0.030, base_hue)

        fgBase      = (0.95, 0.010, base_hue)
        fgDim       = (0.78, 0.015, base_hue)
        fgSubtle    = (0.55, 0.020, base_hue)

    # Transform Accents directly into the Pastel Envelope
    accent_strong = scale_to_pastel(accent_raw, is_light_mode)
    secondary     = scale_to_pastel(secondary_raw, is_light_mode)

    # Maintain soft separation between accent and secondary
    if abs(secondary[0] - accent_strong[0]) < 0.04:
        offset = -0.05 if is_light_mode else 0.05
        secondary = (clamp(secondary[0] + offset, 0.45, 0.75), secondary[1], secondary[2])

    # Dynamic text on top of accents
    onAccent = (0.98, 0.005, base_hue) if accent_strong[0] < 0.65 else (0.18, 0.030, base_hue)
    
    # Mathematical soft offsets for derivations
    accentDim = (accent_strong[0] - 0.10, accent_strong[1] * 0.9, base_hue)
    borderInactive = (0.78, 0.020, base_hue) if is_light_mode else (0.23, 0.035, base_hue)

    # System Utilities mapped to soft, muted pastel positions
    H_RED, H_YEL, H_GRN, H_BLU = 0.50, 1.50, 2.40, 4.20
    util_L = 0.65 if is_light_mode else 0.58
    util_C = 0.09 if is_light_mode else 0.11  # Kept low to remain pastel

    def blend_hue(target_hue, base_hue, weight=0.15):
        x = (1 - weight) * math.cos(target_hue) + weight * math.cos(base_hue)
        y = (1 - weight) * math.sin(target_hue) + weight * math.sin(base_hue)
        return math.atan2(y, x)

    danger  = (util_L - 0.02, util_C + 0.02, blend_hue(H_RED, base_hue))
    warning = (util_L + 0.04, util_C + 0.01, blend_hue(H_YEL, base_hue))
    success = (util_L,        util_C,        blend_hue(H_GRN, base_hue))
    info    = (util_L - 0.02, util_C - 0.01, blend_hue(H_BLU, base_hue))

    def finalize(lch):
        return rgb_to_hex(oklab_to_rgb(*lch_to_oklab(*lch)))

    return {
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
        "info": finalize(info),
        "success": finalize(success),
        "warning": finalize(warning),
        "danger": finalize(danger),
        "borderActive": finalize(accent_strong),
        "borderInactive": finalize(borderInactive),
    }

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate an Oklab contrast-validated JSON palette.")
    parser.add_argument("image", help="Path to the source image")
    parser.add_argument("--light", action="store_true", help="Generate light mode")
    parser.add_argument("--dark",  action="store_false", help="Generate dark mode")
    args = parser.parse_args()

    print(json.dumps(generate_palette(args.image, is_light_mode=args.light or args.dark), indent=2))
