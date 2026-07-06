#!/usr/bin/env python3
"""
colors_pipeline.py — Unified color pipeline for Quickshell rice.

Combines light_or_dark.py, color_extractor.py, and colors_lightify.py
into a single process with persistent caching.

Output format (flat, per-theme light/dark variants):
  {
      "prefered_mode": "dark",
      "auto": {
          "light": { "generated": true,  "bgBase": "#...", ... },
          "dark":  { "generated": true,  "bgBase": "#...", ... }
      },
      "hutao": {
          "light": { "generated": true,  "bgBase": "#...", ... },
          "dark":  { "generated": false, "bgBase": "#...", ... }
      }
  }

Usage:
  python colors_pipeline.py [wallpaper] --config-dir <dir> [--wallpaper-dir <dir>] [options]

  All inputs are accepted at once.  The script:
    1. Pre-warms wallpaper-dir (if given) using parallel workers
    2. Processes the current wallpaper (if given)
    3. Processes manual themes from colors.json
    4. Flushes the full JSON output to stdout

  Progress is logged to stderr throughout.

Caching:
  - Manual themes: cached in colors_cache.json, invalidated by source hash
    when colors.json changes.  No re-generation needed on subsequent runs.
  - Wallpaper palettes: cached by file path + mtime + size.  If the same
    wallpaper is seen again, the cached result is returned instantly.
  - Pre-warm (--wallpaper-dir): batch-generate palettes for every
    image in a directory.  The QML only needs to call the script normally
    afterward — it'll hit the cache every time.

Concurrency:
  - Pre-warm (--wallpaper-dir) uses ProcessPoolExecutor to process
    multiple wallpapers in parallel.  Use --workers to control parallelism.
  - Within each image, mode detection, color extraction, and contrast
    computation run in parallel threads (ThreadPoolExecutor) since PIL/numpy
    release the GIL during C-level operations.

Dependencies: PIL (Pillow), numpy, stdlib
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import os
import sys
from pathlib import Path

from concurrent.futures import ProcessPoolExecutor, ThreadPoolExecutor, as_completed

import numpy as np
from PIL import Image


# ═══════════════════════════════════════════════════════════════════════════════
# COLOR SPACE MATH  (sRGB ↔ Linear ↔ Oklab ↔ OkLCH)
# ═══════════════════════════════════════════════════════════════════════════════

def srgb_to_linear(c: float) -> float:
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

def linear_to_srgb(c: float) -> float:
    return 12.92 * c if c <= 0.0031308 else 1.055 * (c ** (1.0 / 2.4)) - 0.055

def hex_to_rgb(h: str) -> tuple[int, int, int]:
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))

def rgb_to_hex(r: int, g: int, b: int) -> str:
    return f"#{r:02x}{g:02x}{b:02x}"

def rgb_to_oklab(r: int, g: int, b: int) -> tuple[float, float, float]:
    lr = srgb_to_linear(r / 255.0)
    lg = srgb_to_linear(g / 255.0)
    lb = srgb_to_linear(b / 255.0)
    l_ = (max(0, 0.4122214708*lr + 0.5363325363*lg + 0.0514459929*lb)) ** (1/3)
    m_ = (max(0, 0.2119034982*lr + 0.6806995451*lg + 0.1073972632*lb)) ** (1/3)
    s_ = (max(0, 0.0883024619*lr + 0.2817188376*lg + 0.6299787005*lb)) ** (1/3)
    L =  0.2104542553*l_ + 0.7936177850*m_ - 0.0040720468*s_
    a =  1.9779984951*l_ - 2.4285922050*m_ + 0.4505937099*s_
    b_=  0.0259040371*l_ + 0.7827717662*m_ - 0.8086757660*s_
    return L, a, b_

def oklab_to_rgb(L: float, a: float, b: float) -> tuple[int, int, int]:
    l_ = (L + 0.3963377774*a + 0.2158037573*b) ** 3
    m_ = (L - 0.1055613458*a - 0.0638541728*b) ** 3
    s_ = (L - 0.0894841775*a - 1.2914855480*b) ** 3
    r =  +4.0767416621*l_ - 3.3077115913*m_ + 0.2309699292*s_
    g =  -1.2684380046*l_ + 2.6097574011*m_ - 0.3413193965*s_
    b_= -0.0041960863*l_ - 0.7034186147*m_ + 1.7076147010*s_
    def to8(v): return max(0, min(255, round(linear_to_srgb(v)*255)))
    return to8(r), to8(g), to8(b_)

def oklab_to_lch(L, a, b):
    C = math.sqrt(a*a + b*b)
    H = math.atan2(b, a) % (2*math.pi)
    return L, C, H

def lch_to_oklab(L, C, H):
    return L, C*math.cos(H), C*math.sin(H)

def clamp(v, lo, hi): return max(lo, min(v, hi))

def hue_dist(h1, h2):
    d = abs(h1-h2) % (2*math.pi)
    return min(d, 2*math.pi-d)

def blend_hue(target, base, weight=0.15):
    x = (1-weight)*math.cos(target) + weight*math.cos(base)
    y = (1-weight)*math.sin(target) + weight*math.sin(base)
    return math.atan2(y, x)

def finalize(lch):
    return rgb_to_hex(*oklab_to_rgb(*lch_to_oklab(*lch)))

# ── Numpy vectorized ─────────────────────────────────────────────────────────

def _to_linear_np(c):
    return np.where(c <= 0.04045, c/12.92, ((c+0.055)/1.055)**2.4)

def luminance_np(arr):
    lin = _to_linear_np(arr.astype(np.float32)/255.0)
    return 0.2126*lin[...,0] + 0.7152*lin[...,1] + 0.0722*lin[...,2]


# ═══════════════════════════════════════════════════════════════════════════════
# CONTRAST METRIC  (drives dynamic bgSurface brightness)
# ═══════════════════════════════════════════════════════════════════════════════
#
# bgSurface brightness is no longer a static value — it scales with how
# visually contrasty the wallpaper is.  Low-contrast wallpapers (flat
# illustrations, soft gradients) keep bgSurface close to bgBase so the UI
# integrates with the wallpaper.  High-contrast wallpapers (busy photos,
# sharp light/dark scenes) lift bgSurface further from bgBase so UI
# surfaces remain visually distinct and legible.
#
# The metric used is RMS contrast in linear luminance space:
#   contrast = std(lum)
# Typical values for natural images:
#   flat/minimalist illustration:  ~0.03 – 0.08
#   soft gradient wallpaper:       ~0.08 – 0.15
#   average photo:                 ~0.15 – 0.25
#   high-contrast busy photo:      ~0.25 – 0.40

def compute_contrast(img: Image.Image) -> float:
    """RMS contrast of the wallpaper in linear luminance space.

    Returns a float in [0, ~0.5].  Cheaper than it looks: 200×200 thumbnail,
    vectorized.
    """
    thumb = img.copy()
    thumb.thumbnail((200, 200), Image.Resampling.LANCZOS)
    arr = np.array(thumb)
    lum = luminance_np(arr)
    return float(np.std(lum))


def _contrast_factor(contrast: float, lo: float = 0.05, hi: float = 0.30) -> float:
    """Normalize raw RMS contrast to a [0, 1] lift factor.

    contrast <= lo  → 0.0  (low-contrast image, surfaces stay close to bgBase)
    contrast >= hi  → 1.0  (high-contrast image, surfaces lift further)
    """
    if hi <= lo:
        return 0.0
    return clamp((contrast - lo) / (hi - lo), 0.0, 1.0)


def _derive_palette_contrast(palette: dict) -> float:
    """For manual themes (no source image), estimate a contrast-like signal
    from the palette itself: the L-spread between bgSurface and accentStrong.

    Maps a spread of [0.0, 0.7] → contrast of [0.05, 0.30] so it lands in the
    same range as compute_contrast().
    """
    bg_hex  = palette.get("bgSurface",    "#808080")
    acc_hex = palette.get("accentStrong", "#808080")
    try:
        bg_L,  _, _ = rgb_to_oklab(*hex_to_rgb(bg_hex))
        acc_L, _, _ = rgb_to_oklab(*hex_to_rgb(acc_hex))
        spread = abs(acc_L - bg_L)
        return clamp(0.05 + (spread / 0.7) * 0.25, 0.05, 0.30)
    except Exception:
        return 0.15  # mid-range default


# ═══════════════════════════════════════════════════════════════════════════════
# PALETTE MODE DETECTION
# ═══════════════════════════════════════════════════════════════════════════════

COLOR_KEYS = frozenset({
    "bgBase", "bgSurface", "bgOverlay",
    "fgBase", "onAccent", "fgDim", "fgSubtle",
    "accentStrong", "accentDim", "secondary",
    "info", "success", "warning", "danger",
    "borderActive", "borderInactive",
})

def detect_palette_mode(palette: dict) -> str:
    """Determine whether a palette is light or dark based on bgSurface L."""
    bg = palette.get("bgSurface", "")
    if isinstance(bg, str) and bg.startswith("#") and len(bg) >= 7:
        L, _, _ = rgb_to_oklab(*hex_to_rgb(bg))
        return "light" if L > 0.50 else "dark"
    bg = palette.get("bgBase", "")
    if isinstance(bg, str) and bg.startswith("#") and len(bg) >= 7:
        L, _, _ = rgb_to_oklab(*hex_to_rgb(bg))
        return "light" if L > 0.50 else "dark"
    return "dark"


# ═══════════════════════════════════════════════════════════════════════════════
# LIGHT / DARK MODE DETECTION  (from wallpaper image)
# ═══════════════════════════════════════════════════════════════════════════════

def _edge_weights(h, w, fraction, w_bottom, w_top, w_sides):
    m = np.ones((h, w), dtype=np.float32)
    eh = max(int(h*fraction), 16)
    ew = max(int(w*fraction), 16)
    m[-eh:, :] = w_bottom
    m[:eh, :]  = w_top
    m[:, :ew]  = np.maximum(m[:, :ew],  w_sides)
    m[:, -ew:] = np.maximum(m[:, -ew:], w_sides)
    return m, eh

def decide_mode(img, args):
    thumb = img.copy()
    thumb.thumbnail((800, 800), Image.Resampling.LANCZOS)
    arr = np.array(thumb)
    lum = luminance_np(arr)
    wm, eh = _edge_weights(lum.shape[0], lum.shape[1],
                           args.edge_fraction, args.w_bottom,
                           args.w_top, args.w_sides)
    weighted_mean = float(np.average(lum, weights=wm))
    median_lum    = float(np.median(lum))
    dark_frac     = float(np.mean(lum < args.dark_cutoff))
    bright_frac   = float(np.mean(lum > args.bright_cutoff))
    distribution  = (bright_frac - dark_frac + 1.0) / 2.0
    edge_zone     = np.concatenate([lum[:eh].ravel(), lum[-eh:].ravel()])
    edge_mean     = float(np.mean(edge_zone))
    sw = args.signal_weights
    total = sum(sw)
    score = (sw[0]/total)*weighted_mean + (sw[1]/total)*median_lum + \
            (sw[2]/total)*edge_mean + (sw[3]/total)*distribution
    if args.debug:
        print(f"[mode] weighted_mean={weighted_mean:.3f}  median={median_lum:.3f}  "
              f"edge_mean={edge_mean:.3f}  distribution={distribution:.3f}", file=sys.stderr)
        print(f"[mode] score={score:.3f}  threshold={args.threshold}", file=sys.stderr)
    return "light" if score > args.threshold else "dark"


# ═══════════════════════════════════════════════════════════════════════════════
# COLOR EXTRACTION  (Oklab-based)
# ═══════════════════════════════════════════════════════════════════════════════

MIN_CHROMA   = 0.05
MIN_COVERAGE = 0.005

def _thumbnail_for_extraction(img):
    t = img.copy()
    t.thumbnail((400, 400), Image.Resampling.NEAREST)
    return t

def extract_colors(img, debug=False):
    thumb = _thumbnail_for_extraction(img)
    n = 20
    q = thumb.quantize(colors=n, method=Image.Quantize.MAXCOVERAGE)
    rc = q.getcolors(maxcolors=n*4)
    pal = q.getpalette()
    if rc is None:
        q = thumb.quantize(colors=n, method=Image.Quantize.MEDIANCUT)
        rc = q.getcolors(maxcolors=n*4)
        pal = q.getpalette()
    if rc is None or pal is None:
        return 0.0, (0.5, 0.1, 0.0), (0.5, 0.1, 3.14)
    total = sum(c for c, _ in rc)
    clusters = []
    for count, idx in rc:
        rgb = (pal[idx*3], pal[idx*3+1], pal[idx*3+2])
        lch = oklab_to_lch(*rgb_to_oklab(*rgb))
        clusters.append((lch, count/total))
    sx = sy = 0.0
    for (L, C, H), cov in clusters:
        if C >= MIN_CHROMA:
            w = C*cov; sx += w*math.cos(H); sy += w*math.sin(H)
    base_hue = math.atan2(sy, sx) % (2*math.pi)
    dom_lch, _ = max(clusters, key=lambda x: x[1])
    dom_H = dom_lch[2]
    def accent_score(lch, cov):
        L, C, H = lch
        if C < MIN_CHROMA or cov < MIN_COVERAGE: return -1.0
        return C * (hue_dist(H, dom_H)/math.pi) * math.log1p(cov*50)
    best = max(clusters, key=lambda x: accent_score(*x))
    accent_lch = best[0] if accent_score(*best) > 0.01 else \
        (max([(l,c) for l,c in clusters if l[1]>=MIN_CHROMA and c>=MIN_COVERAGE],
             key=lambda x: x[0][1])[0] if any(l[1]>=MIN_CHROMA and c>=MIN_COVERAGE for l,c in clusters) else dom_lch)
    acc_H = accent_lch[2]
    def secondary_score(lch, cov):
        L, C, H = lch
        if C < MIN_CHROMA or cov < MIN_COVERAGE or lch == accent_lch: return -1.0
        if hue_dist(H, acc_H) < 0.52: return -1.0
        return C * ((hue_dist(H,dom_H)/math.pi + hue_dist(H,acc_H)/math.pi)/2.0) * math.log1p(cov*50)
    best_sec = max(clusters, key=lambda x: secondary_score(*x))
    secondary_lch = best_sec[0] if secondary_score(*best_sec) > 0 else accent_lch
    if debug:
        print("\n[extract] All clusters:", file=sys.stderr)
        for (L,C,H), cov in sorted(clusters, key=lambda x: accent_score(*x), reverse=True):
            sc = accent_score((L,C,H), cov)
            rgb = oklab_to_rgb(*lch_to_oklab(L,C,H))
            print(f"  {rgb_to_hex(*rgb)}  L={L:.2f} C={C:.3f} H={math.degrees(H):6.1f}°  "
                  f"cov={cov*100:5.1f}%  score={sc:.4f}", file=sys.stderr)
        print(f"[extract] base_hue={math.degrees(base_hue):.1f}°", file=sys.stderr)
        a_rgb = oklab_to_rgb(*lch_to_oklab(*accent_lch))
        print(f"[extract] accent={rgb_to_hex(*a_rgb)}  H={math.degrees(accent_lch[2]):.1f}°", file=sys.stderr)
        s_rgb = oklab_to_rgb(*lch_to_oklab(*secondary_lch))
        print(f"[extract] secondary={rgb_to_hex(*s_rgb)}  H={math.degrees(secondary_lch[2]):.1f}°\n", file=sys.stderr)
    return base_hue, accent_lch, secondary_lch


# ═══════════════════════════════════════════════════════════════════════════════
# PALETTE GENERATION
# ═══════════════════════════════════════════════════════════════════════════════

def scale_to_pastel(lch, is_light, cf=0.0):
    """Scale an accent color toward pastel (low cf) or vivid (high cf).

    cf is the contrast factor in [0, 1] from _contrast_factor().
    - cf=0: low chroma, tight L range → soft pastel accent
    - cf=1: higher chroma, wider L range → punchy vivid accent
    """
    L, C, H = lch
    if is_light:
        min_C = min(C, 0.05 + 0.03*cf)   # 0.05 → 0.08
        max_C = 0.10 + 0.08*cf           # 0.10 → 0.18
        L_lo  = 0.55 - 0.05*cf           # 0.55 → 0.50 (allow deeper accent for vivid)
        L_hi  = 0.68 + 0.02*cf           # 0.68 → 0.70
    else:
        min_C = min(C, 0.06 + 0.04*cf)   # 0.06 → 0.10
        max_C = 0.12 + 0.10*cf           # 0.12 → 0.22
        L_lo  = 0.45 - 0.03*cf           # 0.45 → 0.42
        L_hi  = 0.60 + 0.05*cf           # 0.60 → 0.65
    new_L = clamp(L, L_lo, L_hi)
    new_C = clamp(C, min_C, max_C)
    return (new_L, new_C, H)

def generate_palette(base_hue, accent_lch, secondary_lch, is_light, contrast=0.15):
    bg_C_scale = min(1.0, accent_lch[1] / 0.05)
    cf = _contrast_factor(contrast)
    if is_light:
        # Warm cream/paper tones — bright enough to read, enough chroma to not feel washed out.
        # bgBase anchored at 0.70; bgSurface lifts to ~0.90 (cream, not bleached).
        bg_surf_L = 0.88 + 0.04 * cf   # 0.88 → 0.92
        bg_over_L = 0.78 + 0.06 * cf   # 0.80 → 0.86  (stays ~0.06 below bgSurface)
        bgBase    = (0.70, max(0.008, 0.020*bg_C_scale), base_hue)
        bgSurface = (bg_surf_L, max(0.010, 0.025*bg_C_scale), base_hue)
        bgOverlay = (bg_over_L, max(0.012, 0.030*bg_C_scale), base_hue)
        fgBase    = (0.22, 0.030*bg_C_scale, base_hue)
        fgDim     = (0.40, 0.025*bg_C_scale, base_hue)
        fgSubtle  = (0.55, 0.020*bg_C_scale, base_hue)
    else:
        bg_surf_L = 0.12 + 0.06 * cf   # 0.14 → 0.22
        bg_over_L = 0.20 + 0.06 * cf   # 0.20 → 0.32  (stays 0.06–0.10 above bgSurface)
        bgBase    = (0.11, 0.040*bg_C_scale, base_hue)
        bgSurface = (bg_surf_L, 0.035*bg_C_scale, base_hue)
        bgOverlay = (bg_over_L, 0.030*bg_C_scale, base_hue)
        fgBase    = (0.95, 0.010*bg_C_scale, base_hue)
        fgDim     = (0.78, 0.015*bg_C_scale, base_hue)
        fgSubtle  = (0.55, 0.020*bg_C_scale, base_hue)
    # Accent chroma scales with cf — pastel for flat wallpapers, vivid for busy ones.
    accent_strong = scale_to_pastel(accent_lch,    is_light, cf=cf)
    secondary     = scale_to_pastel(secondary_lch,  is_light, cf=cf)
    if abs(secondary[0] - accent_strong[0]) < 0.04:
        offset = -0.05 if is_light else 0.05
        secondary = (clamp(secondary[0]+offset, 0.45, 0.75), secondary[1], secondary[2])
    onAccent = (0.98, 0.005, base_hue) if accent_strong[0] < 0.65 else (0.18, 0.030, base_hue)
    accentDim = (clamp(accent_strong[0]-0.10, 0.30, 0.90), accent_strong[1]*0.9, accent_strong[2])
    borderInactive = (0.74 + 0.04*cf, 0.020, base_hue) if is_light else (0.22 + 0.04*cf, 0.035, base_hue)
    H_RED, H_YEL, H_GRN, H_BLU = 0.50, 1.50, 2.40, 4.20
    util_L = 0.65 if is_light else 0.70
    # Utility chroma also scales — soft signals for pastel, punchy for vivid.
    util_C = (0.16 + 0.06*cf) if is_light else (0.12 + 0.08*cf)
    danger  = (util_L-0.07, util_C+0.15, blend_hue(H_RED, base_hue))
    warning = (util_L+0.08, util_C+0.08, blend_hue(H_YEL, base_hue))
    success = (util_L,       util_C,       blend_hue(H_GRN, base_hue))
    info    = (util_L-0.02,  util_C,       blend_hue(H_BLU, base_hue))
    return {
        # Auto-palette metadata — transform_palette() propagates these
        # to the opposite-mode variant unchanged.
        "name":           "<i>Let me cook</i>",
        "description":    "Let the computer pick the best palette for your current wallpaper.",
        "bgBase":         finalize(bgBase),
        "bgSurface":      finalize(bgSurface),
        "bgOverlay":      finalize(bgOverlay),
        "fgBase":         finalize(fgBase),
        "onAccent":       finalize(onAccent),
        "fgDim":          finalize(fgDim),
        "fgSubtle":       finalize(fgSubtle),
        "accentStrong":   finalize(accent_strong),
        "accentDim":      finalize(accentDim),
        "secondary":      finalize(secondary),
        "info":           finalize(info),
        "success":        finalize(success),
        "warning":        finalize(warning),
        "danger":         finalize(danger),
        "borderActive":   finalize(accent_strong),
        "borderInactive": finalize(borderInactive),
    }


# ═══════════════════════════════════════════════════════════════════════════════
# PALETTE TRANSFORMATION  (generate opposite-mode variant)
# ═══════════════════════════════════════════════════════════════════════════════

def transform_palette(palette, target_mode, contrast=None):
    is_light = (target_mode == "light")
    acc_hex = palette.get("accentStrong", "#808080")
    acc_raw_L, acc_raw_C, base_hue = oklab_to_lch(*rgb_to_oklab(*hex_to_rgb(acc_hex)))
    sec_hex = palette.get("secondary", "#808080")
    sec_raw_L, sec_raw_C, sec_hue = oklab_to_lch(*rgb_to_oklab(*hex_to_rgb(sec_hex)))
    bg_C_scale = min(1.0, acc_raw_C / 0.05)
    if contrast is None:
        contrast = _derive_palette_contrast(palette)
    cf = _contrast_factor(contrast)
    if is_light:
        # Warm cream/paper tones — bright enough to read, enough chroma to not feel washed out.
        bg_surf_L = 0.88 + 0.04 * cf
        bg_over_L = 0.78 + 0.06 * cf
        bgBase    = (0.70, max(0.008, 0.020*bg_C_scale), base_hue)
        bgSurface = (bg_surf_L, max(0.010, 0.025*bg_C_scale), base_hue)
        bgOverlay = (bg_over_L, max(0.012, 0.030*bg_C_scale), base_hue)
        fgBase    = (0.22, 0.030*bg_C_scale, base_hue)
        fgDim     = (0.40, 0.025*bg_C_scale, base_hue)
        fgSubtle  = (0.55, 0.020*bg_C_scale, base_hue)
    else:
        bg_surf_L = 0.12 + 0.06 * cf
        bg_over_L = 0.20 + 0.06 * cf
        bgBase    = (0.11, 0.040*bg_C_scale, base_hue)
        bgSurface = (bg_surf_L, 0.035*bg_C_scale, base_hue)
        bgOverlay = (bg_over_L, 0.030*bg_C_scale, base_hue)
        fgBase    = (0.95, 0.010*bg_C_scale, base_hue)
        fgDim     = (0.78, 0.015*bg_C_scale, base_hue)
        fgSubtle  = (0.55, 0.020*bg_C_scale, base_hue)
    # Accent chroma scales with cf — pastel for flat, vivid for busy.
    accent_strong = scale_to_pastel((acc_raw_L, acc_raw_C, base_hue), is_light, cf=cf)
    secondary     = scale_to_pastel((sec_raw_L, sec_raw_C, sec_hue),  is_light, cf=cf)
    if abs(secondary[0] - accent_strong[0]) < 0.04:
        offset = -0.05 if is_light else 0.05
        secondary = (clamp(secondary[0]+offset, 0.45, 0.75), secondary[1], secondary[2])
    onAccent = (0.98, 0.005, base_hue) if accent_strong[0] < 0.65 else (0.18, 0.030, base_hue)
    accentDim = (clamp(accent_strong[0]-0.10, 0.30, 0.90), accent_strong[1]*0.9, accent_strong[2])
    borderInactive = (0.74 + 0.04*cf, 0.020, base_hue) if is_light else (0.22 + 0.04*cf, 0.035, base_hue)
    util_L = 0.65 if is_light else 0.70
    util_C = (0.16 + 0.06*cf) if is_light else (0.12 + 0.08*cf)
    util_palette = {}
    for u in ("info", "success", "warning", "danger"):
        u_hex = palette.get(u, "")
        if isinstance(u_hex, str) and u_hex.startswith("#"):
            _, _, u_hue = oklab_to_lch(*rgb_to_oklab(*hex_to_rgb(u_hex)))
        else:
            u_hue = {"danger":0.50,"warning":1.50,"success":2.40,"info":4.20}.get(u, 0.0)
        if u == "danger":   u_lch = (util_L-0.07, util_C+0.15, blend_hue(u_hue, base_hue))
        elif u == "warning": u_lch = (util_L+0.08, util_C+0.08, blend_hue(u_hue, base_hue))
        elif u == "success": u_lch = (util_L,       util_C,       blend_hue(u_hue, base_hue))
        else:                u_lch = (util_L-0.02,  util_C,       blend_hue(u_hue, base_hue))
        util_palette[u] = finalize(u_lch)
    # Keep name/description as-is — the light/dark distinction is already
    # encoded in the nested output structure, so labelling is redundant.
    return {
        "name":           palette.get("name", "Unnamed"),
        "description":    palette.get("description", ""),
        "bgBase":         finalize(bgBase),
        "bgSurface":      finalize(bgSurface),
        "bgOverlay":      finalize(bgOverlay),
        "fgBase":         finalize(fgBase),
        "onAccent":       finalize(onAccent),
        "fgDim":          finalize(fgDim),
        "fgSubtle":       finalize(fgSubtle),
        "accentStrong":   finalize(accent_strong),
        "accentDim":      finalize(accentDim),
        "secondary":      finalize(secondary),
        "info":           util_palette["info"],
        "success":        util_palette["success"],
        "warning":        util_palette["warning"],
        "danger":         util_palette["danger"],
        "borderActive":   finalize(accent_strong),
        "borderInactive": finalize(borderInactive),
    }


# ═══════════════════════════════════════════════════════════════════════════════
# CACHE MANAGEMENT
# ═══════════════════════════════════════════════════════════════════════════════
#
# Cache file: {config_dir}/scripts/colors_cache.json
#
# Structure:
#   {
#       "wallpapers": {
#           "/abs/path/to/wp.png": {
#               "mtime": 1234567890.0,
#               "size": 1234567,
#               "prefered_mode": "dark",
#               "light": { "generated": true, "bgBase": "#...", ... },
#               "dark":  { "generated": true, "bgBase": "#...", ... }
#           }
#       },
#       "themes": {
#           "hutao": {
#               "source_hash": "md5hex",
#               "light": { "generated": true,  ... },
#               "dark":  { "generated": false, ... }
#           }
#       }
#   }

CACHE_FILENAME = "colors_cache.json"

# Bump this when the cache schema or generated-palette format changes.
# An on-disk cache whose version doesn't match is discarded, forcing
# regeneration with the current code.  This is the cleanest way to
# invalidate stale entries left over from older script versions
# (e.g. palettes with " (Light)" suffixes in the name, or pre-contrast
# bgSurface values that don't reflect wallpaper contrast).
CACHE_VERSION = 5

def _cache_path(config_dir: str) -> Path:
    return Path(config_dir) / "scripts" / CACHE_FILENAME

def _strip_legacy_suffixes(entry: dict) -> None:
    """Remove legacy " (Light)"/" (Dark)" name suffixes and the corresponding
    description tails from a cached palette, in-place.  Defensive — the cache
    version bump should already discard old entries, but this catches any
    that slip through (e.g. user-edited cache)."""
    for mode_key in ("light", "dark"):
        pal = entry.get(mode_key)
        if not isinstance(pal, dict):
            continue
        name = pal.get("name")
        if isinstance(name, str):
            for sfx in (" (Light)", " (Dark)"):
                if name.endswith(sfx):
                    pal["name"] = name[:-len(sfx)]
                    break
        desc = pal.get("description")
        if isinstance(desc, str):
            for tail in (" — Pastel light mode.", " — Deep dark mode."):
                if desc.endswith(tail):
                    pal["description"] = desc[:-len(tail)]
                    break

def load_cache(config_dir: str) -> dict:
    p = _cache_path(config_dir)
    if not p.exists():
        return {"wallpapers": {}, "themes": {}, "version": CACHE_VERSION}
    try:
        with open(p) as f:
            cache = json.load(f)
    except (OSError, json.JSONDecodeError) as exc:
        print(f"[cache] Error reading {p}: {exc}, starting fresh.", file=sys.stderr)
        return {"wallpapers": {}, "themes": {}, "version": CACHE_VERSION}

    # Version mismatch → discard entire cache and start fresh.
    if cache.get("version") != CACHE_VERSION:
        print(f"[cache] Version mismatch (got {cache.get('version')!r}, "
              f"expected {CACHE_VERSION}), discarding stale cache.", file=sys.stderr)
        return {"wallpapers": {}, "themes": {}, "version": CACHE_VERSION}

    # Defensive: strip legacy suffixes from any entry that still has them.
    for entry in cache.get("wallpapers", {}).values():
        _strip_legacy_suffixes(entry)
    for entry in cache.get("themes", {}).values():
        _strip_legacy_suffixes(entry)

    return cache

def save_cache(config_dir: str, cache: dict) -> None:
    p = _cache_path(config_dir)
    p.parent.mkdir(parents=True, exist_ok=True)
    cache["version"] = CACHE_VERSION
    try:
        with open(p, "w") as f:
            json.dump(cache, f)
    except OSError as exc:
        print(f"[cache] Error writing {p}: {exc}", file=sys.stderr)

def _theme_hash(theme: dict) -> str:
    """Hash the colour values of a theme for cache invalidation."""
    # Only hash colour keys — name/description changes don't affect generation
    colour_data = {k: v for k, v in sorted(theme.items()) if k in COLOR_KEYS}
    return hashlib.md5(json.dumps(colour_data).encode()).hexdigest()

def _wp_stat(path: str) -> tuple[float, int] | None:
    """Return (mtime, size) for a file, or None if it doesn't exist."""
    try:
        st = os.stat(path)
        return st.st_mtime, st.st_size
    except OSError:
        return None

def _is_wp_cache_valid(cache: dict, wp_path: str) -> bool:
    """Check if a wallpaper's cached palette is still valid."""
    wp_path = os.path.abspath(wp_path)
    entry = cache.get("wallpapers", {}).get(wp_path)
    if not entry:
        return False
    stat = _wp_stat(wp_path)
    if stat is None:
        return False
    return entry.get("mtime") == stat[0] and entry.get("size") == stat[1]

def _is_theme_cache_valid(cache: dict, key: str, theme: dict) -> bool:
    """Check if a manual theme's cached variants are still valid."""
    entry = cache.get("themes", {}).get(key)
    if not entry:
        return False
    return entry.get("source_hash") == _theme_hash(theme)


# ═══════════════════════════════════════════════════════════════════════════════
# THEME LOADING
# ═══════════════════════════════════════════════════════════════════════════════

def load_themes(colors_path: Path) -> dict:
    if not colors_path.exists():
        print(f"[load] {colors_path} not found, skipping manual themes.", file=sys.stderr)
        return {}
    try:
        with open(colors_path) as f:
            return json.load(f)
    except (OSError, json.JSONDecodeError) as exc:
        print(f"[load] Error reading {colors_path}: {exc}", file=sys.stderr)
        return {}


# ═══════════════════════════════════════════════════════════════════════════════
# OUTPUT BUILDING
# ═══════════════════════════════════════════════════════════════════════════════

def _build_theme_variants(theme: dict, generated_flags: dict[str, bool]) -> dict:
    """Build {light: {..., generated}, dark: {..., generated}} for a theme.

    generated_flags: {"light": bool, "dark": bool}
    """
    mode = detect_palette_mode(theme)
    opposite_mode = "dark" if mode == "light" else "light"
    # Manual themes have no source image — derive a contrast-like signal from
    # the palette itself (L-spread between bgSurface and accentStrong).
    derived_contrast = _derive_palette_contrast(theme)
    if os.environ.get("COLORS_DEBUG"):
        cf = _contrast_factor(derived_contrast)
        print(f"[contrast] theme-derived rms≈{derived_contrast:.4f}  "
              f"lift_factor={cf:.2f}", file=sys.stderr)
    opposite = transform_palette(theme, target_mode=opposite_mode,
                                 contrast=derived_contrast)

    if mode == "light":
        light_palette, dark_palette = theme, opposite
    else:
        dark_palette, light_palette = theme, opposite

    return {
        "light": dict(light_palette, generated=generated_flags["light"]),
        "dark":  dict(dark_palette,  generated=generated_flags["dark"]),
    }


# ═══════════════════════════════════════════════════════════════════════════════
# MAIN PIPELINE
# ═══════════════════════════════════════════════════════════════════════════════
#
# Single entry point.  All work happens in one process:
#
#   1. Pre-warm wallpaper-dir (if provided) — logs to stderr
#   2. Process current wallpaper (if provided) — cache hit or fresh extraction
#   3. Process manual themes from colors.json — cache hit or fresh generation
#   4. Save cache, flush final JSON to stdout

IMAGE_EXTS = frozenset({".png", ".jpg", ".jpeg", ".bmp", ".webp", ".tiff", ".gif"})


def _process_single_wallpaper(img: Image.Image, args: argparse.Namespace) -> dict:
    """Run the full extraction + generation pipeline for one image.

    Mode detection, color extraction, and contrast computation run in
    parallel threads since PIL/numpy release the GIL during C-level
    operations.
    Returns {"prefered_mode": ..., "light": {...}, "dark": {...}}.
    """
    with ThreadPoolExecutor(max_workers=3) as pool:
        mode_future     = pool.submit(decide_mode, img, args)
        extract_future  = pool.submit(extract_colors, img, debug=args.debug)
        contrast_future = pool.submit(compute_contrast, img)
        predicted_mode  = mode_future.result()
        base_hue, accent_lch, secondary_lch = extract_future.result()
        contrast        = contrast_future.result()

    if args.debug:
        cf = _contrast_factor(contrast)
        print(f"[contrast] rms={contrast:.4f}  lift_factor={cf:.2f}  "
              f"→ bgSurface L: dark={0.14 + 0.08*cf:.3f}  light={0.88 + 0.04*cf:.3f}  "
              f"accent max_C: light={0.10 + 0.08*cf:.3f}  dark={0.12 + 0.10*cf:.3f}",
              file=sys.stderr)

    primary = generate_palette(base_hue, accent_lch, secondary_lch,
                               is_light=(predicted_mode == "light"),
                               contrast=contrast)
    detected_mode = detect_palette_mode(primary)
    opposite_mode = "dark" if detected_mode == "light" else "light"
    opposite = transform_palette(primary, target_mode=opposite_mode,
                                 contrast=contrast)

    if detected_mode == "light":
        light_p, dark_p = primary, opposite
    else:
        dark_p, light_p = primary, opposite

    return {
        "prefered_mode": predicted_mode,
        "light": dict(light_p, generated=True),
        "dark":  dict(dark_p,  generated=True),
    }


def _process_wp_worker(wp_path: str, args: argparse.Namespace) -> tuple[str, dict | None, str | None]:
    """Process a single wallpaper in a subprocess worker.

    Opens the image from path (avoids pickling large pixel data),
    runs the full pipeline, and returns the result.
    Returns (wp_path, entry_dict_or_None, error_message_or_None).
    """
    try:
        img = Image.open(wp_path).convert("RGB")
    except Exception as exc:
        return wp_path, None, str(exc)
    try:
        entry = _process_single_wallpaper(img, args)
        return wp_path, entry, None
    except Exception as exc:
        return wp_path, None, str(exc)


def _cache_wallpaper(cache: dict, wp_path: str, entry: dict) -> None:
    """Write a wallpaper entry into the cache dict."""
    abs_path = os.path.abspath(wp_path)
    stat = _wp_stat(wp_path)
    if stat:
        if "wallpapers" not in cache:
            cache["wallpapers"] = {}
        cache["wallpapers"][abs_path] = {
            "mtime": stat[0],
            "size": stat[1],
            "prefered_mode": entry["prefered_mode"],
            "light": entry["light"],
            "dark":  entry["dark"],
        }


def _process_theme(theme: dict) -> dict:
    """Build {light, dark} variants for a manual theme."""
    mode = detect_palette_mode(theme)
    gen_flags = {"light": (mode != "light"), "dark": (mode != "dark")}
    return _build_theme_variants(theme, gen_flags)


def _cache_theme(cache: dict, key: str, theme: dict, variants: dict) -> None:
    """Write a theme entry into the cache dict."""
    if "themes" not in cache:
        cache["themes"] = {}
    cache["themes"][key] = {
        "source_hash": _theme_hash(theme),
        "light": variants["light"],
        "dark":  variants["dark"],
    }


def run(args: argparse.Namespace) -> None:
    """Unified entry point: prewarm → wallpaper → themes → output."""

    cache = load_cache(args.config_dir)
    output = {}

    # ── 1. Pre-warm wallpaper directory (concurrent) ──────────────────────
    if args.wallpaper_dir and os.path.isdir(args.wallpaper_dir):
        images = sorted(
            os.path.join(args.wallpaper_dir, f)
            for f in os.listdir(args.wallpaper_dir)
            if Path(f).suffix.lower() in IMAGE_EXTS
        )

        # Separate cache hits from misses
        to_process = []
        wp_cached = 0
        for img_path in images:
            if _is_wp_cache_valid(cache, img_path):
                wp_cached += 1
            else:
                to_process.append(img_path)

        wp_processed = wp_failed = 0
        if to_process:
            workers = min(args.workers or os.cpu_count() or 1, len(to_process))
            print(f"[prewarm] Processing {len(to_process)} images with {workers} workers "
                  f"({wp_cached} already cached)", file=sys.stderr)
            with ProcessPoolExecutor(max_workers=workers) as executor:
                futures = {executor.submit(_process_wp_worker, p, args): p
                           for p in to_process}
                for future in as_completed(futures):
                    wp_path, entry, error = future.result()
                    if error:
                        print(f"[prewarm] ERROR: {os.path.basename(wp_path)}: {error}",
                              file=sys.stderr)
                        wp_failed += 1
                    elif entry:
                        _cache_wallpaper(cache, wp_path, entry)
                        wp_processed += 1
                        print(f"[prewarm] OK: {os.path.basename(wp_path)} → "
                              f"{entry['prefered_mode']}", file=sys.stderr)

        print(f"[prewarm] Done: {wp_processed} processed, {wp_cached} cached, "
              f"{wp_failed} failed, {len(images)} total", file=sys.stderr)

    elif args.wallpaper_dir:
        print(f"[prewarm] Not a directory: {args.wallpaper_dir}, skipping.", file=sys.stderr)

    # ── 2. Current wallpaper ───────────────────────────────────────────────
    wallpaper = args.wallpaper
    if wallpaper:
        wp_key = os.path.abspath(wallpaper)

        if _is_wp_cache_valid(cache, wallpaper):
            # Cache hit
            auto_entry = cache["wallpapers"][wp_key]
            print(f"[pipeline] Wallpaper cache HIT: {os.path.basename(wallpaper)}", file=sys.stderr)
        elif not os.path.exists(wallpaper):
            print(f"[pipeline] Wallpaper not found: {wallpaper}", file=sys.stderr)
            auto_entry = None
        else:
            try:
                img = Image.open(wallpaper).convert("RGB")
            except Exception as exc:
                print(f"[pipeline] Failed to open wallpaper: {exc}", file=sys.stderr)
                auto_entry = None
                img = None

            if img is not None:
                auto_entry = _process_single_wallpaper(img, args)
                _cache_wallpaper(cache, wallpaper, auto_entry)
                print(f"[pipeline] Wallpaper cache MISS: {os.path.basename(wallpaper)} → {auto_entry['prefered_mode']}", file=sys.stderr)

        if auto_entry:
            output["prefered_mode"] = auto_entry["prefered_mode"]
            output["auto"] = {"light": auto_entry["light"], "dark": auto_entry["dark"]}
        else:
            output["prefered_mode"] = None
            output["auto"] = None
    else:
        output["prefered_mode"] = None
        output["auto"] = None

    # ── 3. Manual themes ───────────────────────────────────────────────────
    colors_path = Path(args.config_dir) / "scripts" / "colors.json"
    themes_raw = load_themes(colors_path)

    for key, theme in themes_raw.items():
        if _is_theme_cache_valid(cache, key, theme):
            cached = cache["themes"][key]
            output[key] = {"light": cached["light"], "dark": cached["dark"]}
            print(f"[pipeline] Theme cache HIT: {key}", file=sys.stderr)
        else:
            variants = _process_theme(theme)
            output[key] = variants
            _cache_theme(cache, key, theme, variants)
            mode = detect_palette_mode(theme)
            print(f"[pipeline] Theme cache MISS: {key} (native={mode})", file=sys.stderr)

    # ── 4. Save cache & flush output ───────────────────────────────────────
    save_cache(args.config_dir, cache)
    print(json.dumps(output))


# ═══════════════════════════════════════════════════════════════════════════════
# CLI
# ═══════════════════════════════════════════════════════════════════════════════

def build_parser():
    p = argparse.ArgumentParser(
        description="Unified color pipeline with caching: mode detection + palette + themes.",
    )
    p.add_argument("wallpaper", nargs="?",
                   help="Path to current wallpaper image. Optional.")
    p.add_argument("--config-dir", required=True,
                   help="Quickshell config directory (contains scripts/colors.json).")
    p.add_argument("--wallpaper-dir",
                   help="Directory of wallpapers to pre-warm into cache. Optional.")

    g = p.add_argument_group("mode-detection tuning")
    g.add_argument("--w-bottom",      type=float, default=3.0)
    g.add_argument("--w-top",         type=float, default=2.5)
    g.add_argument("--w-sides",       type=float, default=1.5)
    g.add_argument("--edge-fraction", type=float, default=0.125)
    g.add_argument("--signal-weights", type=float, nargs=4,
                   default=[0.30, 0.25, 0.25, 0.20],
                   metavar=("WMEAN", "MEDIAN", "EDGE", "DISTRIB"))
    g.add_argument("--dark-cutoff",   type=float, default=0.35)
    g.add_argument("--bright-cutoff", type=float, default=0.65)
    g.add_argument("--threshold",     type=float, default=0.5)
    p.add_argument("--debug", action="store_true")
    p.add_argument("--workers", type=int, default=0,
                   help="Max parallel workers for pre-warm. 0 = auto (cpu_count).")
    return p


def main():
    args = build_parser().parse_args()
    run(args)


if __name__ == "__main__":
    main()

