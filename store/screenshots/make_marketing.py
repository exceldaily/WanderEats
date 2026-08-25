"""Builds App Store marketing screenshots from raw app captures.

Each panel is a saturated brand gradient with two soft colour blobs for depth,
a kicker, a headline whose key phrase sits on a marker highlight, and the real
screenshot in a squared-up device shell that bleeds off the bottom.

Re-run after editing COPY or swapping a source capture; output is deterministic.

    python store/screenshots/make_marketing.py
"""

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont
import os

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, 'appstore', 'iphone69')
OUT = os.path.join(HERE, 'marketing', 'iphone69')

W, H = 1284, 2778

VOYAGE, EMBER, CREAM = '#0E4F4A', '#E4593B', '#FAF6F0'
INK, MINT, GOLD = '#1E211F', '#9FE3D4', '#E8B33D'
PLUM, OCEAN = '#7A2E4E', '#12657F'

FONT_BLACK = 'C:/Windows/Fonts/seguibl.ttf'
FONT_SEMI = 'C:/Windows/Fonts/seguisb.ttf'

# Square brackets mark the phrase that sits on the marker highlight.
# (source, kicker, headline, base, second, text, accent, highlight_text)
COPY = [
    ('01-map-home.png',          'THE MAP',      'Every pin is\n[a real rec]',      VOYAGE, OCEAN,  CREAM, MINT,  INK),
    ('05-discover-feed.png',     'DISCOVER',     'See what is\n[trending now]',     EMBER,  GOLD,   CREAM, INK,   GOLD),
    ('04-biteswipe.png',         'BITESWIPE',    'Swipe right\n[to save]',          MINT,   VOYAGE, INK,   VOYAGE, CREAM),
    ('03-taster-profile.png',    'TASTERS',      'Follow the palates\n[you trust]', PLUM,   EMBER,  CREAM, GOLD,  INK),
    ('02-restaurant-details.png','THE PLACE',    'Know before\n[you go]',           OCEAN,  MINT,   CREAM, GOLD,  INK),
    ('07-your-profile.png',      'YOUR PROFILE', 'Build your\n[taste map]',         GOLD,   EMBER,  INK,   VOYAGE, CREAM),
]


def rgb(h):
    if isinstance(h, tuple):
        return h
    h = h.lstrip('#')
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def shade(h, f):
    r, g, b = rgb(h)
    if f >= 1:
        t = min(f - 1, 1)
        return tuple(int(c + (255 - c) * t) for c in (r, g, b))
    return tuple(int(c * f) for c in (r, g, b))


def mix(a, b, t):
    return tuple(int(x + (y - x) * t) for x, y in zip(rgb(a), rgb(b)))


def background(base, second):
    """Four-corner blend between two brand colours, then blobs for depth."""
    seed = Image.new('RGB', (2, 2))
    seed.putdata([
        shade(base, 1.14),
        mix(base, second, 0.45),
        mix(base, second, 0.20),
        shade(mix(base, second, 0.60), 0.86),
    ])
    canvas = seed.resize((W, H), Image.BICUBIC).convert('RGBA')

    for colour, cx, cy, r, a in (
        (shade(second, 1.25), W * 0.82, H * 0.16, W * 0.55, 96),
        (shade(base, 0.72),   W * 0.10, H * 0.86, W * 0.62, 104),
    ):
        blob = Image.new('RGBA', (W, H), (0, 0, 0, 0))
        ImageDraw.Draw(blob).ellipse(
            [cx - r, cy - r * 0.8, cx + r, cy + r * 0.8], fill=rgb(colour) + (a,)
        )
        canvas.alpha_composite(blob.filter(ImageFilter.GaussianBlur(r * 0.45)))
    return canvas


def grain(canvas, strength=10):
    n = Image.effect_noise((W, H), 44).convert('L')
    canvas.alpha_composite(Image.merge('RGBA', (n, n, n, n.point(lambda v: strength))))


def tracked(draw, text, font, fill, y, tracking, centre_x):
    widths = [draw.textlength(c, font=font) for c in text]
    total = sum(widths) + tracking * max(len(text) - 1, 0)
    x = centre_x - total / 2
    for ch, w in zip(text, widths):
        draw.text((x, y), ch, font=font, fill=fill)
        x += w + tracking
    return total, total


def headline_block(canvas, kicker, headline, text, accent, hi_text, top):
    f_kicker = ImageFont.truetype(FONT_SEMI, 42)
    f_head = ImageFont.truetype(FONT_BLACK, 118)

    draw = ImageDraw.Draw(canvas)
    kw, _ = tracked(draw, kicker, f_kicker, rgb(text) + (0,), top, 9, W / 2)
    pill = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(pill).rounded_rectangle(
        [(W - kw) / 2 - 34, top - 14, (W + kw) / 2 + 34, top + 62], 40,
        fill=rgb(text) + (40,),
    )
    canvas.alpha_composite(pill)
    tracked(ImageDraw.Draw(canvas), kicker, f_kicker, rgb(text) + (255,), top, 9, W / 2)

    y = top + 128
    line_h = int(f_head.size * 1.16)
    for raw in headline.split('\n'):
        marked = raw.startswith('[') and raw.endswith(']')
        line = raw[1:-1] if marked else raw
        draw = ImageDraw.Draw(canvas)
        w = draw.textlength(line, font=f_head)
        x = (W - w) / 2
        if marked:
            asc, desc = f_head.getmetrics()
            bar = Image.new('RGBA', (W, H), (0, 0, 0, 0))
            ImageDraw.Draw(bar).rounded_rectangle(
                [x - 34, y + asc * 0.18 - 12, x + w + 34, y + asc + desc * 0.35 + 12],
                26, fill=rgb(accent) + (255,),
            )
            canvas.alpha_composite(bar)
            draw = ImageDraw.Draw(canvas)
        draw.text((x, y), line, font=f_head,
                  fill=rgb(hi_text if marked else text) + (255,))
        y += line_h
    return y


def device_shell(shot, width, tilt):
    # A touch more punch on the screen itself so the UI reads at thumbnail size.
    shot = ImageEnhance.Color(shot).enhance(1.08)
    shot = ImageEnhance.Contrast(shot).enhance(1.05)

    ratio = shot.height / shot.width
    height = int(width * ratio)
    shot = shot.resize((width, height), Image.LANCZOS)

    radius = int(width * 0.078)
    mask = Image.new('L', (width, height), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, width - 1, height - 1], radius, fill=255)

    bezel = 16
    bw, bh = width + bezel * 2, height + bezel * 2
    frame = Image.new('RGBA', (bw, bh), (0, 0, 0, 0))
    fd = ImageDraw.Draw(frame)
    fd.rounded_rectangle([0, 0, bw - 1, bh - 1], radius + bezel, fill=(16, 19, 18, 255))
    fd.rounded_rectangle([2, 2, bw - 3, bh - 3], radius + bezel,
                         outline=(255, 255, 255, 95), width=3)
    frame.paste(shot, (bezel, bezel), mask)

    pad = 150
    shadow = Image.new('RGBA', (bw + pad * 2, bh + pad * 2), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        [pad, pad + 44, pad + bw, pad + bh + 44], radius + bezel, fill=(0, 0, 0, 155)
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(58))
    shadow.paste(frame, (pad, pad), frame)
    if not tilt:
        # Skip the rotate entirely at zero: resampling would only soften edges.
        return shadow
    return shadow.rotate(tilt, resample=Image.BICUBIC, expand=True)


def build(index, src, kicker, headline, base, second, text, accent, hi_text):
    canvas = background(base, second)
    end = headline_block(canvas, kicker, headline, text, accent, hi_text, 196)

    shot = Image.open(os.path.join(SRC, src)).convert('RGB')
    shell = device_shell(shot, 910, tilt=0)
    canvas.alpha_composite(shell, ((W - shell.width) // 2, int(end + 60)))

    grain(canvas)

    os.makedirs(OUT, exist_ok=True)
    dest = os.path.join(OUT, src)
    canvas.convert('RGB').save(dest, 'PNG')
    return dest


if __name__ == '__main__':
    for i, row in enumerate(COPY):
        print('wrote', os.path.basename(build(i, *row)))
