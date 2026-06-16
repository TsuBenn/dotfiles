#!/usr/bin/env python3
import sys
import argparse
import numpy as np
from PIL import Image


def to_linear(c: np.ndarray) -> np.ndarray:
    c = c / 255.0
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def luminance(rgb: np.ndarray) -> np.ndarray:
    lin = to_linear(rgb.astype(np.float32))
    return 0.2126 * lin[..., 0] + 0.7152 * lin[..., 1] + 0.0722 * lin[..., 2]


def edge_weights(h: int, w: int, fraction: float, w_bottom: float, w_top: float, w_sides: float) -> np.ndarray:
    m = np.ones((h, w), dtype=np.float32)
    eh = max(int(h * fraction), 16)
    ew = max(int(w * fraction), 16)
    m[-eh:, :] = w_bottom
    m[:eh, :]  = w_top
    m[:, :ew]  = np.maximum(m[:, :ew],  w_sides)
    m[:, -ew:] = np.maximum(m[:, -ew:], w_sides)
    return m, eh


def decide(path: str, args) -> str:
    img = Image.open(path).convert("RGB")
    img.thumbnail((800, 800), Image.LANCZOS)
    w, h = img.size
    arr = np.array(img)
    lum = luminance(arr)

    weights_map, eh = edge_weights(
        h, w,
        fraction=args.edge_fraction,
        w_bottom=args.w_bottom,
        w_top=args.w_top,
        w_sides=args.w_sides,
    )

    weighted_mean = float(np.average(lum, weights=weights_map))
    median_lum    = float(np.median(lum))
    dark_frac     = float(np.mean(lum < args.dark_cutoff))
    bright_frac   = float(np.mean(lum > args.bright_cutoff))
    distribution  = (bright_frac - dark_frac + 1.0) / 2.0
    edge_zone     = np.concatenate([lum[:eh].ravel(), lum[-eh:].ravel()])
    edge_mean     = float(np.mean(edge_zone))

    sw = args.signal_weights
    total = sum(sw)
    score = (
        (sw[0] / total) * weighted_mean +
        (sw[1] / total) * median_lum    +
        (sw[2] / total) * edge_mean     +
        (sw[3] / total) * distribution
    )

    if args.debug:
        print(f"[debug] weighted_mean={weighted_mean:.3f}  median={median_lum:.3f}  "
              f"edge_mean={edge_mean:.3f}  distribution={distribution:.3f}", file=sys.stderr)
        print(f"[debug] score={score:.3f}  threshold={args.threshold}", file=sys.stderr)

    return "light" if score > args.threshold else "dark"


def main():
    p = argparse.ArgumentParser(description="Determine dark/light mode from wallpaper.")
    p.add_argument("wallpaper", help="Path to the wallpaper image")

    # Region weights
    p.add_argument("--w-bottom",      type=float, default=3.0,  metavar="F", help="Weight for bottom edge (taskbar). Default: 3.0")
    p.add_argument("--w-top",         type=float, default=2.5,  metavar="F", help="Weight for top edge. Default: 2.5")
    p.add_argument("--w-sides",       type=float, default=1.5,  metavar="F", help="Weight for left/right edges. Default: 1.5")
    p.add_argument("--edge-fraction", type=float, default=0.125, metavar="F", help="Fraction of image height/width counted as 'edge'. Default: 0.125 (1/8)")

    # Signal weights (auto-normalized, so raw ratios are fine)
    p.add_argument("--signal-weights", type=float, nargs=4, default=[0.30, 0.25, 0.25, 0.20],
                   metavar=("WEDGE_MEAN", "MEDIAN", "EDGE_MEAN", "DISTRIB"),
                   help="Weights for the 4 signals (auto-normalized). Default: 0.30 0.25 0.25 0.20")

    # Pixel classification thresholds
    p.add_argument("--dark-cutoff",   type=float, default=0.35, metavar="F", help="Luminance below this = dark pixel. Default: 0.35")
    p.add_argument("--bright-cutoff", type=float, default=0.65, metavar="F", help="Luminance above this = bright pixel. Default: 0.65")

    # Decision threshold
    p.add_argument("--threshold",     type=float, default=0.5,  metavar="F", help="Score above this = light mode. Default: 0.5")

    p.add_argument("--debug", action="store_true", help="Print signal breakdown to stderr")

    args = p.parse_args()
    print(decide(args.wallpaper, args))


if __name__ == "__main__":
    main()
