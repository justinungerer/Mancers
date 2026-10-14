# -*- coding: utf-8 -*-
"""Rasterize the DocuMancer app icon (teal tile + document + sparkle) to PNG/ICO."""
from pathlib import Path
import math
import struct
from io import BytesIO
from PIL import Image, ImageDraw

ROOT = Path(r"C:\Users\ELMYZ\dm-src\assets\app-icon")
ID = "ai.storyteller.pdfcraft"


def rounded_mask(size, rx):
    m = Image.new("L", (size, size), 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, size - 1, size - 1), radius=rx, fill=255)
    return m


def draw_icon(size: int) -> Image.Image:
    s = size / 512.0
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    pix = img.load()
    for y in range(size):
        t = y / max(size - 1, 1)
        r = int(20 + (13 - 20) * t)
        g = int(184 + (148 - 184) * t)
        b = int(166 + (136 - 166) * t)
        for x in range(size):
            pix[x, y] = (r, g, b, 255)
    draw = ImageDraw.Draw(img)

    def rr(x, y, w, h, rad, fill):
        draw.rounded_rectangle(
            [x * s, y * s, (x + w) * s, (y + h) * s],
            radius=max(1, int(rad * s)),
            fill=fill,
        )

    # document
    rr(152, 96, 240, 304, 28, (255, 255, 255, 255))
    # folded corner (triangle over page)
    draw.polygon(
        [(320 * s, 96 * s), (392 * s, 168 * s), (320 * s, 168 * s)],
        fill=(153, 226, 214, 255),
    )
    draw.polygon(
        [(320 * s, 96 * s), (336 * s, 168 * s), (320 * s, 152 * s)],
        fill=(209, 245, 240, 255),
    )
    # cover under-fold page edge with a clean diagonal highlight strip
    draw.line([(320 * s, 96 * s), (392 * s, 168 * s)], fill=(180, 235, 225, 255), width=max(1, int(2 * s)))

    # text lines (solid, readable at 16px as bands)
    for y, w, shade in ((200, 160, 90), (236, 140, 110), (272, 150, 130), (308, 100, 150)):
        rr(176, y, w, 14, 7, (13, 148, 136, 255) if size >= 48 else (13, 148, 136, 255))
        # lighten by overlaying white at small sizes via shorter solid teal-grey
        if size < 48:
            rr(176, y, w, 14, 7, (80, 160, 150, 255))

    # sparkle badge — solid teal disc + white 4-point star (no wand; clearer at 16px)
    cx, cy, rad = 348 * s, 340 * s, 34 * s
    if size <= 24:
        cx, cy, rad = 360 * s, 350 * s, 40 * s
    draw.ellipse([cx - rad, cy - rad, cx + rad, cy + rad], fill=(15, 118, 110, 255))
    outer = 18 * s if size > 24 else 22 * s
    inner = 5 * s if size > 24 else 6 * s
    pts = []
    for i in range(8):
        ang = -math.pi / 2 + i * math.pi / 4
        rr_ = outer if i % 2 == 0 else inner
        pts.append((cx + rr_ * math.cos(ang), cy + rr_ * math.sin(ang)))
    draw.polygon(pts, fill=(255, 255, 255, 255))

    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    out.paste(img, (0, 0), rounded_mask(size, max(1, int(112 * s))))
    return out


def write_ico(path: Path, sizes):
    blobs = []
    for sz in sizes:
        buf = BytesIO()
        draw_icon(sz).save(buf, format="PNG")
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
    svg = (ROOT / "pdfcraft.svg").read_text(encoding="utf-8")
    (ROOT / "pdfcraft-small.svg").write_text(svg, encoding="utf-8")
    body = draw_icon(824)
    mac = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    mac.paste(body, (100, 100), body)
    mac.save(ROOT / "pdfcraft-1024.png")
    for sz in (16, 24, 32, 48, 64, 128, 256, 512):
        d = ROOT / "hicolor" / f"{sz}x{sz}" / "apps"
        d.mkdir(parents=True, exist_ok=True)
        draw_icon(sz).save(d / f"{ID}.png")
    scal = ROOT / "hicolor" / "scalable" / "apps"
    scal.mkdir(parents=True, exist_ok=True)
    (scal / f"{ID}.svg").write_text(svg, encoding="utf-8")
    write_ico(ROOT / "pdfcraft.ico", [16, 20, 24, 32, 40, 48, 64, 128, 256])
    print("ok")


if __name__ == "__main__":
    main()
