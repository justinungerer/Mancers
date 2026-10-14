# -*- coding: utf-8 -*-
"""RenderRoulette app icon: coral rounded tile, white roulette ring with 8 notches, white play
triangle. Writes the SVG masters and every raster the repo carries (same geometry everywhere).

usage: python gen-app-icon.py <assets/app-icon dir> <file stem> <app id> <tmp dir>
"""
import math
import struct
import sys
from io import BytesIO
from pathlib import Path

from PIL import Image, ImageDraw

CORAL = (240, 90, 70)
CORAL_DARK = (214, 66, 48)
WHITE = (255, 255, 255)
TILE_RX = 112
CX = CY = 256
RING_R = 150          # centre line of the ring
NOTCHES = 8
GAP_DEG = 9.0         # angular width of each notch
TRI = [(222.0, 182.0), (222.0, 330.0), (340.0, 256.0)]  # play triangle, centroid ~ (261, 256)
TRI_JOIN = 18         # rounded corners (stroke width of the round join)


def params(size):
    """Small sizes get a thicker ring and fewer, wider notches so the shape survives at 16 px."""
    if size <= 24:
        return 52, 6, 16.0
    if size <= 48:
        return 44, 8, 11.0
    return 38, NOTCHES, GAP_DEG


def svg(ring_w=38, notches=NOTCHES, gap=GAP_DEG):
    circ = 2 * math.pi * RING_R
    seg = circ / notches
    g = circ * gap / 360.0
    dash = seg - g
    off = seg - g / 2  # centres a notch on 0 deg (3 o'clock) and every 360/n after it
    tri = " ".join(f"{x:g},{y:g}" for x, y in TRI)
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
<title>RenderRoulette</title>
<defs><linearGradient id="g" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#f05a46"/><stop offset="1" stop-color="#d64230"/></linearGradient></defs>
<rect width="512" height="512" rx="{TILE_RX}" fill="url(#g)"/>
<circle cx="{CX}" cy="{CY}" r="{RING_R}" fill="none" stroke="#ffffff" stroke-width="{ring_w}" stroke-dasharray="{dash:.3f} {g:.3f}" stroke-dashoffset="{off:.3f}"/>
<polygon points="{tri}" fill="#ffffff" stroke="#ffffff" stroke-width="{TRI_JOIN}" stroke-linejoin="round"/>
</svg>
"""


def draw(size):
    ss = 8 if size <= 64 else 4
    n = size * ss
    k = n / 512.0
    ring_w, notches, gap = params(size)
    img = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    grad = Image.new("RGBA", (1, n))
    for y in range(n):
        t = y / max(n - 1, 1)
        grad.putpixel((0, y), tuple(int(a + (b - a) * t) for a, b in zip(CORAL, CORAL_DARK)) + (255,))
    grad = grad.resize((n, n))
    mask = Image.new("L", (n, n), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, n - 1, n - 1), radius=TILE_RX * k, fill=255)
    img.paste(grad, (0, 0), mask)
    d = ImageDraw.Draw(img)
    r_out = (RING_R + ring_w / 2) * k
    box = (CX * k - r_out, CY * k - r_out, CX * k + r_out, CY * k + r_out)
    step = 360.0 / notches
    for i in range(notches):
        a0 = i * step + gap / 2
        d.arc(box, a0, a0 + step - gap, fill=WHITE + (255,), width=round(ring_w * k))
    pts = [(x * k, y * k) for x, y in TRI]
    d.polygon(pts, fill=WHITE + (255,))
    jr = TRI_JOIN / 2 * k
    for i, (x, y) in enumerate(pts):
        nx, ny = pts[(i + 1) % 3]
        d.line([(x, y), (nx, ny)], fill=WHITE + (255,), width=round(TRI_JOIN * k))
        d.ellipse((x - jr, y - jr, x + jr, y + jr), fill=WHITE + (255,))
    return img.resize((size, size), Image.LANCZOS)


def mac(size):
    """Apple grid: an 824/1024 body centred with a transparent margin."""
    body = draw(round(size * 824 / 1024))
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    o = (size - body.size[0]) // 2
    out.paste(body, (o, o), body)
    return out


def write_ico(path, sizes):
    blobs = []
    for sz in sizes:
        buf = BytesIO()
        draw(sz).save(buf, format="PNG")
        blobs.append(buf.getvalue())
    head = struct.pack("<HHH", 0, 1, len(blobs))
    entries, data, offset = b"", b"", 6 + 16 * len(blobs)
    for b in blobs:
        w, h = struct.unpack(">II", b[16:24])
        entries += struct.pack("<BBBBHHII", w % 256, h % 256, 0, 0, 1, 32, len(b), offset)
        data += b
        offset += len(b)
    path.write_bytes(head + entries + data)


def main():
    root, stem, app_id, tmp = Path(sys.argv[1]), sys.argv[2], sys.argv[3], Path(sys.argv[4])
    tmp.mkdir(parents=True, exist_ok=True)
    nl = dict(encoding="utf-8", newline="\n")
    (root / f"{stem}.svg").write_text(svg(), **nl)
    (root / f"{stem}-small.svg").write_text(svg(*params(16)), **nl)
    scal = root / "hicolor" / "scalable" / "apps"
    scal.mkdir(parents=True, exist_ok=True)
    (scal / f"{app_id}.svg").write_text(svg(), **nl)
    draw(1024).save(root / f"{stem}-1024.png", optimize=True)
    mac(512).save(root / f"{stem}-macos-512.png", optimize=True)
    for sz in (16, 24, 32, 48, 64, 128, 256, 512):
        dd = root / "hicolor" / f"{sz}x{sz}" / "apps"
        dd.mkdir(parents=True, exist_ok=True)
        draw(sz).save(dd / f"{app_id}.png", optimize=True)
    write_ico(root / f"{stem}.ico", [16, 20, 24, 32, 40, 48, 64, 128, 256])
    mac(1024).save(tmp / "mac-1024.png")
    sheet = Image.new("RGBA", (16 + 24 + 32 + 48 + 64 + 128 + 70, 140), (255, 255, 255, 255))
    x = 5
    for sz in (16, 24, 32, 48, 64, 128):
        im = draw(sz)
        sheet.paste(im, (x, 5), im)
        x += sz + 10
    sheet.save(tmp / "icon-sizes.png")
    print("ok")


if __name__ == "__main__":
    main()
