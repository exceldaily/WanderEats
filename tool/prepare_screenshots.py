"""Crops raw phone captures into Play-legal store screenshots.

Play's rule that bites here: "the maximum dimension cannot exceed twice the
minimum dimension". A raw 1080x2340 capture off a modern phone is 2.17:1 and
gets rejected. Trimming Android's own status bar and navigation bar fixes the
ratio and looks better anyway - no clock, no battery, no back button.

The crop is measured, not guessed: the bars are found by their pixels, so a
device with different bar heights still comes out right. The heights are taken
as the batch median rather than per image, because a card that scrolls under
the navigation bar defeats the detection on that one shot and would leave a
sliver of the back button in the listing.

  python tool/prepare_screenshots.py

Reads store/screenshots/*.png, writes store/screenshots/play/*.png.
"""

import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.normpath(os.path.join(HERE, '..', 'store', 'screenshots'))
OUT = os.path.join(SRC, 'play')

MAX_RATIO = 2.0
MIN_SIDE = 320
MAX_SIDE = 3840
MAX_BYTES = 8 * 1024 * 1024


def _row_is_flat(row, tol=3.0):
    """A system bar row is a single flat colour apart from its glyphs."""
    return row.std(axis=0).mean() < tol


def find_nav_bar(a):
    """Height of the bottom system navigation bar, 0 if there isn't one.

    The bar is a band of one flat colour that differs from the app content
    above it. Walk up from the bottom while rows stay within that band.
    """
    h = a.shape[0]
    base = np.median(a[h - 3], axis=0)
    y = h - 1
    while y > h - 400:
        row = a[y]
        # Glyph rows are not flat, so compare the row's dominant colour
        # instead of requiring flatness all the way up.
        if np.abs(np.median(row, axis=0) - base).max() > 6:
            break
        y -= 1
    return h - 1 - y


def find_status_bar(a):
    """Height of the top status bar.

    Only the clock and the icon cluster are reliable markers, and they sit in
    the top ~70px. Searching further down starts catching the app's own first
    row of content - which is exactly how an earlier version of this ate the
    map's filter chips - so the search window is deliberately tight and the
    result is clamped to a plausible bar height.
    """
    limit = min(90, a.shape[0])
    band = a[:limit].astype(int)
    bg = np.median(band.reshape(-1, 3), axis=0)
    last_glyph = 0
    for y in range(limit):
        diff = np.abs(band[y] - bg).max(axis=1)
        if (diff > 60).sum() > 4:
            last_glyph = y
    if not last_glyph:
        return 0
    # Android centres the glyphs in the bar, so the bar runs roughly as far
    # below them as above.
    return min(int(last_glyph * 1.6), 120)


def measure(path):
    """Status and navigation bar heights for one capture."""
    a = np.asarray(Image.open(path).convert('RGB')).astype(int)
    return find_status_bar(a), find_nav_bar(a)


def prepare(path, status, nav):
    im = Image.open(path).convert('RGB')
    w, h = im.size

    im = im.crop((0, status, w, h - nav))
    w, h = im.size

    # Still too tall? Take the remainder off the top, which is dead padding
    # far more often than the bottom is.
    if h > w * MAX_RATIO:
        im = im.crop((0, h - int(w * MAX_RATIO), w, h))
        w, h = im.size

    return im


def main():
    if not os.path.isdir(SRC):
        sys.exit(f'no screenshots at {SRC}')
    os.makedirs(OUT, exist_ok=True)

    names = sorted(n for n in os.listdir(SRC) if n.lower().endswith('.png'))
    if not names:
        sys.exit(f'no .png files in {SRC}')

    # Every shot comes off the same phone, so the system bars are the same
    # height in all of them. Measuring per image lets one bad reading through:
    # a card overlapping the navigation bar breaks the flat-fill detection and
    # leaves a sliver of the back button in the listing. Take the batch median
    # instead, which one odd image cannot move.
    measured = [measure(os.path.join(SRC, n)) for n in names]
    status = int(np.median([m[0] for m in measured]))
    nav = int(np.median([m[1] for m in measured]))
    print(f'system bars: {status}px top, {nav}px bottom '
          f'(median of {len(names)})\n')

    failures = 0
    for name in names:
        im = prepare(os.path.join(SRC, name), status, nav)
        dest = os.path.join(OUT, name)
        # 24-bit PNG, no alpha - Play rejects alpha on store assets.
        im.save(dest, optimize=True)

        w, h = im.size
        size = os.path.getsize(dest)
        problems = []
        if min(w, h) < MIN_SIDE:
            problems.append('side under 320px')
        if max(w, h) > MAX_SIDE:
            problems.append('side over 3840px')
        if max(w, h) > min(w, h) * MAX_RATIO:
            problems.append(f'ratio {max(w, h) / min(w, h):.2f}:1 over 2:1')
        if size > MAX_BYTES:
            problems.append('over 8MB')

        status_txt = 'OK' if not problems else 'REJECT: ' + '; '.join(problems)
        if problems:
            failures += 1
        print(f'{name:28} {w}x{h}  {size // 1024:>5}KB  '
              f'{status_txt}')

    print(f'\n{len(names)} prepared in {OUT}')
    if failures:
        sys.exit(f'{failures} would be rejected by Play')


if __name__ == '__main__':
    main()
