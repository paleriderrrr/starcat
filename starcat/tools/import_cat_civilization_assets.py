from __future__ import annotations

import argparse
import os
from pathlib import Path
from typing import Iterable

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
DEST_ROOT = ROOT / "assets" / "factions" / "cats"

NAMES = [
    "russian_blue_command",
    "ragdoll_diplomatic",
    "bengal_tactical",
    "maine_coon_imperial",
    "black_cat_stealth",
    "orange_tabby_industrial",
]

OUTPUT_SPECS = {
    "portraits": (256, 256),
    "ships": (320, 180),
    "emblems": (192, 192),
}


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Import cat civilization source sheet into Starcat faction assets.")
    parser.add_argument(
        "--source-image",
        type=Path,
        default=None,
        help="Path to the generated 3x6 cat civilization sprite sheet. Falls back to STARCAT_CAT_SOURCE_IMAGE or assets/factions/cats/source/*.png.",
    )
    return parser.parse_args()


def _resolve_source_image(source_image: Path | None) -> Path:
    if source_image is not None:
        return source_image.expanduser().resolve()
    env_value = os.environ.get("STARCAT_CAT_SOURCE_IMAGE", "").strip()
    if env_value:
        return Path(env_value).expanduser().resolve()
    source_dir = DEST_ROOT / "source"
    candidates = sorted(source_dir.glob("*.png")) if source_dir.exists() else []
    if candidates:
        return candidates[0].resolve()
    raise FileNotFoundError(
        "Source image not provided. Pass --source-image, set STARCAT_CAT_SOURCE_IMAGE, "
        "or place a PNG sheet under assets/factions/cats/source/."
    )


def _ensure_dirs() -> None:
    for folder in OUTPUT_SPECS:
        (DEST_ROOT / folder).mkdir(parents=True, exist_ok=True)
    (DEST_ROOT / "source").mkdir(parents=True, exist_ok=True)


def _soft_remove_background(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    width, height = rgba.size
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            low = min(r, g, b)
            high = max(r, g, b)
            if low >= 250:
                pixels[x, y] = (r, g, b, 0)
            elif low >= 235 and high - low <= 18:
                alpha = int(max(0, min(255, (250 - low) * 17)))
                pixels[x, y] = (r, g, b, alpha)
            else:
                pixels[x, y] = (r, g, b, a)
    return rgba


def _fit_on_canvas(image: Image.Image, size: tuple[int, int], padding: int) -> Image.Image:
    canvas = Image.new("RGBA", size, (0, 0, 0, 0))
    inner_width = max(1, size[0] - padding * 2)
    inner_height = max(1, size[1] - padding * 2)
    fitted = image.copy()
    fitted.thumbnail((inner_width, inner_height), Image.Resampling.LANCZOS)
    offset_x = (size[0] - fitted.width) // 2
    offset_y = (size[1] - fitted.height) // 2
    canvas.alpha_composite(fitted, (offset_x, offset_y))
    return canvas


def _largest_component_bounds(image: Image.Image, alpha_threshold: int = 24) -> tuple[int, int, int, int] | None:
    rgba = image.convert("RGBA")
    width, height = rgba.size
    pixels = rgba.load()
    visited: set[tuple[int, int]] = set()
    best_bounds: tuple[int, int, int, int] | None = None
    best_area = 0
    for y in range(height):
        for x in range(width):
            if (x, y) in visited:
                continue
            if pixels[x, y][3] <= alpha_threshold:
                visited.add((x, y))
                continue
            stack = [(x, y)]
            visited.add((x, y))
            min_x = max_x = x
            min_y = max_y = y
            count = 0
            while stack:
                current_x, current_y = stack.pop()
                count += 1
                min_x = min(min_x, current_x)
                min_y = min(min_y, current_y)
                max_x = max(max_x, current_x)
                max_y = max(max_y, current_y)
                for next_x, next_y in (
                    (current_x + 1, current_y),
                    (current_x - 1, current_y),
                    (current_x, current_y + 1),
                    (current_x, current_y - 1),
                ):
                    if next_x < 0 or next_y < 0 or next_x >= width or next_y >= height:
                        continue
                    if (next_x, next_y) in visited:
                        continue
                    visited.add((next_x, next_y))
                    if pixels[next_x, next_y][3] > alpha_threshold:
                        stack.append((next_x, next_y))
            if count > best_area:
                best_area = count
                best_bounds = (min_x, min_y, max_x + 1, max_y + 1)
    return best_bounds


def _crop_cells(sheet: Image.Image) -> Iterable[Image.Image]:
    columns = 3
    rows = 6
    cell_width = sheet.width / columns
    cell_height = sheet.height / rows
    for row in range(rows):
        for column in range(columns):
            left = int(round(column * cell_width))
            top = int(round(row * cell_height))
            right = int(round((column + 1) * cell_width))
            bottom = int(round((row + 1) * cell_height))
            yield sheet.crop((left, top, right, bottom))


def main() -> None:
    args = _parse_args()
    source_image = _resolve_source_image(args.source_image)
    if not source_image.exists():
        raise FileNotFoundError(f"Source image not found: {source_image}")

    _ensure_dirs()
    source_copy = DEST_ROOT / "source" / source_image.name
    source_copy.write_bytes(source_image.read_bytes())

    sheet = Image.open(source_image).convert("RGBA")
    cells = list(_crop_cells(sheet))
    portrait_cells = cells[0:3] + cells[9:12]
    ship_cells = cells[3:6] + cells[12:15]
    emblem_cells = cells[6:9] + cells[15:18]

    groups = {
        "portraits": portrait_cells,
        "ships": ship_cells,
        "emblems": emblem_cells,
    }

    for group_name, images in groups.items():
        target_size = OUTPUT_SPECS[group_name]
        for name, cell in zip(NAMES, images, strict=True):
            if group_name == "emblems":
                cell = cell.crop((0, int(cell.height * 0.14), cell.width, cell.height))
            cleaned = _soft_remove_background(cell)
            bounds = _largest_component_bounds(cleaned) or cleaned.getbbox()
            if bounds:
                cleaned = cleaned.crop(bounds)
            padding = 12 if group_name == "emblems" else 16 if group_name == "portraits" else 20
            final_image = _fit_on_canvas(cleaned, target_size, padding)
            final_image.save(DEST_ROOT / group_name / f"{name}.png")


if __name__ == "__main__":
    main()
