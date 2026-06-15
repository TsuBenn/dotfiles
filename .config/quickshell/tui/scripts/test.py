#!/usr/bin/env python3
import argparse
import math
import os
import sys
from PIL import Image

# ==============================================================================
# PERCEPTUAL TRANSLATION (sRGB -> Linear -> Oklab Lightness)
# ==============================================================================

def srgb_to_linear(c):
    return c / 12.92 if c <= 0.04045 else math.pow((c + 0.055) / 1.055, 2.4)

def rgb_to_oklab_lightness(rgb):
    """Calculates true perceptual lightness (0.0 - 1.0) for a single pixel."""
    r = srgb_to_linear(rgb[0] / 255.0)
    g = srgb_to_linear(rgb[1] / 255.0)
    b = srgb_to_linear(rgb[2] / 255.0)

    # Move to LMS cone space
    l_ = 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b
    m_ = 0.2119034982 * r + 0.6806995451 * g + 0.1073972632 * b
    s_ = 0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b

    # Scale non-linearly for human eyes
    l_ = math.pow(max(0, l_), 1.0 / 3.0)
    m_ = math.pow(max(0, m_), 1.0 / 3.0)
    s_ = math.pow(max(0, s_), 1.0 / 3.0)

    # Return final Oklab Lightness
    return 0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_

# ==============================================================================
# THE 1-PIXEL SQUISH ENGINE
# ==============================================================================

def analyze_image_mode(image_path, threshold=0.50):
    if not os.path.exists(image_path):
        print(f"Error: Image '{image_path}' not found.", file=sys.stderr)
        sys.exit(1)

    with Image.open(image_path) as img:
        # Force Pillow to blend the entire image into a single global average pixel
        one_pixel_img = img.resize((1, 1), resample=Image.Resampling.BOX)
        global_average_rgb = one_pixel_img.getpixel((0, 0))
        
        # Extract perceptual lightness out of that single averaged color
        perceptual_lightness = rgb_to_oklab_lightness(global_average_rgb)
        
        # Output flag based on threshold boundary
        if perceptual_lightness >= threshold:
            return "--light"
        else:
            return "--dark"

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="1-Pixel Perceptual Lightness Analyzer")
    parser.add_argument("image", help="Path to the wallpaper image")
    parser.add_argument(
        "--threshold", 
        type=float, 
        default=0.5, 
        help="Oklab lightness threshold boundary (default: 0.48)"
    )
    args = parser.parse_args()

    mode_flag = analyze_image_mode(args.image, threshold=args.threshold)
    print(mode_flag)
