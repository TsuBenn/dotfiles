#!/usr/bin/env python3
import argparse
import math
import os
import sys
from PIL import Image

# ==============================================================================
# COLOR SPACE MATH (sRGB -> Linear -> Oklab Lightness)
# ==============================================================================

def srgb_to_linear(c):
    """Converts standard sRGB channel to linear light space."""
    return c / 12.92 if c <= 0.04045 else math.pow((c + 0.055) / 1.055, 2.4)

def rgb_to_oklab_lightness(rgb):
    """Returns only the Perceptual Lightness (L) channel from an RGB tuple."""
    r = srgb_to_linear(rgb[0] / 255.0)
    g = srgb_to_linear(rgb[1] / 255.0)
    b = srgb_to_linear(rgb[2] / 255.0)

    # Convert to cone response space (LMS)
    l_ = 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b
    m_ = 0.2119034982 * r + 0.6806995451 * g + 0.1073972632 * b
    s_ = 0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b

    # Non-linear scaling based on human perception
    l_ = math.pow(max(0, l_), 1.0 / 3.0)
    m_ = math.pow(max(0, m_), 1.0 / 3.0)
    s_ = math.pow(max(0, s_), 1.0 / 3.0)

    # Return final Oklab Lightness (0.0 = pure black, 1.0 = pure white)
    L = 0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_
    return L

# ==============================================================================
# IMAGE ANALYSIS ENGINE
# ==============================================================================

def analyze_image_mode(image_path, threshold=0.50):
    if not os.path.exists(image_path):
        print(f"Error: Image '{image_path}' not found.", file=sys.stderr)
        sys.exit(1)

    with Image.open(image_path) as img:
        img = img.convert("RGB")
        img.thumbnail((80, 80))
        
        width, height = img.size
        lightness_values = []
        
        # Walk the 2D matrix directly—completely bypassing getdata()
        for y in range(height):
            for x in range(width):
                pixel = img.getpixel((x, y))
                lightness_values.append(rgb_to_oklab_lightness(pixel))
        
        # Sort values to calculate the median density
        lightness_values.sort()
        mid_index = len(lightness_values) // 2
        median_lightness = lightness_values[mid_index]
        
        if median_lightness >= threshold:
            return "light"
        else:
            return "dark"

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Analyze an image and return an environment theme flag.")
    parser.add_argument("image", help="Path to the wallpaper image")
    parser.add_argument(
        "--threshold", 
        type=float, 
        default=0.48, 
        help="Oklab lightness threshold (default: 0.48). Higher means bias towards dark mode."
    )
    args = parser.parse_args()

    mode_flag = analyze_image_mode(args.image, threshold=args.threshold)
    print(mode_flag)
