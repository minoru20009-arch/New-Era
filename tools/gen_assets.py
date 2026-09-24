"""Generates the placeholder pixel-art assets for New Era.

Run from the repo root:  python3 tools/gen_assets.py
Outputs assets/1x and assets/2x (2x is a nearest-neighbour upscale, so pixels stay crisp).
"""
from PIL import Image, ImageDraw

W, H = 71, 95


def hexc(h, a=255):
    h = h.lstrip('#')
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


def lerp(c1, c2, t):
    return tuple(int(round(a + (b - a) * t)) for a, b in zip(c1, c2))


def card_mask():
    """Rounded-rectangle alpha mask matching Balatro's card silhouette."""
    m = Image.new('L', (W, H), 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, W - 1, H - 1], radius=5, fill=255)
    return m


def gradient(top, bottom):
    img = Image.new('RGBA', (W, H))
    px = img.load()
    for y in range(H):
        c = lerp(top, bottom, y / (H - 1))
        for x in range(W):
            px[x, y] = c
    return img


def frame(top, bottom, border, inner, emblem):
    img = gradient(hexc(top), hexc(bottom))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([0, 0, W - 1, H - 1], radius=5, outline=hexc(border), width=2)
    d.rounded_rectangle([3, 3, W - 4, H - 4], radius=3, outline=hexc(inner), width=1)
    emblem(d)
    out = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    out.paste(img, (0, 0), card_mask())
    return out


cx, cy = W // 2, H // 2


def emblem_unranked(d):
    c = hexc('#7D8BA1')
    d.polygon([(cx, cy - 14), (cx + 10, cy), (cx, cy + 14), (cx - 10, cy)], outline=c)
    d.polygon([(cx, cy - 7), (cx + 5, cy), (cx, cy + 7), (cx - 5, cy)], fill=hexc('#4A5568'))


def emblem_demonic(d):
    red = hexc('#B3122E')
    d.polygon([(cx - 12, cy - 4), (cx - 18, cy - 20), (cx - 6, cy - 9)], fill=red)
    d.polygon([(cx + 12, cy - 4), (cx + 18, cy - 20), (cx + 6, cy - 9)], fill=red)
    d.ellipse([cx - 10, cy - 8, cx + 10, cy + 12], outline=red, width=2)
    d.ellipse([cx - 3, cy - 1, cx + 3, cy + 5], fill=hexc('#FF4D4D'))


def emblem_heavenly(d):
    gold = hexc('#D4AF37')
    d.ellipse([cx - 14, cy - 22, cx + 14, cy - 14], outline=gold, width=2)
    d.polygon([(cx, cy - 8), (cx + 4, cy + 2), (cx + 14, cy + 4), (cx + 5, cy + 9),
               (cx + 8, cy + 20), (cx, cy + 13), (cx - 8, cy + 20), (cx - 5, cy + 9),
               (cx - 14, cy + 4), (cx - 4, cy + 2)], fill=gold)


def hybrid():
    left = frame('#FFF6DA', '#E8D9A8', '#D4AF37', '#F2E3B3', emblem_heavenly)
    right = frame('#1A0A0E', '#3B0A14', '#B3122E', '#5C1020', emblem_demonic)
    out = left.copy()
    out.paste(right.crop((W // 2, 0, W, H)), (W // 2, 0))
    d = ImageDraw.Draw(out)
    d.line([(W // 2, 2), (W // 2, H - 3)], fill=hexc('#C9A227'), width=1)
    return out


frames = [
    frame('#2A3140', '#1C2230', '#7D8BA1', '#4A5568', emblem_unranked),
    frame('#1A0A0E', '#3B0A14', '#B3122E', '#5C1020', emblem_demonic),
    frame('#FFF6DA', '#E8D9A8', '#D4AF37', '#F2E3B3', emblem_heavenly),
    hybrid(),
]

sheet = Image.new('RGBA', (W * len(frames), H), (0, 0, 0, 0))
for i, f in enumerate(frames):
    sheet.paste(f, (i * W, 0))
sheet.save('assets/1x/ne_frames.png')
sheet.resize((sheet.width * 2, sheet.height * 2), Image.NEAREST).save('assets/2x/ne_frames.png')

# Formation planets (src/formation/planets.lua): one 71x95 card per formation, in priority order.
# A planet over a star field, and the formation's 5x3 diagram (same cells as
# Formation.DIAGRAMS in src/formation/ui_diagram.lua) at the bottom.
import random

DIAGRAMS = [
    ('empyrea', '#F6E7A8', '#C9A227', 'ring', 'all'),
    ('polaris', '#D8F1FF', '#6FB7E8', None, [(1, 2), (2, 2), (3, 2), (4, 2), (5, 2)]),
    ('andromeda', '#E7B8F2', '#8E4FB3', 'ring', [(1, 1), (2, 1), (3, 1), (4, 1), (5, 1)]),
    ('pegasus', '#9FE3D6', '#2F8F83', None, [(2, 1), (3, 1), (2, 2), (3, 2)]),
    ('nibiru', '#E0605A', '#6E1420', 'ring', [(1, 1), (2, 2), (3, 3)]),
    ('sirius', '#FFFFFF', '#9CC7FF', None, [(5, 1), (4, 2), (3, 3)]),
    ('crux', '#9BE08A', '#3D8A3A', None, [(3, 2), (3, 1), (2, 2), (4, 2), (3, 3)]),
    ('perseus', '#F7B267', '#C0561D', None, [(1, 1), (2, 1), (3, 1), (5, 2), (5, 3)]),
    ('cygnus', '#8FE9F2', '#1F8DA3', 'ring', [(1, 3), (2, 3), (3, 3), (4, 3), (5, 3)]),
    ('sagitta', '#D6F28A', '#7FA32A', None, [(1, 2), (2, 2), (3, 2), (4, 2), (5, 2)]),
    ('draco', '#7FBF8E', '#245C3A', None, [(3, 2), (4, 2), (3, 3), (4, 3)]),
    ('orion', '#8FB4FF', '#2E4FA8', None, [(2, 2), (3, 2), (4, 2)]),
    ('aquila', '#E8C98A', '#8A6424', None, [(2, 3), (3, 2), (4, 1)]),
    ('pollux', '#FFD08A', '#C98A1E', None, [(1, 1), (2, 1), (4, 2), (4, 3)]),
    ('lyra', '#C9A8FF', '#5E3FB3', 'ring', [(3, 1), (3, 2), (3, 3)]),
    ('gemini', '#FFF08A', '#C9B21E', None, [(2, 2), (3, 2)]),
    ('proxima', '#FF9B6B', '#B3401D', None, [(3, 2)]),
]


def planet_card(i, name, light, dark, ring, cells):
    img = gradient(hexc('#10142A'), hexc('#1D1238'))
    d = ImageDraw.Draw(img)
    rnd = random.Random(1000 + i)
    for _ in range(22):
        x, y = rnd.randrange(4, W - 4), rnd.randrange(4, 60)
        d.point((x, y), fill=hexc('#FFFFFF', rnd.choice([120, 180, 255])))
    pcx, pcy, pr = W // 2, 32, 17
    # planet: dark rim, lit disc offset to the upper left, a highlight
    d.ellipse([pcx - pr, pcy - pr, pcx + pr, pcy + pr], fill=hexc(dark))
    d.ellipse([pcx - pr + 2, pcy - pr + 1, pcx + pr - 5, pcy + pr - 6], fill=hexc(light))
    d.ellipse([pcx - pr + 6, pcy - pr + 5, pcx - pr + 11, pcy - pr + 10], fill=hexc('#FFFFFF', 200))
    for k in range(3):  # bands
        y = pcy - 6 + k * 6
        d.line([(pcx - pr + 4, y), (pcx + pr - 6, y + 1)], fill=hexc(dark, 90), width=1)
    if ring:
        d.ellipse([pcx - pr - 8, pcy - 4, pcx + pr + 8, pcy + 4], outline=hexc('#FFFFFF', 170), width=1)
    d.rounded_rectangle([0, 0, W - 1, H - 1], radius=5, outline=hexc(dark), width=2)
    # diagram: 5x3 cells of 7x5 px, 2 px gaps
    cw, ch, gap = 7, 5, 2
    gw, gh = 5 * cw + 4 * gap, 3 * ch + 2 * gap
    x0, y0 = (W - gw) // 2, 64
    d.rounded_rectangle([x0 - 3, y0 - 3, x0 + gw + 2, y0 + gh + 2], radius=2, fill=hexc('#0A0A14'))
    lit = set()
    if cells == 'all':
        lit = {(c, r) for c in range(1, 6) for r in range(1, 4)}
    else:
        lit = set(cells)
    for r in range(1, 4):
        for c in range(1, 6):
            x, y = x0 + (c - 1) * (cw + gap), y0 + (r - 1) * (ch + gap)
            col = hexc(light) if (c, r) in lit else hexc('#3A3A4A')
            d.rectangle([x, y, x + cw - 1, y + ch - 1], fill=col)
    out = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    out.paste(img, (0, 0), card_mask())
    return out


psheet = Image.new('RGBA', (W * len(DIAGRAMS), H), (0, 0, 0, 0))
for i, (name, light, dark, ring, cells) in enumerate(DIAGRAMS):
    psheet.paste(planet_card(i, name, light, dark, ring, cells), (i * W, 0))
psheet.save('assets/1x/ne_planets.png')
psheet.resize((psheet.width * 2, psheet.height * 2), Image.NEAREST).save('assets/2x/ne_planets.png')

# Mod icon: 34x34 (1x) gold halo over a dark disc with a split light/dark core.
I = 34
icon = Image.new('RGBA', (I, I), (0, 0, 0, 0))
d = ImageDraw.Draw(icon)
d.ellipse([1, 1, I - 2, I - 2], fill=hexc('#1B1B1B'), outline=hexc('#C9A227'), width=2)
d.pieslice([8, 8, I - 9, I - 9], 90, 270, fill=hexc('#FFF6DA'))
d.pieslice([8, 8, I - 9, I - 9], 270, 90, fill=hexc('#B3122E'))
d.ellipse([12, 4, I - 13, 7], outline=hexc('#D4AF37'), width=1)
icon.save('assets/1x/icon.png')
icon.resize((I * 2, I * 2), Image.NEAREST).save('assets/2x/icon.png')
print('assets generated')
