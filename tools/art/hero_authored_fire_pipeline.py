#!/usr/bin/env python3
"""Production extraction for authored hero FIRE poses.

The source action sheet stores three authored firing poses for each of eight
hero directions. This module isolates those poses from presentation labels and
other detached sheet chrome, then normalizes them onto the shared 320x320
runtime canvas used by the rest of the hero pipeline.
"""

from __future__ import annotations

import shutil
from pathlib import Path
from typing import Sequence

import numpy as np
from PIL import Image


DEFAULT_DIRECTIONS = [
    "front",
    "front_right",
    "right",
    "back_right",
    "back",
    "back_left",
    "left",
    "front_left",
]


def _component_boxes(alpha: np.ndarray, min_area: int = 24):
    mask = alpha > 18
    height, width = mask.shape
    labels = np.zeros((height, width), dtype=np.int32)
    components = []
    component_id = 0

    for y in range(height):
        for x in range(width):
            if not mask[y, x] or labels[y, x] != 0:
                continue
            component_id += 1
            stack = [(x, y)]
            labels[y, x] = component_id
            area = 0
            x0 = x1 = x
            y0 = y1 = y
            while stack:
                px, py = stack.pop()
                area += 1
                x0 = min(x0, px)
                x1 = max(x1, px)
                y0 = min(y0, py)
                y1 = max(y1, py)
                for nx, ny in ((px - 1, py), (px + 1, py), (px, py - 1), (px, py + 1)):
                    if 0 <= nx < width and 0 <= ny < height and mask[ny, nx] and labels[ny, nx] == 0:
                        labels[ny, nx] = component_id
                        stack.append((nx, ny))
            if area >= min_area:
                components.append((area, component_id, x0, y0, x1 - x0 + 1, y1 - y0 + 1))

    components.sort(reverse=True)
    return labels, components


def _bbox_gap(a, b):
    _, _, ax, ay, aw, ah = a
    _, _, bx, by, bw, bh = b
    ar, ab = ax + aw, ay + ah
    br, bb = bx + bw, by + bh
    return max(0, bx - ar, ax - br), max(0, by - ab, ay - bb)


def _is_presentation_label(main, component) -> bool:
    _main_area, _main_id, _mx, my, _mw, mh = main
    _area, _component_id, _x, y, w, h = component
    shallow_and_wide = h <= max(10, int(mh * 0.16)) and w >= max(24, int(h * 2.8))
    below_body_center = y >= my + int(mh * 0.58)
    return shallow_and_wide and below_body_center


def _extract_pose(cell: Image.Image):
    rgba = cell.convert("RGBA")
    pixels = np.array(rgba)
    labels, components = _component_boxes(pixels[:, :, 3])
    if not components:
        raise ValueError("FIRE cell contains no foreground pose")

    main = components[0]
    main_area, main_id, _mx, _my, main_w, main_h = main
    keep = {main_id}
    for component in components[1:]:
        area, component_id, _x, _y, _w, _h = component
        if area < max(18, int(main_area * 0.006)):
            continue
        if _is_presentation_label(main, component):
            continue
        dx, dy = _bbox_gap(main, component)
        # Keep nearby detached weapon / hose pieces. Presentation chrome and
        # neighboring-cell debris should sit farther away than this envelope.
        if dx <= max(96, int(main_w * 1.25)) and dy <= max(48, int(main_h * 0.34)):
            keep.add(component_id)

    alpha = np.zeros(pixels.shape[:2], dtype=np.uint8)
    for component_id in keep:
        mask = labels == component_id
        alpha[mask] = pixels[:, :, 3][mask]
    pixels[:, :, 3] = alpha

    ys, xs = np.nonzero(alpha > 0)
    if len(xs) == 0:
        raise ValueError("FIRE pose became empty after cleanup")

    x0, x1 = int(xs.min()), int(xs.max()) + 1
    y0, y1 = int(ys.min()), int(ys.max()) + 1
    crop = Image.fromarray(pixels[y0:y1, x0:x1], "RGBA")
    _, _, mx, my, mw, mh = main
    main_relative = (mx - x0, my - y0, mw, mh)
    return crop, main_relative


def _normalize_pose(
    crop: Image.Image,
    main_relative,
    canvas_size: int,
    ground_y: int,
    target_main_height: int = 244,
) -> Image.Image:
    mx, my, mw, mh = main_relative
    safe_margin = 8
    max_extent = canvas_size - safe_margin * 2
    scale = target_main_height / max(1, mh)
    scale = min(scale, max_extent / max(1, crop.width), max_extent / max(1, crop.height))

    width = max(1, round(crop.width * scale))
    height = max(1, round(crop.height * scale))
    resized = crop.resize((width, height), Image.Resampling.LANCZOS)

    main_center_x = (mx + mw / 2.0) * scale
    main_bottom = (my + mh) * scale
    left = round(canvas_size / 2.0 - main_center_x)
    top = round(ground_y - main_bottom)

    max_left = canvas_size - safe_margin - width
    max_top = canvas_size - safe_margin - height
    left = min(max(left, safe_margin), max_left)
    top = min(max(top, safe_margin), max_top)

    canvas = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    canvas.alpha_composite(resized, (left, top))
    return canvas


def build_authored_fire_frames(
    source_path: Path | str,
    output_dir: Path | str,
    directions: Sequence[str] = DEFAULT_DIRECTIONS,
    row_bands: Sequence[tuple[int, int]] = ((72, 220), (220, 375), (375, 530)),
    canvas_size: int = 320,
    ground_y: int = 306,
) -> list[Path]:
    """Extract three authored FIRE frames for every direction.

    ``row_bands`` intentionally remains explicit: the full action sheet also
    contains build/hurt/death art below the firing poses, so auto-detecting all
    horizontal bands would be less safe than validating the known authored
    firing region and performing resilient component cleanup inside each cell.
    """

    if len(directions) != 8:
        raise ValueError(f"Authored FIRE expects 8 directions, got {len(directions)}")
    if len(row_bands) != 3:
        raise ValueError(f"Authored FIRE expects 3 action rows, got {len(row_bands)}")
    if not 0 < int(ground_y) < int(canvas_size):
        raise ValueError(f"Invalid FIRE ground anchor: {ground_y}")

    destination = Path(output_dir)
    if destination.exists():
        shutil.rmtree(destination)
    destination.mkdir(parents=True, exist_ok=True)

    with Image.open(source_path) as source_file:
        source = source_file.convert("RGBA")
    source_width, source_height = source.size
    cell_width = source_width / 8.0

    built: list[Path] = []
    for frame_index, raw_band in enumerate(row_bands):
        y0, y1 = map(int, raw_band)
        if not (0 <= y0 < y1 <= source_height):
            raise ValueError(f"Invalid FIRE row band {raw_band} for source height {source_height}")
        for column, direction in enumerate(directions):
            x0 = round(column * cell_width)
            x1 = round((column + 1) * cell_width)
            cell = source.crop((x0, y0, x1, y1))
            crop, main_relative = _extract_pose(cell)
            frame = _normalize_pose(
                crop,
                main_relative,
                canvas_size=int(canvas_size),
                ground_y=int(ground_y),
            )
            output_path = destination / f"fire_{direction}_{frame_index:02d}.png"
            frame.save(output_path)
            built.append(output_path)

    return built
