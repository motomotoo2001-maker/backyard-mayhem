#!/usr/bin/env python3
"""Ground-normalizing wrapper for projection-based authored RUN recovery."""

from __future__ import annotations

import importlib.util
import sys
from pathlib import Path
from typing import Sequence

from PIL import Image, ImageDraw


BASE_PATH = Path(__file__).with_name("hero_authored_run_recovery.py")
CLEANUP_PATH = Path(__file__).with_name("hero_candidate_cleanup.py")


def _load_base():
    spec = importlib.util.spec_from_file_location("hero_authored_run_recovery_base", BASE_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Cannot load recovery base from {BASE_PATH}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _load_cleanup():
    module_name = "hero_candidate_cleanup_for_run_recovery"
    spec = importlib.util.spec_from_file_location(module_name, CLEANUP_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Cannot load hero cleanup from {CLEANUP_PATH}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[module_name] = module
    try:
        spec.loader.exec_module(module)
    except Exception:
        sys.modules.pop(module_name, None)
        raise
    return module


def _alpha_bbox(image: Image.Image):
    return image.getchannel("A").point(lambda value: 255 if value > 16 else 0).getbbox()


def _longest_run(alpha, y: int, left: int, right: int) -> int:
    best = 0
    current = 0
    for x in range(left, right):
        if alpha[x, y] > 16:
            current += 1
            best = max(best, current)
        else:
            current = 0
    return best


def _strip_wide_bottom_slab(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    bbox = _alpha_bbox(rgba)
    if bbox is None:
        return rgba
    left, top, right, bottom = bbox
    width = right - left
    height = bottom - top
    if width < 12 or height < 20:
        return rgba

    alpha = rgba.getchannel("A").load()
    wide_threshold = max(8, int(width * 0.55))
    slab_rows = []
    y = bottom - 1
    while y >= top and _longest_run(alpha, y, left, right) >= wide_threshold:
        slab_rows.append(y)
        y -= 1
    if len(slab_rows) < 2:
        return rgba
    slab_start = min(slab_rows)
    slab_height = bottom - slab_start
    if slab_height > max(10, int(height * 0.22)):
        return rgba

    cleaned = rgba.copy()
    pixels = cleaned.load()
    for yy in range(slab_start, bottom):
        for xx in range(left, right):
            pixels[xx, yy] = (0, 0, 0, 0)
    return cleaned


def _strip_connected_lower_chrome(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    bbox = _alpha_bbox(rgba)
    if bbox is None:
        return rgba
    left, top, right, bottom = bbox
    height = bottom - top
    if height < 20:
        return rgba

    alpha = rgba.getchannel("A").load()
    row_counts = [sum(1 for x in range(left, right) if alpha[x, y] > 16) for y in range(top, bottom)]
    maximum = max(row_counts) if row_counts else 0
    if maximum <= 0:
        return rgba

    narrow_threshold = max(4, int(maximum * 0.28))
    search_start = max(1, int(height * 0.48))
    candidate_cut = None
    index = search_start
    while index < height - 2:
        if row_counts[index] > narrow_threshold:
            index += 1
            continue
        start = index
        while index < height and row_counts[index] <= narrow_threshold:
            index += 1
        end = index
        if end - start < 2 or end >= height:
            continue
        above_mass = sum(row_counts[:start])
        below_mass = sum(row_counts[end:])
        below_peak = max(row_counts[end:], default=0)
        if above_mass > 0 and 0 < below_mass <= above_mass * 0.40 and below_peak >= narrow_threshold * 1.35:
            candidate_cut = start
            break

    if candidate_cut is None:
        return rgba

    cut_y = top + candidate_cut
    cleaned = rgba.copy()
    pixels = cleaned.load()
    for y in range(cut_y, bottom):
        for x in range(left, right):
            pixels[x, y] = (0, 0, 0, 0)
    return cleaned


def _normalize_ground(path: Path, canvas_size: int, ground_y: int) -> None:
    with Image.open(path) as source:
        image = source.convert("RGBA")

    image = _strip_wide_bottom_slab(image)
    image = _strip_connected_lower_chrome(image)

    cleanup = _load_cleanup()
    cleaned, stats = cleanup.clean_frame(image, ground_y=int(ground_y), safe_margin=8)
    if stats["removed_pixels"] or stats["shift_y"]:
        print(
            f"Recovered RUN cleanup {path.name}: "
            f"removed={stats['removed_pixels']}px shift_y={stats['shift_y']:+d} "
            f"body_bottom={stats['body_bottom']}"
        )

    normalized_bbox = _alpha_bbox(cleaned)
    if normalized_bbox is None or normalized_bbox[3] != int(ground_y) + 1:
        raise ValueError(
            f"Could not normalize {path.name} to ground pixel {ground_y}; bbox={normalized_bbox}"
        )
    if normalized_bbox[1] < 6:
        raise ValueError(f"Ground normalization clips top margin in {path.name}: {normalized_bbox[1]}")
    cleaned.save(path)


def _write_contact_sheet(paths: Sequence[Path], destination: Path, directions: Sequence[str]) -> None:
    tile = 160
    sheet = Image.new("RGBA", (8 * tile, 8 * tile), (28, 31, 34, 255))
    draw = ImageDraw.Draw(sheet)
    by_name = {path.name: path for path in paths}
    for row, direction in enumerate(directions):
        for column in range(8):
            name = f"run_{direction}_{column:02d}.png"
            path = by_name[name]
            with Image.open(path) as source:
                frame = source.convert("RGBA")
            sheet.alpha_composite(frame.resize((tile, tile), Image.Resampling.LANCZOS), (column * tile, row * tile))
            draw.text((column * tile + 4, row * tile + 4), f"{row + 1}:{column + 1}", fill=(245, 245, 245, 255))
    destination.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(destination)


def build_recovered_run_frames(
    source_path: Path | str,
    output_dir: Path | str,
    directions: Sequence[str],
    canvas_size: int = 320,
    ground_y: int = 306,
    contact_sheet_path: Path | str | None = None,
) -> list[Path]:
    base = _load_base()
    built = base.build_recovered_run_frames(
        source_path,
        output_dir,
        directions=directions,
        canvas_size=canvas_size,
        ground_y=ground_y,
        contact_sheet_path=None,
    )
    for path in built:
        _normalize_ground(Path(path), canvas_size, ground_y)
    if contact_sheet_path is not None:
        _write_contact_sheet([Path(path) for path in built], Path(contact_sheet_path), directions)
    return [Path(path) for path in built]
