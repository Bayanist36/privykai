"""Round the corners of exported widget PNGs.

Chrome's headless screenshot keeps an opaque background behind clipped
screenshots, so the exact-size widget exports get an alpha mask here.
Usage: python tools/round-widget-corners.py
"""
from pathlib import Path

from PIL import Image, ImageDraw

EXPORTS = Path(__file__).resolve().parent.parent / "widgets" / "exports"
SCALE = 3
RADII = {"2x1": 20 * SCALE, "4x2": 24 * SCALE}


def rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    width, height = size
    supersample = 4
    mask = Image.new("L", (width * supersample, height * supersample), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle(
        (0, 0, width * supersample - 1, height * supersample - 1),
        radius=radius * supersample,
        fill=255,
    )
    return mask.resize(size, Image.Resampling.LANCZOS)


for path in sorted(EXPORTS.glob("*.png")):
    radius = next((value for key, value in RADII.items() if path.name.startswith(key)), None)
    if radius is None:
        continue
    image = Image.open(path).convert("RGBA")
    image.putalpha(rounded_mask(image.size, radius))
    image.save(path)
    print(f"rounded {path.name} r={radius}px")
