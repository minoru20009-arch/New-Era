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
