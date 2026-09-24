#!/usr/bin/env python3
"""Extract authored 8-direction RUN frames from a labeled reference sheet.

The source sheet is an art/reference input only. Runtime output is always
transparent 320x320 PNG frames with one shared scale and bottom-center anchor.

The important constraint is that rows are *detected* from character components;
the source is intentionally not sliced into eight equal-height strips. That
prevents RUN labels and pieces of neighboring rows from leaking into runtime.
"""

from __future__ import annotations

import argparse
from collections import deque
from pathlib import Path
from typing import Iterable, NamedTuple, Sequence

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


def _is_background(pixel: tuple[int, int, int, int]) -> bool:
    r, g, b, a = pixel
    if a <= 8:
        return True
    if r >= 242 and g >= 242 and b >= 242:
        return True
    # Reference sheets often contain pale gray guide/grid lines. Treat only
    # bright near-neutral gray as matte; dark labels remain foreground and are
    # rejected later by component geometry.
    if max(r, g, b) - min(r, g, b) <= 8 and (r + g + b) / 3.0 >= 190:
        return True
    return False


def _foreground_mask(image: Image.Image) -> bytearray:
    rgba = image.convert("RGBA")
    mask = bytearray(rgba.width * rgba.height)
    for index, pixel in enumerate(rgba.getdata()):
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
                row = ny * width
                for nx in range(max(0, x - 1), min(width, x + 2)):
                    neighbor = row + nx
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
    if fill < 0.08:
        return False
    return True


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

    row_pairs = sorted(zip(centers, groups), key=lambda item: item[0])
    return [group for _center, group in row_pairs]


def _vertical_overlap(a: Component, b: Component) -> int:
    return max(0, min(a.bbox[3], b.bbox[3]) - max(a.bbox[1], b.bbox[1]))


def _merge_related_bbox(
    primary: Component,
    components: Sequence[Component],
    cell_left: float,
    cell_right: float,
) -> tuple[int, int, int, int]:
    related = [primary]
    expanded_left = cell_left - (cell_right - cell_left) * 0.08
    expanded_right = cell_right + (cell_right - cell_left) * 0.08

    for component in components:
        if component == primary:
            continue
        if not (expanded_left <= component.center_x <= expanded_right):
            continue
        # Authored accessories/weapons can be disconnected, but must share a
        # meaningful vertical span with the main body. This intentionally rejects
        # RUN labels below the feet and fragments from adjacent rows.
        overlap = _vertical_overlap(primary, component)
        if overlap <= 0:
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
    """Return one detected character bbox for each row/column frame cell.

    Y positions are discovered from connected character components. X columns
    remain layout slots because the authored sheet uses a regular frame order.
    """

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
        row_all = [
            component
            for component in raw_components
            if abs(component.center_y - sum(c.center_y for c in row_components) / len(row_components))
            <= max(c.height for c in row_components) * 0.8
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
            bbox = _merge_related_bbox(primary, row_all, left, right)
            cells.append(RunCell(row_index, column, bbox))

    if len(cells) != rows * columns:
        raise ValueError(f"Expected {rows * columns} run cells, detected {len(cells)}")
    return cells


def _transparent_crop(
    image: Image.Image,
    bbox: tuple[int, int, int, int],
    padding: int = 2,
) -> Image.Image:
    left, top, right, bottom = bbox
    left = max(0, left - padding)
    top = max(0, top - padding)
    right = min(image.width, right + padding)
    bottom = min(image.height, bottom + padding)
    crop = image.convert("RGBA").crop((left, top, right, bottom))

    cleaned: list[tuple[int, int, int, int]] = []
    for pixel in crop.getdata():
        if _is_background(pixel):
            cleaned.append((pixel[0], pixel[1], pixel[2], 0))
        else:
            cleaned.append(pixel)
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
    target_width = canvas_size * 0.72
    target_height = max(1, ground_y - 20)
    return min(target_width / max_width, target_height / max_height)


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
        frame = Image.open(frame_path).convert("RGBA")
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

    source = Image.open(source_path).convert("RGBA")
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
