#!/usr/bin/env python3
"""Extract authored 8-direction RUN frames from a labeled reference sheet.

The source sheet is reference-only. Runtime output is transparent 320x320 PNG
with one shared scale and a fixed bottom-center anchor. Rows are discovered from
character components instead of slicing the sheet into eight equal-height bands.
"""

from __future__ import annotations

import argparse
from collections import deque
from pathlib import Path
from typing import NamedTuple, Sequence

from PIL import Image, ImageDraw


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


class Component(NamedTuple):
    bbox: tuple[int, int, int, int]
    pixels: int

    @property
    def width(self) -> int:
        return self.bbox[2] - self.bbox[0]

    @property
    def height(self) -> int:
        return self.bbox[3] - self.bbox[1]

    @property
    def center_x(self) -> float:
        return (self.bbox[0] + self.bbox[2]) * 0.5

    @property
    def center_y(self) -> float:
        return (self.bbox[1] + self.bbox[3]) * 0.5


class RunCell(NamedTuple):
    row: int
    column: int
    bbox: tuple[int, int, int, int]


def _pixel_data(image: Image.Image):
    getter = getattr(image, "get_flattened_data", None)
    return getter() if getter is not None else image.getdata()


def _is_background(pixel: tuple[int, int, int, int]) -> bool:
    r, g, b, a = pixel
    if a <= 8:
        return True
    if r >= 242 and g >= 242 and b >= 242:
        return True
    if max(r, g, b) - min(r, g, b) <= 8 and (r + g + b) / 3.0 >= 190:
        return True
    return False


def _foreground_mask(image: Image.Image) -> bytearray:
    rgba = image.convert("RGBA")
    mask = bytearray(rgba.width * rgba.height)
    for index, pixel in enumerate(_pixel_data(rgba)):
        if not _is_background(pixel):
            mask[index] = 1
    return mask


def _connected_components(image: Image.Image) -> list[Component]:
    width, height = image.size
    foreground = _foreground_mask(image)
    visited = bytearray(width * height)
    result: list[Component] = []

    for start in range(width * height):
        if not foreground[start] or visited[start]:
            continue

        queue: deque[int] = deque([start])
        visited[start] = 1
        min_x = max_x = start % width
        min_y = max_y = start // width
        count = 0

        while queue:
            index = queue.popleft()
            x = index % width
            y = index // width
            count += 1
            min_x = min(min_x, x)
            max_x = max(max_x, x)
            min_y = min(min_y, y)
            max_y = max(max_y, y)

            for ny in range(max(0, y - 1), min(height, y + 2)):
                row_start = ny * width
                for nx in range(max(0, x - 1), min(width, x + 2)):
                    neighbor = row_start + nx
                    if foreground[neighbor] and not visited[neighbor]:
                        visited[neighbor] = 1
                        queue.append(neighbor)

        result.append(Component((min_x, min_y, max_x + 1, max_y + 1), count))

    return result


def _is_character_candidate(
    component: Component,
    image_size: tuple[int, int],
    rows: int,
    columns: int,
) -> bool:
    width, height = image_size
    min_height = max(16, height // max(1, rows * 5))
    min_width = max(6, width // max(1, columns * 30))
    min_pixels = max(60, (width * height) // 24000)

    if component.height < min_height or component.width < min_width:
        return False
    if component.pixels < min_pixels:
        return False

    aspect = component.width / max(1.0, float(component.height))
    if aspect < 0.18 or aspect > 1.8:
        return False

    fill = component.pixels / max(1.0, float(component.width * component.height))
    return fill >= 0.08


def _cluster_rows(components: Sequence[Component], row_count: int) -> list[list[Component]]:
    if len(components) < row_count:
        raise ValueError(
            f"Need at least {row_count} character components, found {len(components)}"
        )

    ordered = sorted(components, key=lambda component: component.center_y)
    count = len(ordered)
    centers = [
        ordered[min(count - 1, int((row + 0.5) * count / row_count))].center_y
        for row in range(row_count)
    ]

    groups: list[list[Component]] = []
    for _iteration in range(32):
        groups = [[] for _ in range(row_count)]
        for component in ordered:
            nearest = min(
                range(row_count),
                key=lambda index: abs(component.center_y - centers[index]),
            )
            groups[nearest].append(component)

        if any(not group for group in groups):
            raise ValueError("Could not discover all authored character rows")

        updated = [
            sum(component.center_y for component in group) / len(group)
            for group in groups
        ]
        if max(abs(a - b) for a, b in zip(centers, updated)) < 0.05:
            centers = updated
            break
        centers = updated

    return [
        group
        for _center, group in sorted(zip(centers, groups), key=lambda item: item[0])
    ]


def _vertical_overlap(a: Component, b: Component) -> int:
    return max(0, min(a.bbox[3], b.bbox[3]) - max(a.bbox[1], b.bbox[1]))


def _merge_related_bbox(
    primary: Component,
    components: Sequence[Component],
    cell_left: float,
    cell_right: float,
) -> tuple[int, int, int, int]:
    related = [primary]
    slot_width = cell_right - cell_left
    expanded_left = cell_left - slot_width * 0.08
    expanded_right = cell_right + slot_width * 0.08

    for component in components:
        if component == primary:
            continue
        if not (expanded_left <= component.center_x <= expanded_right):
            continue

        # Detached authored accessories may be merged only when they share a
        # meaningful vertical span with the body. A few touching pixels are not
        # enough: this is what prevents labels/legs from adjacent bands leaking in.
        overlap = _vertical_overlap(primary, component)
        required_overlap = max(3, int(min(primary.height, component.height) * 0.30))
        if overlap < required_overlap:
            continue
        if component.pixels < max(4, int(primary.pixels * 0.004)):
            continue
        if component.height > primary.height * 0.9 and component.width > primary.width * 0.9:
            continue
        related.append(component)

    return (
        min(component.bbox[0] for component in related),
        min(component.bbox[1] for component in related),
        max(component.bbox[2] for component in related),
        max(component.bbox[3] for component in related),
    )


def detect_authored_run_cells(
    image: Image.Image,
    rows: int = 8,
    columns: int = 8,
) -> list[RunCell]:
    rgba = image.convert("RGBA")
    raw_components = _connected_components(rgba)
    candidates = [
        component
        for component in raw_components
        if _is_character_candidate(component, rgba.size, rows, columns)
    ]
    row_groups = _cluster_rows(candidates, rows)

    cell_width = rgba.width / float(columns)
    cells: list[RunCell] = []

    for row_index, row_components in enumerate(row_groups):
        used: set[Component] = set()
        row_center = sum(component.center_y for component in row_components) / len(row_components)
        row_height = max(component.height for component in row_components)
        row_all = [
            component
            for component in raw_components
            if abs(component.center_y - row_center) <= row_height * 0.8
        ]

        for column in range(columns):
            left = column * cell_width
            right = (column + 1) * cell_width
            center_x = (left + right) * 0.5
            available = [component for component in row_components if component not in used]
            in_slot = [
                component
                for component in available
                if left <= component.center_x < right
            ]
            pool = in_slot if in_slot else available
            if not pool:
                raise ValueError(f"Missing character candidate at row {row_index}, column {column}")

            primary = max(
                pool,
                key=lambda component: (
                    component.pixels,
                    component.height,
                    -abs(component.center_x - center_x),
                ),
            )
            used.add(primary)
            cells.append(
                RunCell(
                    row_index,
                    column,
                    _merge_related_bbox(primary, row_all, left, right),
                )
            )

    if len(cells) != rows * columns:
        raise ValueError(f"Expected {rows * columns} run cells, detected {len(cells)}")
    return cells


def _transparent_crop(
    image: Image.Image,
    bbox: tuple[int, int, int, int],
    padding: int = 2,
) -> Image.Image:
    left, top, right, bottom = bbox
    crop = image.convert("RGBA").crop(
        (
            max(0, left - padding),
            max(0, top - padding),
            min(image.width, right + padding),
            min(image.height, bottom + padding),
        )
    )

    cleaned: list[tuple[int, int, int, int]] = []
    for pixel in _pixel_data(crop):
        # Zero RGB as well as alpha. Keeping white matte RGB under alpha=0 causes
        # Lanczos to bleed pale/gray fringe pixels back into resized runtime art.
        cleaned.append((0, 0, 0, 0) if _is_background(pixel) else pixel)
    crop.putdata(cleaned)

    alpha_bbox = crop.getchannel("A").getbbox()
    if alpha_bbox is None:
        raise ValueError(f"Detected run cell {bbox} became empty after matte cleanup")
    return crop.crop(alpha_bbox)


def _shared_scale(
    crops: Sequence[Image.Image],
    canvas_size: int,
    ground_y: int,
) -> float:
    max_width = max(crop.width for crop in crops)
    max_height = max(crop.height for crop in crops)
    return min((canvas_size * 0.72) / max_width, max(1, ground_y - 20) / max_height)


def _render_on_canvas(
    crop: Image.Image,
    scale: float,
    canvas_size: int,
    ground_y: int,
) -> Image.Image:
    width = max(1, round(crop.width * scale))
    height = max(1, round(crop.height * scale))
    resized = crop.resize((width, height), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    x = (canvas_size - width) // 2
    y = ground_y - height
    if y < 0:
        raise ValueError("Shared hero scale places a run frame above the runtime canvas")
    canvas.alpha_composite(resized, (x, y))
    return canvas


def _write_contact_sheet(
    frames: Sequence[tuple[int, int, Path]],
    path: Path,
    rows: int,
    columns: int,
    tile_size: int = 160,
) -> None:
    contact = Image.new(
        "RGBA",
        (columns * tile_size, rows * tile_size),
        (30, 34, 38, 255),
    )
    draw = ImageDraw.Draw(contact)
    for row, column, frame_path in frames:
        with Image.open(frame_path) as source:
            frame = source.convert("RGBA")
        thumb = frame.resize((tile_size, tile_size), Image.Resampling.LANCZOS)
        contact.alpha_composite(thumb, (column * tile_size, row * tile_size))
        draw.text(
            (column * tile_size + 4, row * tile_size + 4),
            f"{row + 1}:{column + 1}",
            fill=(245, 245, 245, 255),
        )
    path.parent.mkdir(parents=True, exist_ok=True)
    contact.save(path)


def build_authored_run_frames(
    source_path: Path | str,
    output_dir: Path | str,
    directions: Sequence[str] = DEFAULT_DIRECTIONS,
    canvas_size: int = 320,
    ground_y: int = 292,
    contact_sheet_path: Path | str | None = None,
) -> list[Path]:
    if len(directions) != 8:
        raise ValueError(f"Authored RUN sheet expects 8 directions, got {len(directions)}")
    if not 0 < ground_y <= canvas_size:
        raise ValueError("ground_y must lie inside the runtime canvas")

    with Image.open(source_path) as source_file:
        source = source_file.convert("RGBA")
    cells = detect_authored_run_cells(source, rows=8, columns=8)
    crops = [_transparent_crop(source, cell.bbox) for cell in cells]
    scale = _shared_scale(crops, canvas_size, ground_y)

    destination = Path(output_dir)
    destination.mkdir(parents=True, exist_ok=True)
    built: list[Path] = []
    contact_frames: list[tuple[int, int, Path]] = []

    for cell, crop in zip(cells, crops):
        frame = _render_on_canvas(crop, scale, canvas_size, ground_y)
        frame_path = destination / f"run_{directions[cell.row]}_{cell.column:02d}.png"
        frame.save(frame_path)
        built.append(frame_path)
        contact_frames.append((cell.row, cell.column, frame_path))

    if contact_sheet_path is not None:
        _write_contact_sheet(
            contact_frames,
            Path(contact_sheet_path),
            rows=8,
            columns=8,
        )
    return built


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path, help="8x8 authored RUN reference sheet")
    parser.add_argument("output_dir", type=Path, help="runtime frame destination")
    parser.add_argument("--contact-sheet", type=Path, default=None)
    parser.add_argument("--canvas-size", type=int, default=320)
    parser.add_argument("--ground-y", type=int, default=292)
    return parser.parse_args()


def main() -> int:
    args = _parse_args()
    built = build_authored_run_frames(
        args.source,
        args.output_dir,
        canvas_size=args.canvas_size,
        ground_y=args.ground_y,
        contact_sheet_path=args.contact_sheet,
    )
    print(f"Built {len(built)} authored RUN frames in {args.output_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
