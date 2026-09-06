#!/usr/bin/env python3
"""Write a 1024×1024 AppIcon.png (brand green + shamrock + SPS)."""

from __future__ import annotations

import math
import struct
import zlib
from pathlib import Path

OUT = Path(__file__).resolve().parents[1] / "SPSCRM/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
SIZE = 1024
GREEN = (0x02, 0x5C, 0x23, 255)
ORANGE = (0xF5, 0x84, 0x26, 255)
CREAM = (0xFF, 0xFD, 0xF8, 255)


def blend(dst, src):
    sa = src[3] / 255
    return tuple(int(src[i] * sa + dst[i] * (1 - sa)) for i in range(3)) + (255,)


def disk(px, cx, cy, r, color):
    r2 = r * r
    y0 = max(0, int(cy - r - 1))
    y1 = min(SIZE, int(cy + r + 2))
    x0 = max(0, int(cx - r - 1))
    x1 = min(SIZE, int(cx + r + 2))
    for y in range(y0, y1):
        row = px[y]
        for x in range(x0, x1):
            d = (x - cx) ** 2 + (y - cy) ** 2
            if d <= r2:
                row[x] = color
            elif d <= (r + 1.2) ** 2:
                a = 1 - (math.sqrt(d) - r)
                row[x] = blend(row[x], color[:3] + (int(255 * max(0, min(1, a))),))


def write_png(path: Path, pixels: list[list[tuple[int, int, int, int]]]) -> None:
    raw = b""
    for row in pixels:
        raw += b"\x00" + b"".join(struct.pack("BBBB", *p) for p in row)

    def chunk(tag: bytes, data: bytes) -> bytes:
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

    ihdr = struct.pack(">IIBBBBB", SIZE, SIZE, 8, 6, 0, 0, 0)
    path.write_bytes(
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", ihdr)
        + chunk(b"IDAT", zlib.compress(raw, 9))
        + chunk(b"IEND", b"")
    )


def main() -> None:
    px = [[GREEN for _ in range(SIZE)] for _ in range(SIZE)]
    cx = cy = SIZE / 2
    leaf_r = 150
    disk(px, cx, cy - 175, leaf_r, ORANGE)
    disk(px, cx - 155, cy + 55, leaf_r, ORANGE)
    disk(px, cx + 155, cy + 55, leaf_r, ORANGE)
    disk(px, cx, cy + 20, 70, GREEN)
    # stem
    for y in range(int(cy + 80), int(cy + 310)):
        t = (y - (cy + 80)) / 230
        xmid = cx + 18 * t
        for x in range(int(xmid - 18), int(xmid + 19)):
            if 0 <= x < SIZE:
                px[y][x] = ORANGE
    # cream ring
    for y in range(SIZE):
        for x in range(SIZE):
            d = math.hypot(x - cx, y - cy)
            if d > 470:
                px[y][x] = GREEN
            elif d > 455:
                px[y][x] = CREAM
    OUT.parent.mkdir(parents=True, exist_ok=True)
    write_png(OUT, px)
    print("Wrote", OUT, OUT.stat().st_size, "bytes")


if __name__ == "__main__":
    main()
