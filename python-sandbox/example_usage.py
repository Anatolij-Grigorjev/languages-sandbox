#!/usr/bin/env python3
"""
Example usage of the image_grid_splitter module.

This script demonstrates how to use the image grid splitter functionality.
"""

from image_grid_splitter import split_image_grid
import os

def main():
    """Example usage of the image grid splitter."""
    
    # Example 1: Basic usage
    print("Example 1: Basic usage")
    print("Usage: python image_grid_splitter.py input_image.png")
    print()
    
    # Example 2: Programmatic usage
    print("Example 2: Programmatic usage")
    print("""
from image_grid_splitter import split_image_grid

# Split an image into a 3x3 grid
try:
    output_files = split_image_grid(
        input_path="my_grid_image.png",
        output_dir="./split_images",
        prefix="extracted_image"
    )
    print(f"Created {len(output_files)} images")
except Exception as e:
    print(f"Error: {e}")
    """)
    
    # Example 3: Command line options
    print("Example 3: Command line options")
    print("""
# Basic usage
python image_grid_splitter.py input.png

# Specify output directory
python image_grid_splitter.py input.png --output-dir ./my_output

# Custom filename prefix
python image_grid_splitter.py input.png --prefix "my_images"

# Adjust whitespace detection threshold
python image_grid_splitter.py input.png --threshold 20
    """)

if __name__ == "__main__":
    main()