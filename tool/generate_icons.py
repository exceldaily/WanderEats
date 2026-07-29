"""Generates the WanderBites app icon set from a vector description.

The mark: a dashed travel route tracing "WB" that ends in a map pin — a food
journey drawn as a map line. Rendered here rather than shipped as a raster so
every size is drawn at native resolution and stays crisp at 48dp.

Deliberate departure from the plate mockup: the plate's navy rim and thin
white interior vanish below ~96px, and Play renders the icon at 48dp in most
places. The route + pin alone survives small sizes and reads instantly, so
the plate becomes an optional background rather than the mark itself.

Outputs (all transparent unless noted):
  branding/wanderbites_mark.png            1024, transparent, the logo
  branding/wanderbites_mark_plate.png      1024, transparent, plate version
  branding/play_icon_512.png               512, opaque cream (Play requires no alpha)
  branding/icon_foreground.png             1024, transparent, adaptive foreground
  branding/icon_monochrome.png             1024, transparent, themed-icon layer
  branding/feature_graphic.png             1024x500, store listing banner

Run:  python tool/generate_icons.py
"""

import math
import os
from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(__file__), '..', 'branding')

# Brand tokens, mirrored from lib/app/theme/wb_tokens.dart
EMBER = (228, 89, 59, 255)
VOYAGE = (14, 79, 74, 255)
CREAM = (250, 246, 240, 255)
NAVY = (26, 42, 71, 255)
WHITE = (255, 255, 255, 255)

SS = 4  # supersample factor; drawn big then downsampled for smooth curves


def _bezier(p0, p1, p2, p3, steps=160):
    """Cubic bezier sample points."""
    pts = []
    for i in range(steps + 1):
        t = i / steps
        u = 1 - t
        x = (u**3 * p0[0] + 3 * u**2 * t * p1[0]
             + 3 * u * t**2 * p2[0] + t**3 * p3[0])
        y = (u**3 * p0[1] + 3 * u**2 * t * p1[1]
             + 3 * u * t**2 * p2[1] + t**3 * p3[1])
        pts.append((x, y))
    return pts


def _resample(points, spacing):
    """Walk a polyline at fixed arc-length spacing so dashes stay even
    around curves — spacing by parameter alone bunches them on tight bends."""
    out = [points[0]]
    carry = 0.0
    for a, b in zip(points, points[1:]):
        seg = math.dist(a, b)
        if seg == 0:
            continue
        pos = carry
        while pos + spacing <= seg:
            pos += spacing
            t = pos / seg
            out.append((a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t))
        carry = pos - seg
    return out


def _dashed(draw, points, color, width, dash, gap):
    """Draw a polyline as rounded dashes of constant length."""
    pts = _resample(points, 2.0)
    step = dash + gap
    dist = 0.0
    for a, b in zip(pts, pts[1:]):
        seg = math.dist(a, b)
        if seg == 0:
            continue
        if (dist % step) < dash:
            draw.line([a, b], fill=color, width=width)
            r = width / 2
            draw.ellipse([a[0] - r, a[1] - r, a[0] + r, a[1] + r], fill=color)
        dist += seg


def _pin(draw, cx, cy, w, color):
    """Map pin: teardrop body with a punched-out hole."""
    h = w * 1.35
    top = cy - h / 2
    r = w / 2
    draw.ellipse([cx - r, top, cx + r, top + w], fill=color)
    draw.polygon(
        [(cx - r * 0.86, top + w * 0.62), (cx + r * 0.86, top + w * 0.62),
         (cx, top + h)],
        fill=color,
    )
    hr = w * 0.19
    draw.ellipse(
        [cx - hr, top + w / 2 - hr, cx + hr, top + w / 2 + hr],
        fill=(0, 0, 0, 0),
    )


def draw_mark(size, plate=False, mono=False):
    """The WB route mark on a transparent canvas."""
    S = size * SS
    img = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    route = (255, 255, 255, 255) if mono else EMBER

    # Route geometry in a 0..1 box. Exact placement matters less than it
    # looks: the mark is auto-fitted to the canvas afterwards, so these
    # numbers only control proportion, not position.
    def P(x, y):
        return (x * S, y * S)

    # One continuous journey: lead-in, W, up into the B, out to the pin.
    # W and B share a baseline with matching cap height so it reads "WB".
    path = []
    path += _bezier(P(0.02, 0.34), P(0.05, 0.26), P(0.09, 0.30), P(0.11, 0.40))
    # W: four strokes, full height
    path += _bezier(P(0.11, 0.40), P(0.15, 0.66), P(0.19, 0.78), P(0.24, 0.56))
    path += _bezier(P(0.24, 0.56), P(0.27, 0.38), P(0.31, 0.36), P(0.34, 0.56))
    path += _bezier(P(0.34, 0.56), P(0.38, 0.78), P(0.42, 0.76), P(0.46, 0.52))
    # rise into the B stem
    path += _bezier(P(0.46, 0.52), P(0.48, 0.36), P(0.50, 0.22), P(0.52, 0.10))
    # B upper bowl
    path += _bezier(P(0.52, 0.10), P(0.62, 0.03), P(0.75, 0.09), P(0.74, 0.22))
    path += _bezier(P(0.74, 0.22), P(0.73, 0.33), P(0.63, 0.39), P(0.54, 0.40))
    # B lower bowl
    path += _bezier(P(0.54, 0.40), P(0.68, 0.40), P(0.80, 0.48), P(0.79, 0.61))
    path += _bezier(P(0.79, 0.61), P(0.78, 0.74), P(0.63, 0.79), P(0.53, 0.72))
    # tail sweeping out toward the pin
    path += _bezier(P(0.53, 0.72), P(0.66, 0.82), P(0.83, 0.74), P(0.90, 0.58))

    lw = int(S * (0.032 if plate else 0.041))
    # Gap comfortably larger than the dash so it reads as a route, not a rope.
    dash = S * 0.024
    gap = S * 0.036
    _dashed(d, path, route, lw, dash, gap)
    _pin(d, *P(0.95, 0.40), S * 0.155, route)

    # Auto-fit: crop to the drawn pixels, then centre inside the requested
    # size with a consistent margin. Hand-tuning coordinates to centre a
    # composition this irregular is guesswork; measuring it is not.
    bbox = img.getbbox()
    if bbox:
        art = img.crop(bbox)
        margin = 0.14 if plate else 0.08
        avail = int(S * (1 - margin * 2))
        scale = min(avail / art.width, avail / art.height)
        art = art.resize(
            (max(1, int(art.width * scale)), max(1, int(art.height * scale))),
            Image.LANCZOS,
        )
        canvas = Image.new('RGBA', (S, S), (0, 0, 0, 0))
        if plate and not mono:
            pd = ImageDraw.Draw(canvas)
            m = S * 0.03
            pd.ellipse([m, m, S - m, S - m], fill=WHITE)
            pd.ellipse([m, m, S - m, S - m], outline=NAVY,
                       width=int(S * 0.024))
            i = S * 0.09
            pd.ellipse([i, i, S - i, S - i], outline=(214, 219, 227, 255),
                       width=max(1, int(S * 0.005)))
        canvas.alpha_composite(art, ((S - art.width) // 2,
                                     (S - art.height) // 2))
        img = canvas

    return img.resize((size, size), Image.LANCZOS)


def flatten(img, bg):
    out = Image.new('RGBA', img.size, bg)
    out.alpha_composite(img)
    return out


def main():
    os.makedirs(OUT, exist_ok=True)

    mark = draw_mark(1024)
    mark.save(os.path.join(OUT, 'wanderbites_mark.png'))

    draw_mark(1024, plate=True).save(
        os.path.join(OUT, 'wanderbites_mark_plate.png'))

    # Play store icon must be 512 and fully opaque.
    flatten(draw_mark(512), CREAM).convert('RGB').save(
        os.path.join(OUT, 'play_icon_512.png'))

    # Adaptive foreground: Android masks and zooms it, so the art must sit
    # inside the inner ~66% safe circle. Draw at 62% and centre it.
    fg = Image.new('RGBA', (1024, 1024), (0, 0, 0, 0))
    inner = draw_mark(int(1024 * 0.62))
    fg.alpha_composite(inner, ((1024 - inner.width) // 2,
                               (1024 - inner.height) // 2))
    fg.save(os.path.join(OUT, 'icon_foreground.png'))

    mono = Image.new('RGBA', (1024, 1024), (0, 0, 0, 0))
    inner_m = draw_mark(int(1024 * 0.62), mono=True)
    mono.alpha_composite(inner_m, ((1024 - inner_m.width) // 2,
                                   (1024 - inner_m.height) // 2))
    mono.save(os.path.join(OUT, 'icon_monochrome.png'))

    # Feature graphic: mark on voyage teal with generous margin.
    feat = Image.new('RGBA', (1024, 500), VOYAGE)
    fm = draw_mark(360, mono=True)
    feat.alpha_composite(fm, (80, 70))
    feat.convert('RGB').save(os.path.join(OUT, 'feature_graphic.png'))

    print('wrote icons to', os.path.normpath(OUT))


if __name__ == '__main__':
    main()
