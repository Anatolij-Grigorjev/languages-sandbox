#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Image Grid Splitter

This script splits a PNG image containing a 3x3 grid of images into 9 separate PNG files.
The script automatically detects the whitespace margins and extracts each image from the grid.
"""

import os
import sys
from PIL import Image, ImageOps
import argparse
from typing import Tuple, List


def detect_content_bounds(image: Image.Image, threshold: int = 10) -> Tuple[int, int, int, int]:
    """
    Detect the bounds of the actual content by finding non-white pixels.
    
    Args:
        image: PIL Image object
        threshold: Tolerance for what's considered "white" (0-255)
    
    Returns:
        Tuple of (left, top, right, bottom) bounds
    """
    # Convert to grayscale for easier processing
    gray = ImageOps.grayscale(image)
    
    # Get image dimensions
    width, height = image.size
    
    # Find left bound
    left = 0
    for x in range(width):
        for y in range(height):
            if gray.getpixel((x, y)) < (255 - threshold):
                left = x
                break
        else:
            continue
        break
    
    # Find right bound
    right = width - 1
    for x in range(width - 1, -1, -1):
        for y in range(height):
            if gray.getpixel((x, y)) < (255 - threshold):
                right = x + 1
                break
        else:
            continue
        break
    
    # Find top bound
    top = 0
    for y in range(height):
        for x in range(left, right):
            if gray.getpixel((x, y)) < (255 - threshold):
                top = y
                break
        else:
            continue
        break
    
    # Find bottom bound
    bottom = height - 1
    for y in range(height - 1, -1, -1):
        for x in range(left, right):
            if gray.getpixel((x, y)) < (255 - threshold):
                bottom = y + 1
                break
        else:
            continue
        break
    
    return left, top, right, bottom


def split_image_grid(input_path: str, output_dir: str = None, prefix: str = "grid_image") -> List[str]:
    """
    Split a PNG image containing a 3x3 grid into 9 separate images.
    
    Args:
        input_path: Path to the input PNG file
        output_dir: Directory to save the split images (default: same as input)
        prefix: Prefix for output filenames
    
    Returns:
        List of paths to the created image files
    """
    # Validate input file
    if not os.path.exists(input_path):
        raise FileNotFoundError(f"Input file not found: {input_path}")
    
    if not input_path.lower().endswith(('.png', '.jpg', '.jpeg')):
        raise ValueError("Input file must be a PNG, JPG, or JPEG image")
    
    # Set output directory
    if output_dir is None:
        output_dir = os.path.dirname(input_path)
    
    os.makedirs(output_dir, exist_ok=True)
    
    print(f"Loading image: {input_path}")
    
    # Load the image
    with Image.open(input_path) as image:
        # Convert to RGB if necessary
        if image.mode != 'RGB':
            image = image.convert('RGB')
        
        print(f"Original image size: {image.size}")
        
        # Detect content bounds to skip whitespace margins
        left, top, right, bottom = detect_content_bounds(image)
        print(f"Detected content bounds: left={left}, top={top}, right={right}, bottom={bottom}")
        
        # Crop to content area
        content_image = image.crop((left, top, right, bottom))
        content_width = right - left
        content_height = bottom - top
        
        print(f"Content area size: {content_width}x{content_height}")
        
        # Calculate dimensions for each grid cell
        cell_width = content_width // 3
        cell_height = content_height // 3
        
        print(f"Each grid cell size: {cell_width}x{cell_height}")
        
        # Split into 3x3 grid
        output_paths = []
        
        for row in range(3):
            for col in range(3):
                # Calculate crop coordinates
                x1 = col * cell_width
                y1 = row * cell_height
                x2 = x1 + cell_width
                y2 = y1 + cell_height
                
                # Crop the cell
                cell_image = content_image.crop((x1, y1, x2, y2))
                
                # Generate output filename
                cell_number = row * 3 + col + 1
                output_filename = f"{prefix}_{cell_number:02d}.png"
                output_path = os.path.join(output_dir, output_filename)
                
                # Save the cell image
                cell_image.save(output_path, "PNG")
                output_paths.append(output_path)
                
                print(f"Saved cell {cell_number}: {output_filename} ({cell_image.size})")
    
    print(f"\nSuccessfully split image into {len(output_paths)} files")
    return output_paths


def main():
    """Main function with command-line interface."""
    parser = argparse.ArgumentParser(
        description="Split a PNG image containing a 3x3 grid into 9 separate images",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python image_grid_splitter.py input.png
  python image_grid_splitter.py input.png --output-dir ./split_images
  python image_grid_splitter.py input.png --prefix "my_image"
        """
    )
    
    parser.add_argument("input", help="Path to the input PNG image file")
    parser.add_argument(
        "--output-dir", "-o",
        help="Output directory for split images (default: same as input)"
    )
    parser.add_argument(
        "--prefix", "-p",
        default="grid_image",
        help="Prefix for output filenames (default: 'grid_image')"
    )
    parser.add_argument(
        "--threshold", "-t",
        type=int,
        default=10,
        help="Threshold for detecting content vs whitespace (0-255, default: 10)"
    )
    
    args = parser.parse_args()
    
    try:
        # Split the image
        output_paths = split_image_grid(
            args.input,
            args.output_dir,
            args.prefix
        )
        
        print("\nOutput files:")
        for path in output_paths:
            print(f"  {path}")
            
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
