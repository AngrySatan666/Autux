"""
img2img.py

Usage:
  python img2img.py <directory> [--type png|jpeg|jpg|...] [--del]

Examples:
  python img2img.py myimages
  python img2img.py myimages --type jpeg
  python img2img.py myimages --type jpg --del

- Converts all compatible images in <directory> (recursively) to the specified type (default: png).
- Outputs converted images to the 'out' directory.
- Logs each run and per-image results in out/skipped.txt.
- Use --del to delete source images after conversion.
- Requires: Pillow, tqdm
  pip install pillow tqdm
"""

import os
from PIL import Image
import sys
import shutil
import argparse
from tqdm import tqdm
import datetime

# Supported image extensions
IMAGE_EXTENSIONS = ['.jpg', '.jpeg', '.bmp', '.gif', '.tiff', '.webp', '.jfif']

_dir = os.path.dirname(os.path.abspath(__file__))
out = os.path.join(_dir, 'out')

def get_compatible_images(directory):
    compatible = []
    non_compatible = []
    for root, _, files in os.walk(directory):
        for file in files:
            ext = os.path.splitext(file)[1].lower()
            path = os.path.join(root, file)
            if ext in IMAGE_EXTENSIONS:
                compatible.append(path)
            else:
                non_compatible.append(path)
    return compatible, non_compatible

def convert_images_to_png(directory, output_dir=out, out_type='png', delete_source=False):
    os.makedirs(output_dir, exist_ok=True)
    images, non_compatible = get_compatible_images(directory)
    total = len(images)
    log_path = os.path.join(output_dir, 'skipped.txt')
    now = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    with open(log_path, 'a') as f:
        f.write(f"\n--- Run at {now} ---\n")
        f.write(f"Directory: {directory}\n")
        f.write(f"Output type: {out_type}\n")
        f.write(f"Delete source: {delete_source}\n")
        f.write(f"Found {total} compatible images.\n")
        if non_compatible:
            f.write("Non-compatible files:\n")
            for item in non_compatible:
                f.write(f"  {item}\n")
        else:
            f.write("No non-compatible files.\n")
    if total == 0:
        print("No compatible images found.")
        print(f"Non-compatible files: {non_compatible}")
        print(f"Run log written to: {log_path}")
        return
    print(f"Found {total} compatible images.")
    if non_compatible:
        print(f"Non-compatible files:")
        for item in non_compatible:
            print(f"  {item}")
        print(f"Run log written to: {log_path}")
    with open(log_path, 'a') as f:
        for idx, img_path in enumerate(tqdm(images, desc='Converting', unit='img'), 1):
            try:
                with Image.open(img_path) as img:
                    base_name = os.path.splitext(os.path.basename(img_path))[0]
                    out_ext = '.' + out_type.lower().replace('jpg', 'jpeg') if out_type.lower() == 'jpg' else '.' + out_type.lower()
                    save_type = out_type.upper() if out_type.lower() != 'jpg' else 'JPEG'
                    out_file = os.path.join(output_dir, base_name + out_ext)
                    img.save(out_file, save_type)
                    f.write(f"SUCCESS: {img_path} -> {out_file}\n")
                if delete_source:
                    try:
                        os.remove(img_path)
                        f.write(f"DELETED: {img_path}\n")
                    except Exception as del_e:
                        f.write(f"FAILED TO DELETE: {img_path} | {del_e}\n")
            except Exception as e:
                f.write(f"FAILED: {img_path} | {e}\n")
                print(f"\nFailed to convert {img_path}: {e}")
    print("Conversion complete.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Convert images in a directory to a specified format.')
    parser.add_argument('directory', help='Directory to search for images')
    parser.add_argument('--type', default='png', help='Output image type (png, jpeg, jpg, etc). Default: png')
    parser.add_argument('--del', dest='delete_source', action='store_true', help='Delete source images after conversion')
    args = parser.parse_args()
    convert_images_to_png(args.directory, out, args.type, args.delete_source)
