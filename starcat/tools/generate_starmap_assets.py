from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "vfx" / "starmap"
SIZE = 384


def clamp(value: float, low: int = 0, high: int = 255) -> int:
    return max(low, min(high, int(value)))


def add_star(draw: ImageDraw.ImageDraw, x: float, y: float, radius: float, color: tuple[int, int, int], alpha: int) -> None:
    for step in range(5, 0, -1):
        r = radius * step / 5.0
        a = alpha * (step / 5.0) ** 2
        draw.ellipse((x - r, y - r, x + r, y + r), fill=(*color, clamp(a)))


def make_system(name: str, palette: list[tuple[int, int, int]], seed: int, kind: str = "solar") -> None:
    rng = random.Random(seed)
    base = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    haze = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(haze, "RGBA")
    cx = cy = SIZE / 2

    for i in range(7600):
        angle = rng.random() * math.tau
        arm = 1.0 + 0.32 * math.sin(angle * (2.0 + seed % 3) + seed)
        radius = (rng.random() ** 0.58) * 162 * arm
        if kind == "black_hole":
            radius = 42 + (rng.random() ** 0.7) * 116
        elif kind == "binary":
            radius = (rng.random() ** 0.54) * 150
        jitter = rng.gauss(0, 10 + radius * 0.025)
        spiral = angle + radius * 0.032
        x = cx + math.cos(spiral) * radius + math.cos(angle + math.pi / 2) * jitter
        y = cy + math.sin(spiral) * radius * 0.82 + math.sin(angle + math.pi / 2) * jitter
        if not (0 <= x < SIZE and 0 <= y < SIZE):
            continue
        color = palette[int((radius / 170) * (len(palette) - 1)) % len(palette)]
        alpha = clamp(10 + 80 * (1.0 - radius / 180.0) + rng.random() * 28)
        draw.point((x, y), fill=(*color, alpha))

    haze = haze.filter(ImageFilter.GaussianBlur(0.72))
    base.alpha_composite(haze)

    core = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    cdraw = ImageDraw.Draw(core, "RGBA")
    if kind == "black_hole":
        for r, a in [(112, 32), (78, 50), (48, 74)]:
            cdraw.ellipse((cx - r, cy - r * 0.62, cx + r, cy + r * 0.62), outline=(*palette[-1], a), width=4)
        cdraw.ellipse((cx - 30, cy - 30, cx + 30, cy + 30), fill=(3, 5, 9, 246))
        cdraw.ellipse((cx - 38, cy - 38, cx + 38, cy + 38), outline=(*palette[-1], 118), width=3)
    elif kind == "binary":
        add_star(cdraw, cx - 21, cy - 10, 22, palette[0], 220)
        add_star(cdraw, cx + 28, cy + 13, 15, palette[1], 190)
    else:
        add_star(cdraw, cx, cy, 24 if kind != "cluster" else 18, palette[0], 225)
        if kind == "cluster":
            for _ in range(16):
                angle = rng.random() * math.tau
                radius = rng.uniform(18, 82)
                add_star(cdraw, cx + math.cos(angle) * radius, cy + math.sin(angle) * radius, rng.uniform(3.0, 7.0), rng.choice(palette), 120)

    base.alpha_composite(core.filter(ImageFilter.GaussianBlur(0.18)))

    rim = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    rdraw = ImageDraw.Draw(rim, "RGBA")
    for _ in range(190):
        angle = rng.random() * math.tau
        radius = rng.uniform(48, 160)
        x = cx + math.cos(angle + radius * 0.025) * radius
        y = cy + math.sin(angle + radius * 0.025) * radius * 0.84
        color = rng.choice(palette)
        rdraw.ellipse((x - 0.9, y - 0.9, x + 0.9, y + 0.9), fill=(*color, rng.randint(70, 170)))
    base.alpha_composite(rim)
    base.save(OUT / name)


def make_lane(name: str, color: tuple[int, int, int], accent: tuple[int, int, int]) -> None:
    img = Image.new("RGBA", (512, 128), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, "RGBA")
    y = 64
    for x in range(-40, 552, 56):
        draw.line((x, y, x + 26, y), fill=(*color, 58), width=2)
        draw.line((x + 33, y, x + 43, y), fill=(*accent, 30), width=1)
    for x in range(0, 512, 128):
        draw.polygon([(x + 22, y), (x + 32, y - 6), (x + 42, y), (x + 32, y + 6)], outline=(*accent, 50))
    img = img.filter(ImageFilter.GaussianBlur(0.22))
    img.save(OUT / name)


def make_fleet_marker() -> None:
    img = Image.new("RGBA", (384, 384), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, "RGBA")
    color = (216, 246, 255)
    points = [(192, 40), (326, 250), (220, 218), (192, 344), (164, 218), (58, 250)]
    draw.polygon(points, outline=(*color, 210), fill=(*color, 34))
    draw.line([(192, 66), (192, 300)], fill=(*color, 172), width=10)
    draw.line([(118, 230), (192, 118), (266, 230)], fill=(*color, 164), width=9, joint="curve")
    draw.polygon([(192, 34), (220, 92), (192, 76), (164, 92)], fill=(*color, 174))
    img.filter(ImageFilter.GaussianBlur(0.15)).save(OUT / "fleet_marker_chevron.png")


def make_all() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    make_system("system_solar.png", [(255, 235, 184), (138, 207, 255), (104, 138, 210)], 11)
    make_system("system_solar_dust.png", [(255, 218, 156), (214, 137, 88), (110, 142, 170)], 12)
    make_system("system_solar_blue.png", [(185, 229, 255), (96, 178, 255), (135, 123, 255)], 13)
    make_system("system_red_dwarf.png", [(255, 151, 118), (204, 77, 72), (118, 76, 122)], 14)
    make_system("system_binary.png", [(255, 230, 156), (124, 203, 255), (126, 121, 194)], 21, "binary")
    make_system("system_binary_close.png", [(255, 201, 111), (255, 112, 80), (120, 164, 218)], 22, "binary")
    make_system("system_binary_accretion.png", [(255, 222, 140), (234, 122, 83), (144, 221, 214)], 23, "binary")
    make_system("system_storm.png", [(169, 230, 255), (119, 143, 255), (111, 244, 218)], 31)
    make_system("system_magnetar_storm.png", [(231, 242, 255), (112, 188, 255), (168, 110, 255)], 32)
    make_system("system_black_hole.png", [(150, 171, 188), (92, 113, 143), (226, 233, 243)], 41, "black_hole")
    make_system("system_black_hole_lensed.png", [(187, 212, 222), (116, 140, 178), (245, 236, 214)], 42, "black_hole")
    make_system("system_nebula.png", [(138, 236, 222), (75, 161, 196), (130, 126, 202)], 51, "cluster")
    make_system("system_star_cluster.png", [(235, 242, 255), (130, 204, 255), (255, 199, 139)], 52, "cluster")
    make_system("system_colony_hub.png", [(236, 244, 250), (122, 225, 215), (74, 148, 174)], 61, "cluster")
    make_system("system_colony_orbital.png", [(224, 242, 245), (109, 212, 198), (226, 134, 77)], 62, "cluster")
    make_lane("hyperlane_dash.png", (138, 196, 211), (209, 235, 239))
    make_lane("wormhole_route_tick.png", (142, 224, 211), (240, 225, 183))
    make_fleet_marker()


if __name__ == "__main__":
    make_all()
