"""Derives every Android launcher/splash bitmap from the source icons in
this folder:

  app_icon.png       -> launcher icon set (ic_launcher*)
  app_girl_icon.png  -> splash logo (splash_logo)

Each source is a light mark on a dark rounded-square tile. The mark is
lifted off the tile via a luminance threshold (light mark, dark tile) and
re-rendered at the right scale for each derived asset; the legacy
(pre-API 26) icon is the source tile itself, cropped and corner-masked.

Run from this folder with: python3 generate_icon.py
"""
import os

from PIL import Image, ImageDraw

WHITE = (250, 250, 250, 255)  # design/DESIGN.md on-surface #FAFAFA
RES = os.path.join("..", "..", "android", "app", "src", "main", "res")

# Luminance band used to turn the source's background-vs-mark contrast into
# a soft alpha mask: pixels at/below LUM_LO are background (alpha 0),
# pixels at/above LUM_HI are fully the mark (alpha 255), and the gap
# between them ramps smoothly for anti-aliased edges.
LUM_LO = 80
LUM_HI = 110
# app_icon.png's tile has a rim highlight (up to ~139 luminance) that falls
# inside the band above, so only pixels connected to a clearly-mark seed
# (at/above LUM_SEED, which the rim never reaches) are kept.
LUM_SEED = 170

# Adaptive-icon layers are masked to (at smallest) a 66dp circle of the
# 108dp canvas, so marks are fitted by their bounding-box diagonal, which
# keeps any mark shape inside the circle. The monochrome (themed) layer uses
# the same mask, so it shares the fit.
ADAPTIVE_DIAGONAL = 0.63
# Android 12+ shows the splash icon on a 288dp canvas masked to a 192dp
# circle (2/3 of it); the same bitmap is centered on pre-12 splashes.
SPLASH_DIAGONAL = 0.63

# dp -> px multipliers per density bucket.
DENSITIES = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}
ADAPTIVE_DP = 108
LEGACY_DP = 48
SPLASH_DP = 288

# Corner radius of the legacy icon's tile, as a fraction of its side.
LEGACY_CORNER = 0.22

ICON_SOURCE = "app_icon.png"
SPLASH_SOURCE = "app_girl_icon.png"


def _extract_mark(img):
    """Returns the mask-weighted RGBA mark cropped tight to content."""
    img = img.convert("RGBA")
    px = img.load()
    w, h = img.size

    def lum(x, y):
        r, g, b, a = px[x, y]
        return (r + g + b) / 3 if a else 0

    # Flood out from every seed pixel through in-band pixels.
    keep = bytearray(w * h)
    stack = [(x, y) for y in range(h) for x in range(w) if lum(x, y) >= LUM_SEED]
    for x, y in stack:
        keep[y * w + x] = 1
    while stack:
        x, y = stack.pop()
        for nx in (x - 1, x, x + 1):
            for ny in (y - 1, y, y + 1):
                if 0 <= nx < w and 0 <= ny < h and not keep[ny * w + nx] and lum(nx, ny) > LUM_LO:
                    keep[ny * w + nx] = 1
                    stack.append((nx, ny))

    mark = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    mpx = mark.load()
    for y in range(h):
        for x in range(w):
            if not keep[y * w + x]:
                continue
            r, g, b, a = px[x, y]
            weight = min(1.0, (lum(x, y) - LUM_LO) / (LUM_HI - LUM_LO))
            mpx[x, y] = (r, g, b, round(a * weight))
    return mark.crop(mark.getbbox())


def _extract_tile(img):
    """Returns the source's rounded-square tile, cropped and corner-masked."""
    img = img.convert("RGBA")
    # The tile is whatever is opaque and not pure black (the margin around
    # it is either transparent or #000).
    px = img.load()
    w, h = img.size
    mask = Image.new("L", (w, h), 0)
    mpx = mask.load()
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a > 128 and r + g + b > 6:
                mpx[x, y] = 255
    tile = img.crop(mask.getbbox())
    side = max(tile.size)
    square = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    square.paste(tile, ((side - tile.width) // 2, (side - tile.height) // 2))
    corners = Image.new("L", (side, side), 0)
    ImageDraw.Draw(corners).rounded_rectangle(
        (0, 0, side - 1, side - 1), radius=round(side * LEGACY_CORNER), fill=255
    )
    square.putalpha(corners)
    return square


def _place(mark, canvas_size, *, diagonal, monochrome=False):
    mw, mh = mark.size
    # Scale so the mark's diagonal is the given fraction of the canvas,
    # preserving its aspect ratio, then center it.
    factor = canvas_size * diagonal / (mw * mw + mh * mh) ** 0.5
    resized = mark.resize((max(1, round(mw * factor)), max(1, round(mh * factor))), Image.LANCZOS)

    if monochrome:
        alpha = resized.getchannel("A")
        resized = Image.new("RGBA", resized.size, WHITE)
        resized.putalpha(alpha)

    out = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    out.paste(resized, ((canvas_size - resized.width) // 2, (canvas_size - resized.height) // 2), resized)
    return out


def _save(img, folder, name):
    path = os.path.join(RES, folder, name)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path, optimize=True)


def main():
    icon = Image.open(ICON_SOURCE)
    mark = _extract_mark(icon)
    tile = _extract_tile(icon)
    splash = _extract_mark(Image.open(SPLASH_SOURCE))
    for bucket, mult in DENSITIES.items():
        adaptive = round(ADAPTIVE_DP * mult)
        _save(_place(mark, adaptive, diagonal=ADAPTIVE_DIAGONAL),
              f"mipmap-{bucket}", "ic_launcher_foreground.png")
        _save(_place(mark, adaptive, diagonal=ADAPTIVE_DIAGONAL, monochrome=True),
              f"mipmap-{bucket}", "ic_launcher_monochrome.png")
        legacy = round(LEGACY_DP * mult)
        _save(tile.resize((legacy, legacy), Image.LANCZOS),
              f"mipmap-{bucket}", "ic_launcher.png")
        size = round(SPLASH_DP * mult)
        _save(_place(splash, size, diagonal=SPLASH_DIAGONAL),
              f"drawable-{bucket}", "splash_logo.png")
    print(f"Wrote ic_launcher set from {ICON_SOURCE}, splash_logo from {SPLASH_SOURCE}")


if __name__ == "__main__":
    main()
