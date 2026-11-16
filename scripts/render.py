#!/usr/bin/env python3
"""Render NOAA full disk imagery without distorting its aspect ratio."""
import argparse
from PIL import Image, ImageOps


def render(source, output, width, height, padding=32, quality=92):
    if min(width, height) < 256 or padding < 0 or padding * 2 >= min(width, height):
        raise ValueError('Invalid screen dimensions or padding')
    with Image.open(source) as original:
        original.verify()
    with Image.open(source) as original:
        image = ImageOps.exif_transpose(original).convert('RGB')
        image.thumbnail((width - 2 * padding, height - 2 * padding), Image.Resampling.LANCZOS)
        canvas = Image.new('RGB', (width, height), '#000000')
        canvas.paste(image, ((width - image.width) // 2, (height - image.height) // 2))
        canvas.save(output, 'JPEG', quality=quality, optimize=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source')
    parser.add_argument('output')
    parser.add_argument('--width', type=int, default=3840)
    parser.add_argument('--height', type=int, default=2160)
    parser.add_argument('--padding', type=int, default=32)
    args = parser.parse_args()
    render(args.source, args.output, args.width, args.height, args.padding)
