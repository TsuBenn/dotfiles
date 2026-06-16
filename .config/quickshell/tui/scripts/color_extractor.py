#!/usr/bin/env python3
import argparse
import json
import math
import os
import sys
from PIL import Image

# ==============================================================================
# COLOR SPACE CONVERSIONS
# ==============================================================================

def srgb_to_linear(c):
    return c / 12.92 if c <= 0.04045 else math.pow((c + 0.055) / 1.055, 2.4)

def linear_to_srgb(c):
    return 12.92 * c if c <= 0.0031308 else 1.055 * math.pow(c, 1.0 / 2.4) - 0.055

def rgb_to_oklab(rgb):
    r = srgb_to_linear(rgb[0] / 255.0)
    g = srgb_to_linear(rgb[1] / 255.0)
    b = srgb_to_linear(rgb[2] / 255.0)
    l_ = math.pow(max(0, 0.4122214708*r + 0.5363325363*g + 0.0514459929*b), 1/3)
    m_ = math.pow(max(0, 0.2119034982*r + 0.6806995451*g + 0.1073972632*b), 1/3)
    s_ = math.pow(max(0, 0.0883024619*r + 0.2817188376*g + 0.6299787005*b), 1/3)
    L  =  0.2104542553*l_ + 0.7936177850*m_ - 0.0040720468*s_
    a  =  1.9779984951*l_ - 2.4285922050*m_ + 0.4505937099*s_
    b_ =  0.0259040371*l_ + 0.7827717662*m_ - 0.8086757660*s_
    return L, a, b_

def oklab_to_rgb(L, a, b):
    l_ = (L + 0.3963377774*a + 0.2158037573*b) ** 3
    m_ = (L - 0.1055613458*a - 0.0638541728*b) ** 3
    s_ = (L - 0.0894841775*a - 1.2914855480*b) ** 3
    r  = +4.0767416621*l_ - 3.3077115913*m_ + 0.2309699292*s_
    g  = -1.2684380046*l_ + 2.6097574011*m_ - 0.3413193965*s_
    b_ = -0.0041960863*l_ - 0.7034186147*m_ + 1.7076147010*s_
    to255 = lambda c: int(max(0, min(255, round(linear_to_srgb(c) * 255))))
    return to255(r), to255(g), to255(b_)

def oklab_to_lch(L, a, b):
    C = math.sqrt(a*a + b*b)
    H = math.atan2(b, a) % (2 * math.pi)
    return L, C, H

def lch_to_oklab(L, C, H):
    return L, C * math.cos(H), C * math.sin(H)

def rgb_to_hex(rgb):
    return f"#{rgb[0]:02x}{rgb[1]:02x}{rgb[2]:02x}"

def clamp(v, lo, hi):
    return max(lo, min(v, hi))

def hue_dist(h1, h2):
    """Shortest arc between two hues on the wheel [0, π]."""
    d = abs(h1 - h2) % (2 * math.pi)
    return min(d, 2 * math.pi - d)

# ==============================================================================
# COLOR EXTRACTION
# ==============================================================================

MIN_CHROMA   = 0.05   # below = near-neutral, skip as accent candidate
MIN_COVERAGE = 0.005  # below = noise, skip

def extract_colors(image_path, debug=False):
    if not os.path.exists(image_path):
        print(f"Error: '{image_path}' not found.", file=sys.stderr)
        sys.exit(1)

    with Image.open(image_path) as img:
        img = img.convert("RGB")
        # Optmized: Switched from LANCZOS to NEAREST for instant downsampling
        img.thumbnail((400, 400), Image.Resampling.NEAREST)
        n = 20
        quantized = img.quantize(colors=n, method=Image.Quantize.MAXCOVERAGE)
        raw_counts = quantized.getcolors(maxcolors=n * 4)
        palette    = quantized.getpalette()

    total = sum(c[0] for c in raw_counts)
    clusters = []
    for count, idx in raw_counts:
        rgb = (palette[idx*3], palette[idx*3+1], palette[idx*3+2])
        lch = oklab_to_lch(*rgb_to_oklab(rgb))
        clusters.append((lch, count / total))

    # --- base_hue: circular mean weighted by chroma × coverage ---
    sx = sy = 0.0
    for (L, C, H), cov in clusters:
        if C >= MIN_CHROMA:
            w = C * cov
            sx += w * math.cos(H)
            sy += w * math.sin(H)
    base_hue = math.atan2(sy, sx) % (2 * math.pi)

    # --- dominant: highest-coverage cluster (contrast reference) ---
    dom_lch, _ = max(clusters, key=lambda x: x[1])
    dom_H = dom_lch[2]

    # --- accent scoring ---
    def accent_score(lch, cov):
        L, C, H = lch
        if C < MIN_CHROMA or cov < MIN_COVERAGE:
            return -1.0
        contrast = hue_dist(H, dom_H) / math.pi
        presence = math.log1p(cov * 50)
        return C * contrast * presence

    best = max(clusters, key=lambda x: accent_score(*x))
    if accent_score(*best) > 0.01:
        accent_lch = best[0]
    else:
        chromatics = [(lch, cov) for lch, cov in clusters
                      if lch[1] >= MIN_CHROMA and cov >= MIN_COVERAGE]
        accent_lch = max(chromatics, key=lambda x: x[0][1])[0] if chromatics else dom_lch

    acc_H = accent_lch[2]

    # --- secondary scoring ---
    def secondary_score(lch, cov):
        L, C, H = lch
        if C < MIN_CHROMA or cov < MIN_COVERAGE or lch == accent_lch:
            return -1.0
        if hue_dist(H, acc_H) < 0.52:
            return -1.0
        c_dom = hue_dist(H, dom_H) / math.pi
        c_acc = hue_dist(H, acc_H) / math.pi
        return C * ((c_dom + c_acc) / 2.0) * math.log1p(cov * 50)

    best_sec = max(clusters, key=lambda x: secondary_score(*x))
    secondary_lch = best_sec[0] if secondary_score(*best_sec) > 0 else accent_lch

    if debug:
        print("\n[debug] All clusters (L, C, H°, coverage%, accent_score):", file=sys.stderr)
        for (L, C, H), cov in sorted(clusters, key=lambda x: accent_score(*x), reverse=True):
            sc = accent_score((L, C, H), cov)
            rgb = oklab_to_rgb(*lch_to_oklab(L, C, H))
            print(f"  {rgb_to_hex(rgb)}  L={L:.2f} C={C:.3f} H={math.degrees(H):6.1f}°  "
                  f"cov={cov*100:5.1f}%  score={sc:.4f}", file=sys.stderr)
        print(f"\n[debug] base_hue  : {math.degrees(base_hue):.1f}°", file=sys.stderr)
        a_rgb = oklab_to_rgb(*lch_to_oklab(*accent_lch))
        print(f"[debug] accent    : {rgb_to_hex(a_rgb)}  H={math.degrees(accent_lch[2]):.1f}°", file=sys.stderr)
        s_rgb = oklab_to_rgb(*lch_to_oklab(*secondary_lch))
        print(f"[debug] secondary : {rgb_to_hex(s_rgb)}  H={math.degrees(secondary_lch[2]):.1f}°\n", file=sys.stderr)

    return base_hue, accent_lch, secondary_lch

# ==============================================================================
# PASTEL SCALING + PALETTE GENERATION
# ==============================================================================

def scale_to_pastel(lch, is_light_mode):
    L, C, H = lch
    
    # Allow chroma to drop completely if the image is grayscale
    min_C = min(C, 0.08 if is_light_mode else 0.10)
    max_C = 0.14 if is_light_mode else 0.16
    
    new_L = clamp(L, 0.55, 0.70) if is_light_mode else clamp(L, 0.45, 0.60)
    new_C = clamp(C, min_C, max_C)
    
    return (new_L, new_C, H)

def generate_palette(image_path, is_light_mode=False, debug=False):
    base_hue, accent_raw, secondary_raw = extract_colors(image_path, debug=debug)

    # Scale down background chroma if the image lacks strong colors
    bg_C_scale = min(1.0, accent_raw[1] / 0.05)

    if is_light_mode:
        bgBase    = (0.70, 0.015 * bg_C_scale, base_hue)
        bgSurface = (0.93, 0.020 * bg_C_scale, base_hue)
        bgOverlay = (0.87, 0.025 * bg_C_scale, base_hue)
        fgBase    = (0.25, 0.030 * bg_C_scale, base_hue)
        fgDim     = (0.42, 0.025 * bg_C_scale, base_hue)
        fgSubtle  = (0.60, 0.020 * bg_C_scale, base_hue)
    else:
        bgBase    = (0.11, 0.040 * bg_C_scale, base_hue)
        bgSurface = (0.17, 0.035 * bg_C_scale, base_hue)
        bgOverlay = (0.26, 0.030 * bg_C_scale, base_hue)
        fgBase    = (0.95, 0.010 * bg_C_scale, base_hue)
        fgDim     = (0.78, 0.015 * bg_C_scale, base_hue)
        fgSubtle  = (0.55, 0.020 * bg_C_scale, base_hue)

    accent_strong = scale_to_pastel(accent_raw,    is_light_mode)
    secondary     = scale_to_pastel(secondary_raw, is_light_mode)

    if abs(secondary[0] - accent_strong[0]) < 0.04:
        offset = -0.05 if is_light_mode else 0.05
        secondary = (clamp(secondary[0] + offset, 0.45, 0.75), secondary[1], secondary[2])

    onAccent = (0.98, 0.005, base_hue) if accent_strong[0] < 0.65 else (0.18, 0.030, base_hue)

    accentDim = (
        clamp(accent_strong[0] - 0.10, 0.30, 0.90),
        accent_strong[1] * 0.9,
        accent_strong[2],
    )

    borderInactive = (0.78, 0.020, base_hue) if is_light_mode else (0.23, 0.035, base_hue)

    H_RED, H_YEL, H_GRN, H_BLU = 0.50, 1.50, 2.40, 4.20
    util_L = 0.60 if is_light_mode else 0.70
    util_C = 0.20 if is_light_mode else 0.15

    def blend_hue(target, weight=0.15):
        x = (1 - weight) * math.cos(target) + weight * math.cos(base_hue)
        y = (1 - weight) * math.sin(target) + weight * math.sin(base_hue)
        return math.atan2(y, x)

    danger  = (util_L - 0.07, util_C + 0.15, blend_hue(H_RED))
    warning = (util_L + 0.08, util_C + 0.08, blend_hue(H_YEL))
    success = (util_L,        util_C       , blend_hue(H_GRN))
    info    = (util_L - 0.02, util_C       , blend_hue(H_BLU))

    def fin(lch):
        return rgb_to_hex(oklab_to_rgb(*lch_to_oklab(*lch)))

    return {
        "bgBase":         fin(bgBase),
        "bgSurface":      fin(bgSurface),
        "bgOverlay":      fin(bgOverlay),
        "fgBase":         fin(fgBase),
        "onAccent":       fin(onAccent),
        "fgDim":          fin(fgDim),
        "fgSubtle":       fin(fgSubtle),
        "accentStrong":   fin(accent_strong),
        "accentDim":      fin(accentDim),
        "secondary":      fin(secondary),
        "info":           fin(info),
        "success":        fin(success),
        "warning":        fin(warning),
        "danger":         fin(danger),
        "borderActive":   fin(accent_strong),
        "borderInactive": fin(borderInactive),
    }

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate an Oklab semantic JSON palette from a wallpaper.")
    parser.add_argument("image",    help="Path to the source image")
    parser.add_argument("--light",  action="store_true",  dest="light", help="Light mode palette")
    parser.add_argument("--dark",   action="store_false", dest="light", help="Dark mode palette")
    parser.add_argument("--debug",  action="store_true",  help="Print cluster analysis to stderr")
    parser.set_defaults(light=False)
    args = parser.parse_args()
    print(json.dumps(generate_palette(args.image, is_light_mode=args.light, debug=args.debug), indent=2))
