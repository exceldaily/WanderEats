"""Generates the WanderBites icon set from the globe artwork.

The mark: a globe with a bite taken out of it, an orange dashed travel route
across the continents, and a map pin where the journey ends. Source art lives
at branding/source/wanderbites_globe.png on a flat cream field; everything
here is derived from it so there is exactly one file to replace when the logo
changes.

The cream field is knocked out by flood-filling inward from the border rather
than by thresholding on colour — Greenland, Antarctica and the pin's hole are
near-white and a colour threshold would eat them.

Outputs:
  branding/wanderbites_mark.png    1024, transparent, the logo on any background
  branding/play_icon_512.png       512, opaque cream (Play rejects alpha)
  branding/icon_foreground.png     1024, transparent, adaptive foreground
  branding/icon_monochrome.png     1024, transparent, themed-icon layer
  branding/feature_graphic.png     1024x500, store listing banner

Run:  python tool/generate_icons.py && dart run flutter_launcher_icons
"""

import os
from collections import deque

import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.normpath(os.path.join(HERE, '..', 'branding'))
SRC = os.path.join(OUT, 'source', 'wanderbites_globe.png')

# Brand tokens, mirrored from lib/app/theme/wb_tokens.dart
EMBER = (228, 89, 59, 255)
VOYAGE = (14, 79, 74, 255)
CREAM = (250, 246, 240, 255)
NAVY = (26, 42, 71, 255)

# Cream knock-out. Below SOLID a pixel is background outright; above SOFT it is
# fully opaque art; between the two it gets partial alpha, which is what keeps
# the navy rim from acquiring a hard jagged edge.
BG_SOLID = 14.0
BG_SOFT = 46.0


def _bg_mask(rgb):
    """Boolean mask of the cream field, found by flooding in from the border.

    Scanline fill rather than per-pixel BFS: the field is one large simply
    connected region and spans keep the Python loop count in the thousands.
    """
    h, w, _ = rgb.shape
    corners = np.concatenate([rgb[0, :], rgb[-1, :], rgb[:, 0], rgb[:, -1]])
    bg_colour = np.median(corners.reshape(-1, 3), axis=0)
    dist = np.sqrt(((rgb.astype(np.float32) - bg_colour) ** 2).sum(axis=2))

    fillable = dist < BG_SOFT
    mask = np.zeros((h, w), dtype=bool)

    seeds = deque()
    for x in range(w):
        seeds.append((x, 0))
        seeds.append((x, h - 1))
    for y in range(h):
        seeds.append((0, y))
        seeds.append((w - 1, y))

    while seeds:
        x, y = seeds.popleft()
        if mask[y, x] or not fillable[y, x]:
            continue
        row_fill = fillable[y]
        row_mask = mask[y]
        left = x
        while left > 0 and row_fill[left - 1] and not row_mask[left - 1]:
            left -= 1
        right = x
        while right < w - 1 and row_fill[right + 1] and not row_mask[right + 1]:
            right += 1
        row_mask[left:right + 1] = True
        for ny in (y - 1, y + 1):
            if 0 <= ny < h:
                above_fill = fillable[ny]
                above_mask = mask[ny]
                nx = left
                while nx <= right:
                    if above_fill[nx] and not above_mask[nx]:
                        seeds.append((nx, ny))
                        while nx <= right and above_fill[nx]:
                            nx += 1
                    nx += 1

    return mask, dist


def load_mark():
    """The source art with its cream field removed and cropped to the mark."""
    src = Image.open(SRC).convert('RGB')
    rgb = np.asarray(src)
    mask, dist = _bg_mask(rgb)

    # Full alpha everywhere, then ramp it down across the knocked-out band so
    # the antialiased edge of the navy rim survives instead of stair-stepping.
    alpha = np.full(rgb.shape[:2], 255.0, dtype=np.float32)
    ramp = np.clip((dist - BG_SOLID) / (BG_SOFT - BG_SOLID), 0.0, 1.0) * 255.0
    band = mask.copy()
    for shift in (1, 2, 3):
        band |= np.roll(mask, shift, axis=0) | np.roll(mask, -shift, axis=0)
        band |= np.roll(mask, shift, axis=1) | np.roll(mask, -shift, axis=1)
    alpha[band] = ramp[band]
    alpha[mask] = 0.0

    out = np.dstack([rgb, alpha.astype(np.uint8)])
    img = Image.fromarray(out, 'RGBA')
    return img.crop(img.getbbox())


def square(mark, size, margin=0.0, background=None):
    """Fit the mark inside a square canvas, centred, with a relative margin."""
    avail = int(size * (1 - margin * 2))
    scale = min(avail / mark.width, avail / mark.height)
    art = mark.resize(
        (max(1, round(mark.width * scale)), max(1, round(mark.height * scale))),
        Image.LANCZOS,
    )
    canvas = Image.new('RGBA', (size, size), background or (0, 0, 0, 0))
    canvas.alpha_composite(art, ((size - art.width) // 2,
                                 (size - art.height) // 2))
    return canvas


def monochrome(mark, size):
    """Themed-icon layer: white globe silhouette with the route and pin
    knocked out of it, so the mark still reads when Android strips colour."""
    art = np.asarray(square(mark, size, margin=0.02)).astype(np.int16)
    r, g, b, a = art[..., 0], art[..., 1], art[..., 2], art[..., 3]
    # Tight on ember specifically. A loose test also catches the warm pencil
    # strokes in the sand and coastlines, which knock out as dirt.
    orange = (r > 190) & (b < 115) & (g > 55) & (g < 175) & (r - g > 70)
    # Opening: a pixel survives only with company, which drops the stray
    # single-pixel hits the texture produces without thinning the dashes.
    neighbours = np.zeros(orange.shape, dtype=np.int16)
    for dy in (-1, 0, 1):
        for dx in (-1, 0, 1):
            neighbours += np.roll(np.roll(orange, dy, axis=0), dx, axis=1)
    orange &= neighbours >= 6
    alpha = np.where(a > 128, 255, 0)
    alpha = np.where(orange, 0, alpha)
    white = np.full(art.shape[:2] + (3,), 255, dtype=np.uint8)
    return Image.fromarray(
        np.dstack([white, alpha.astype(np.uint8)]), 'RGBA')


def _font(size):
    for name in ('segoeuib.ttf', 'seguisb.ttf', 'arialbd.ttf'):
        path = os.path.join(os.environ.get('WINDIR', r'C:\Windows'),
                            'Fonts', name)
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    return ImageFont.load_default(size)


def feature_graphic(mark):
    """1024x500 store banner: mark on voyage teal with the name beside it."""
    img = Image.new('RGBA', (1024, 500), VOYAGE)
    globe = square(mark, 360)
    img.alpha_composite(globe, (72, 70))
    d = ImageDraw.Draw(img)
    d.text((470, 190), 'WanderBites', font=_font(76), fill=(255, 255, 255, 255))
    d.text((474, 282), 'Follow people with great taste', font=_font(31),
           fill=(255, 255, 255, 205))
    return img.convert('RGB')


def main():
    os.makedirs(OUT, exist_ok=True)
    mark = load_mark()

    square(mark, 1024).save(os.path.join(OUT, 'wanderbites_mark.png'))

    # Play's listing icon must be 512 and fully opaque.
    square(mark, 512, margin=0.06, background=CREAM).convert('RGB').save(
        os.path.join(OUT, 'play_icon_512.png'))

    # Android masks and zooms the adaptive foreground, so the art has to sit
    # inside the inner ~66% safe circle.
    square(mark, 1024, margin=0.17).save(
        os.path.join(OUT, 'icon_foreground.png'))

    monochrome(mark, 1024).save(os.path.join(OUT, 'icon_monochrome.png'))

    feature_graphic(mark).save(os.path.join(OUT, 'feature_graphic.png'))

    print('wrote icons to', OUT)


if __name__ == '__main__':
    main()
