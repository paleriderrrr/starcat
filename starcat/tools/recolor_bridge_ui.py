from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
BRIDGE_ASSET_DIR = ROOT / "assets" / "ui" / "bridge"
MENU_ASSET_DIR = ROOT / "assets" / "ui" / "menu"
SOURCE_ASSET_DIR = ROOT / "assets" / "ui" / "source"
SOURCE_SHEET_ALPHA = SOURCE_ASSET_DIR / "generated_ui_sheet_alpha.png"

TARGET_SIZES: dict[str, tuple[int, int]] = {
    "button_base.png": (192, 72),
    "button_hover.png": (192, 72),
    "button_pressed.png": (192, 72),
    "button_disabled.png": (192, 72),
    "card_shell.png": (256, 192),
    "card_shell_alert.png": (256, 192),
    "chip_panel.png": (256, 112),
    "divider_glow.png": (1024, 24),
    "info_line_panel.png": (512, 84),
    "input_panel.png": (640, 240),
    "input_panel_focus.png": (640, 240),
    "panel_shell.png": (256, 256),
    "panel_shell_strong.png": (256, 256),
    "section_title_panel.png": (512, 72),
    "tab_active.png": (320, 104),
    "tab_idle.png": (320, 104),
}

SOURCE_CROPS: dict[str, tuple[int, int, int, int]] = {
    "button_base.png": (434, 487, 557, 523),
    "button_hover.png": (573, 488, 706, 527),
    "button_pressed.png": (858, 488, 1001, 528),
    "button_disabled.png": (1004, 488, 1139, 528),
    "card_shell.png": (22, 762, 190, 896),
    "card_shell_alert.png": (1165, 681, 1516, 780),
    "chip_panel.png": (576, 289, 717, 344),
    "divider_glow.png": (20, 111, 358, 121),
    "info_line_panel.png": (1158, 550, 1515, 653),
    "input_panel.png": (435, 549, 557, 588),
    "input_panel_focus.png": (573, 549, 706, 589),
    "panel_shell.png": (384, 762, 512, 896),
    "panel_shell_strong.png": (1170, 119, 1514, 520),
    "section_title_panel.png": (930, 37, 1109, 84),
    "tab_active.png": (300, 922, 443, 996),
    "tab_idle.png": (170, 922, 299, 996),
}

STATE_TUNING: dict[str, dict[str, float]] = {
    "button_base.png": {"alpha": 0.86, "brightness": 0.94, "contrast": 1.08, "cyan": 0.05},
    "button_hover.png": {"alpha": 1.0, "brightness": 1.18, "contrast": 1.12, "cyan": 0.18},
    "button_pressed.png": {"alpha": 0.98, "brightness": 0.30, "contrast": 1.28, "cyan": 0.22, "amber": 0.04},
    "button_disabled.png": {"alpha": 0.48, "brightness": 0.56, "contrast": 0.78},
    "card_shell_alert.png": {"alpha": 0.98, "brightness": 1.08, "contrast": 1.14, "amber": 0.32},
    "input_panel_focus.png": {"alpha": 1.0, "brightness": 1.12, "contrast": 1.15, "cyan": 0.22},
    "panel_shell_strong.png": {"alpha": 0.98, "brightness": 1.06, "contrast": 1.10, "cyan": 0.08},
    "section_title_panel.png": {"alpha": 0.96, "brightness": 1.08, "contrast": 1.10, "cyan": 0.14},
    "tab_active.png": {"alpha": 1.0, "brightness": 1.12, "contrast": 1.16, "amber": 0.58},
    "tab_idle.png": {"alpha": 0.72, "brightness": 0.82, "contrast": 0.92},
}

BUTTON_STATES: dict[str, dict[str, tuple[int, int, int, int] | int]] = {
    "button_base.png": {
        "fill": (10, 32, 35, 214),
        "border": (94, 156, 156, 212),
        "accent": (255, 126, 32, 160),
        "glow": (72, 218, 230, 54),
    },
    "button_hover.png": {
        "fill": (13, 62, 64, 230),
        "border": (82, 226, 232, 232),
        "accent": (255, 126, 32, 180),
        "glow": (72, 226, 232, 92),
    },
    "button_pressed.png": {
        "fill": (9, 20, 20, 238),
        "border": (132, 94, 40, 224),
        "accent": (255, 126, 32, 188),
        "glow": (255, 126, 32, 42),
    },
    "button_disabled.png": {
        "fill": (20, 31, 32, 145),
        "border": (86, 102, 101, 140),
        "accent": (128, 102, 68, 86),
        "glow": (72, 122, 128, 22),
    },
}

FRAME_STATES: dict[str, dict[str, tuple[int, int, int, int] | float]] = {
    "panel_shell.png": {
        "fill": (6, 24, 27, 214),
        "border": (64, 154, 156, 184),
        "accent": (255, 126, 32, 98),
        "glow": (70, 222, 235, 34),
        "line": (70, 222, 235, 40),
        "margin": 0.10,
    },
    "panel_shell_strong.png": {
        "fill": (8, 32, 36, 230),
        "border": (84, 178, 178, 210),
        "accent": (255, 126, 32, 124),
        "glow": (70, 222, 235, 52),
        "line": (70, 222, 235, 52),
        "margin": 0.10,
    },
    "card_shell.png": {
        "fill": (8, 30, 32, 216),
        "border": (70, 166, 166, 190),
        "accent": (255, 126, 32, 104),
        "glow": (70, 222, 235, 34),
        "line": (70, 222, 235, 34),
        "margin": 0.12,
    },
    "card_shell_alert.png": {
        "fill": (22, 32, 28, 222),
        "border": (222, 136, 42, 218),
        "accent": (255, 126, 32, 176),
        "glow": (255, 126, 32, 46),
        "line": (255, 156, 64, 36),
        "margin": 0.12,
    },
    "chip_panel.png": {
        "fill": (8, 28, 31, 214),
        "border": (70, 166, 166, 180),
        "accent": (255, 126, 32, 96),
        "glow": (70, 222, 235, 28),
        "line": (70, 222, 235, 28),
        "margin": 0.15,
    },
    "info_line_panel.png": {
        "fill": (7, 26, 29, 196),
        "border": (70, 166, 166, 142),
        "accent": (255, 126, 32, 72),
        "glow": (70, 222, 235, 18),
        "line": (70, 222, 235, 24),
        "margin": 0.22,
    },
    "input_panel.png": {
        "fill": (8, 29, 32, 222),
        "border": (70, 166, 166, 178),
        "accent": (255, 126, 32, 78),
        "glow": (70, 222, 235, 30),
        "line": (70, 222, 235, 28),
        "margin": 0.10,
    },
    "input_panel_focus.png": {
        "fill": (10, 48, 52, 232),
        "border": (82, 226, 232, 220),
        "accent": (255, 126, 32, 130),
        "glow": (70, 222, 235, 68),
        "line": (70, 222, 235, 40),
        "margin": 0.10,
    },
    "section_title_panel.png": {
        "fill": (7, 28, 31, 204),
        "border": (70, 166, 166, 154),
        "accent": (255, 126, 32, 116),
        "glow": (70, 222, 235, 28),
        "line": (70, 222, 235, 34),
        "margin": 0.20,
    },
    "tab_active.png": {
        "fill": (22, 32, 28, 222),
        "border": (222, 136, 42, 210),
        "accent": (255, 126, 32, 170),
        "glow": (255, 126, 32, 46),
        "line": (255, 156, 64, 36),
        "margin": 0.14,
    },
    "tab_idle.png": {
        "fill": (7, 25, 28, 190),
        "border": (66, 126, 128, 136),
        "accent": (255, 126, 32, 54),
        "glow": (70, 222, 235, 18),
        "line": (70, 222, 235, 20),
        "margin": 0.14,
    },
}

MENU_CROPS: dict[str, tuple[int, int, int, int]] = {
    "backdrop_panel": (1170, 119, 1514, 520),
    "backdrop_card": (22, 121, 416, 294),
    "backdrop_bar": (20, 922, 930, 997),
    "divider": (20, 111, 358, 121),
}

OBSOLETE_MENU_ASSETS = [
    "main_menu_backdrop.png",
    "main_menu_option_row.png",
    "main_menu_panel.png",
    "main_menu_start_button.png",
    "main_menu_texture_sheet.png",
]


def load_generated_sheet() -> Image.Image:
    if not SOURCE_SHEET_ALPHA.exists():
        raise FileNotFoundError(
            f"Missing generated transparent UI source sheet: {SOURCE_SHEET_ALPHA}"
        )
    return Image.open(SOURCE_SHEET_ALPHA).convert("RGBA")


def _scale_alpha(image: Image.Image, alpha_scale: float) -> Image.Image:
    if alpha_scale >= 0.999:
        return image
    output = image.copy()
    alpha = output.getchannel("A").point(lambda value: int(value * alpha_scale))
    output.putalpha(alpha)
    return output


def _apply_tint(image: Image.Image, color: tuple[int, int, int], amount: float) -> Image.Image:
    if amount <= 0.0:
        return image
    tint = Image.new("RGBA", image.size, (*color, 0))
    tint.putalpha(image.getchannel("A").point(lambda value: int(value * amount)))
    return Image.alpha_composite(image, tint)


def apply_state_tuning(image: Image.Image, name: str) -> Image.Image:
    tuning = STATE_TUNING.get(name, {})
    output = image
    if "brightness" in tuning:
        output = ImageEnhance.Brightness(output).enhance(tuning["brightness"])
    if "contrast" in tuning:
        output = ImageEnhance.Contrast(output).enhance(tuning["contrast"])
    output = _apply_tint(output, (70, 222, 235), tuning.get("cyan", 0.0))
    output = _apply_tint(output, (255, 126, 32), tuning.get("amber", 0.0))
    output = _scale_alpha(output, tuning.get("alpha", 0.92))
    return output


def generate_button_texture(name: str) -> Image.Image:
    width, height = TARGET_SIZES[name]
    scale = 4
    canvas = Image.new("RGBA", (width * scale, height * scale), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas, "RGBA")
    state = BUTTON_STATES[name]

    def pt(x: int, y: int) -> tuple[int, int]:
        return (x * scale, y * scale)

    outer = [
        pt(11, 2),
        pt(width - 10, 2),
        pt(width - 3, 11),
        pt(width - 3, height - 12),
        pt(width - 12, height - 3),
        pt(9, height - 3),
        pt(3, height - 11),
        pt(3, 12),
    ]
    inner = [
        pt(16, 8),
        pt(width - 17, 8),
        pt(width - 9, 16),
        pt(width - 9, height - 17),
        pt(width - 18, height - 9),
        pt(17, height - 9),
        pt(9, height - 17),
        pt(9, 17),
    ]

    draw.polygon(outer, fill=state["glow"])
    draw.polygon(inner, fill=state["fill"])
    draw.line(outer + [outer[0]], fill=state["border"], width=2 * scale, joint="curve")
    draw.line(inner + [inner[0]], fill=(18, 58, 60, 190), width=1 * scale, joint="curve")

    draw.line([pt(24, 9), pt(width - 54, 9)], fill=(140, 236, 236, 70), width=1 * scale)
    draw.line([pt(28, height - 10), pt(width - 26, height - 10)], fill=(72, 218, 230, 48), width=1 * scale)
    draw.line([pt(width - 54, 8), pt(width - 33, 8), pt(width - 25, 16)], fill=state["accent"], width=1 * scale)
    draw.line([pt(10, height - 21), pt(10, height - 13), pt(18, height - 8)], fill=state["accent"], width=1 * scale)

    return canvas.resize((width, height), Image.Resampling.LANCZOS)


def generate_frame_texture(name: str) -> Image.Image:
    width, height = TARGET_SIZES[name]
    scale = 4
    canvas = Image.new("RGBA", (width * scale, height * scale), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas, "RGBA")
    state = FRAME_STATES[name]
    cut = max(8, int(min(width, height) * float(state["margin"])))

    def pt(x: int, y: int) -> tuple[int, int]:
        return (x * scale, y * scale)

    outer = [
        pt(cut, 2),
        pt(width - cut, 2),
        pt(width - 3, cut),
        pt(width - 3, height - cut),
        pt(width - cut, height - 3),
        pt(cut, height - 3),
        pt(3, height - cut),
        pt(3, cut),
    ]
    inner_inset = max(6, cut // 2)
    inner = [
        pt(cut + inner_inset, 8),
        pt(width - cut - inner_inset, 8),
        pt(width - 9, cut + inner_inset),
        pt(width - 9, height - cut - inner_inset),
        pt(width - cut - inner_inset, height - 9),
        pt(cut + inner_inset, height - 9),
        pt(9, height - cut - inner_inset),
        pt(9, cut + inner_inset),
    ]

    draw.polygon(outer, fill=state["glow"])
    draw.polygon(inner, fill=state["fill"])
    draw.line(outer + [outer[0]], fill=state["border"], width=max(1, int(1.5 * scale)), joint="curve")
    draw.line(inner + [inner[0]], fill=state["line"], width=scale, joint="curve")

    top_y = max(7, int(height * 0.10))
    bottom_y = min(height - 8, int(height * 0.88))
    left_x = max(12, cut + 6)
    right_x = min(width - 12, width - cut - 6)
    draw.line([pt(left_x, top_y), pt(int(width * 0.74), top_y)], fill=state["line"], width=scale)
    draw.line([pt(int(width * 0.20), bottom_y), pt(right_x, bottom_y)], fill=state["line"], width=scale)
    draw.line(
        [pt(int(width * 0.72), top_y), pt(int(width * 0.84), top_y), pt(int(width * 0.89), top_y + max(6, cut // 2))],
        fill=state["accent"],
        width=scale,
    )
    draw.line(
        [pt(9, height - cut - 3), pt(9, height - 10), pt(cut + 2, height - 4)],
        fill=state["accent"],
        width=scale,
    )

    return canvas.resize((width, height), Image.Resampling.LANCZOS)


def extract_component(
    source: Image.Image,
    name: str,
    target_size: tuple[int, int] | None = None,
) -> Image.Image:
    crop_box = SOURCE_CROPS[name]
    size = target_size if target_size is not None else TARGET_SIZES[name]
    component = source.crop(crop_box).resize(size, Image.Resampling.LANCZOS)
    return apply_state_tuning(component, name)


def write_bridge_textures() -> None:
    BRIDGE_ASSET_DIR.mkdir(parents=True, exist_ok=True)
    source = load_generated_sheet()
    for name, size in TARGET_SIZES.items():
        if name.startswith("button_"):
            generate_button_texture(name).save(BRIDGE_ASSET_DIR / name)
        elif name in FRAME_STATES:
            generate_frame_texture(name).save(BRIDGE_ASSET_DIR / name)
        else:
            extract_component(source, name, size).save(BRIDGE_ASSET_DIR / name)


def write_menu_textures() -> None:
    MENU_ASSET_DIR.mkdir(parents=True, exist_ok=True)
    source = load_generated_sheet()

    divider = source.crop(MENU_CROPS["divider"]).resize((1024, 32), Image.Resampling.LANCZOS)
    divider = apply_state_tuning(divider.filter(ImageFilter.GaussianBlur(0.15)), "section_title_panel.png")
    divider.save(MENU_ASSET_DIR / "main_menu_divider.png")

    for name in OBSOLETE_MENU_ASSETS:
        for path in (MENU_ASSET_DIR / name, MENU_ASSET_DIR / f"{name}.import"):
            if path.exists():
                path.unlink()


def main() -> None:
    write_bridge_textures()
    write_menu_textures()
    print(f"Wrote generated transparent UI textures from {SOURCE_SHEET_ALPHA}")


if __name__ == "__main__":
    main()
