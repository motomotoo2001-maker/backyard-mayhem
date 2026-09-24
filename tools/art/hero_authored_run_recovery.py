#!/usr/bin/env python3
"""Projection-based recovery for authored hero RUN sheets with joined row components.

Some production poses touch presentation chrome or a pose in the neighboring row,
so a whole-sheet connected-component pass can merge two characters vertically.
This fallback discovers the eight RUN columns and eight directional row bands from
foreground-density projections, then isolates one character inside each detected cell.
The bands are data-driven; the sheet is never divided into equal-height rows.
"""

from __future__ import annotations

from collections import deque
from pathlib import Path
from typing import NamedTuple, Sequence

from PIL import Image, ImageDraw


class LocalComponent(NamedTuple):
    bbox: tuple[int, int, int, int]
    pixels: tuple[int, ...]

    @property
    def width(self) -> int:
        return self.bbox[2] - self.bbox[0]

    @property
    def height(self) -> int:
        return self.bbox[3] - self.bbox[1]

    @property
    def count(self) -> int:
        return len(self.pixels)

    @property
    def center_x(self) -> float:
        return (self.bbox[0] + self.bbox[2]) * 0.5

    @property
    def center_y(self) -> float:
        return (self.bbox[1] + self.bbox[3]) * 0.5


class ExtractedPose(NamedTuple):
    image: Image.Image
    anchor_x: float
    anchor_y: float


def _pixel_data(image: Image.Image):
    getter = getattr(image, "get_flattened_data", None)
    return getter() if getter is not None else image.getdata()


def _is_background(pixel: tuple[int, int, int, int]) -> bool:
    r, g, b, a = pixel
    if a <= 8:
        return True
    if r >= 242 and g >= 242 and b >= 242:
        return True
    if max(r, g, b) <= 248 and max(r, g, b) - min(r, g, b) <= 8 and (r + g + b) / 3.0 >= 190:
        return True
    return False


def _foreground_mask(image: Image.Image) -> bytearray:
    rgba = image.convert("RGBA")
    mask = bytearray(rgba.width * rgba.height)
    for index, pixel in enumerate(_pixel_data(rgba)):
        if not _is_background(pixel):
            mask[index] = 1
    return mask


def _capped(weights: Sequence[int]) -> list[float]:
    positive = sorted(weight for weight in weights if weight > 0)
    if not positive:
        return [0.0 for _ in weights]
    percentile = positive[min(len(positive) - 1, int(len(positive) * 0.88))]
    cap = max(1.0, float(percentile) * 1.8)
    return [min(float(weight), cap) for weight in weights]


def _weighted_cluster_centers(weights: Sequence[int], cluster_count: int) -> list[float]:
    clipped = _capped(weights)
    total = sum(clipped)
    if total <= 0.0:
        raise ValueError("Foreground projection is empty")

    centers: list[float] = []
    cumulative = 0.0
    targets = [total * (index + 0.5) / cluster_count for index in range(cluster_count)]
    target_index = 0
    for position, weight in enumerate(clipped):
        cumulative += weight
        while target_index < len(targets) and cumulative >= targets[target_index]:
            centers.append(float(position))
            target_index += 1
    while len(centers) < cluster_count:
        centers.append(float(len(weights) - 1))

    for _iteration in range(48):
        sum_weight = [0.0] * cluster_count
        sum_position = [0.0] * cluster_count
        for position, weight in enumerate(clipped):
            if weight <= 0.0:
                continue
            nearest = min(range(cluster_count), key=lambda index: abs(position - centers[index]))
            sum_weight[nearest] += weight
            sum_position[nearest] += position * weight
        if any(weight <= 0.0 for weight in sum_weight):
            raise ValueError("Could not discover all projection clusters")
        updated = [sum_position[index] / sum_weight[index] for index in range(cluster_count)]
        updated.sort()
        if max(abs(a - b) for a, b in zip(centers, updated)) < 0.02:
            centers = updated
            break
        centers = updated

    for left, right in zip(centers, centers[1:]):
        if right - left < 8.0:
            raise ValueError(f"Projection clusters overlap: {centers}")
    return centers


def _discover_centers(image: Image.Image, rows: int, columns: int) -> tuple[list[float], list[float]]:
    rgba = image.convert("RGBA")
    width, height = rgba.size
    mask = _foreground_mask(rgba)
    run_left = int(width * 0.20)

    row_weights = [0] * height
    column_weights = [0] * width
    for y in range(height):
        base = y * width
        for x in range(run_left, width):
            if mask[base + x]:
                row_weights[y] += 1
                column_weights[x] += 1

    row_centers = _weighted_cluster_centers(row_weights, rows)
    column_slice = column_weights[run_left:]
    relative_columns = _weighted_cluster_centers(column_slice, columns)
    column_centers = [center + run_left for center in relative_columns]
    return row_centers, column_centers


def _axis_bounds(centers: Sequence[float], index: int, limit: int) -> tuple[int, int]:
    center = centers[index]
    if index == 0:
        half = (centers[1] - center) * 0.52
        left = center - half
    else:
        left = (centers[index - 1] + center) * 0.5
    if index + 1 == len(centers):
        half = (center - centers[index - 1]) * 0.52
        right = center + half
    else:
        right = (center + centers[index + 1]) * 0.5
    return max(0, int(left)), min(limit, int(right + 0.999))


def _components(mask: bytearray, width: int, height: int) -> list[LocalComponent]:
    visited = bytearray(width * height)
    result: list[LocalComponent] = []
    for start in range(width * height):
        if not mask[start] or visited[start]:
            continue
        queue: deque[int] = deque([start])
        visited[start] = 1
        indexes: list[int] = []
        min_x = max_x = start % width
        min_y = max_y = start // width
        while queue:
            current = queue.popleft()
            indexes.append(current)
            x = current % width
            y = current // width
            min_x = min(min_x, x)
            max_x = max(max_x, x)
            min_y = min(min_y, y)
            max_y = max(max_y, y)
            for ny in range(max(0, y - 1), min(height, y + 2)):
                base = ny * width
                for nx in range(max(0, x - 1), min(width, x + 2)):
                    neighbor = base + nx
                    if mask[neighbor] and not visited[neighbor]:
                        visited[neighbor] = 1
                        queue.append(neighbor)
        result.append(LocalComponent((min_x, min_y, max_x + 1, max_y + 1), tuple(indexes)))
    return result


def _horizontal_gap(a: LocalComponent, b: LocalComponent) -> int:
    if a.bbox[2] < b.bbox[0]:
        return b.bbox[0] - a.bbox[2]
    if b.bbox[2] < a.bbox[0]:
        return a.bbox[0] - b.bbox[2]
    return 0


def _vertical_gap(a: LocalComponent, b: LocalComponent) -> int:
    if a.bbox[3] < b.bbox[1]:
        return b.bbox[1] - a.bbox[3]
    if b.bbox[3] < a.bbox[1]:
        return a.bbox[1] - b.bbox[3]
    return 0


def _trim_boundary_bridge(component: LocalComponent, width: int, height: int) -> set[int]:
    selected = set(component.pixels)
    row_counts = [0] * height
    for index in component.pixels:
        row_counts[index // width] += 1
    maximum = max(row_counts) if row_counts else 0
    threshold = max(4, int(maximum * 0.20))
    top, bottom = component.bbox[1], component.bbox[3]

    keep_top = top
    if top <= 2:
        for y in range(top, bottom):
            if row_counts[y] >= threshold:
                keep_top = y
                break
    keep_bottom = bottom
    if bottom >= height - 2:
        for y in range(bottom - 1, keep_top - 1, -1):
            if row_counts[y] >= threshold:
                keep_bottom = y + 1
                break

    if keep_top == top and keep_bottom == bottom:
        return selected
    return {
        index
        for index in selected
        if keep_top <= index // width < keep_bottom
    }


def _extract_pose(cell: Image.Image, expected_center_x: float) -> ExtractedPose:
    rgba = cell.convert("RGBA")
    width, height = rgba.size
    mask = _foreground_mask(rgba)
    components = _components(mask, width, height)
    min_height = max(18, int(height * 0.26))
    min_pixels = max(60, int(width * height * 0.006))
    candidates = [
        component for component in components
        if component.height >= min_height
        and component.count >= min_pixels
        and 0.14 <= component.width / max(1.0, float(component.height)) <= 2.2
    ]
    if not candidates:
        raise ValueError(f"No character body found in detected RUN cell {cell.size}")

    primary = max(
        candidates,
        key=lambda component: (
            component.count
            + component.height * 35
            - abs(component.center_x - expected_center_x) * 14
        ),
    )
    primary_pixels = _trim_boundary_bridge(primary, width, height)
    if not primary_pixels:
        raise ValueError("Character body vanished while trimming a cross-row bridge")

    primary_xs = [index % width for index in primary_pixels]
    primary_ys = [index // width for index in primary_pixels]
    p_left, p_right = min(primary_xs), max(primary_xs) + 1
    p_top, p_bottom = min(primary_ys), max(primary_ys) + 1
    primary_width = p_right - p_left
    primary_height = p_bottom - p_top

    selected = set(primary_pixels)
    for component in components:
        if component is primary:
            continue
        # RUN/IDLE labels are short, wide presentation chrome below the body.
        if component.height <= max(10, int(primary_height * 0.18)) and component.width >= component.height * 1.8:
            continue
        if component.count < max(4, int(len(primary_pixels) * 0.004)):
            continue
        horizontal_gap = max(0, max(p_left - component.bbox[2], component.bbox[0] - p_right))
        vertical_gap = max(0, max(p_top - component.bbox[3], component.bbox[1] - p_bottom))
        vertical_overlap = max(0, min(p_bottom, component.bbox[3]) - max(p_top, component.bbox[1]))
        close_to_body = horizontal_gap <= max(8, int(primary_width * 0.55))
        vertically_related = vertical_overlap >= 3 or vertical_gap <= max(4, int(primary_height * 0.08))
        if close_to_body and vertically_related:
            selected.update(component.pixels)

    xs = [index % width for index in selected]
    ys = [index // width for index in selected]
    left, top, right, bottom = min(xs), min(ys), max(xs) + 1, max(ys) + 1
    crop = Image.new("RGBA", (right - left, bottom - top), (0, 0, 0, 0))
    source_pixels = rgba.load()
    destination_pixels = crop.load()
    for index in selected:
        x = index % width
        y = index // width
        if left <= x < right and top <= y < bottom:
            destination_pixels[x - left, y - top] = source_pixels[x, y]

    anchor_x = ((p_left + p_right) * 0.5) - left
    anchor_y = p_bottom - top
    return ExtractedPose(crop, anchor_x, anchor_y)


def _shared_scale(poses: Sequence[ExtractedPose], canvas_size: int, ground_y: int) -> float:
    maximum = 999.0
    side = canvas_size * 0.5 - 7.0
    for pose in poses:
        left_extent = pose.anchor_x
        right_extent = pose.image.width - pose.anchor_x
        up_extent = pose.anchor_y
        down_extent = pose.image.height - pose.anchor_y
        if left_extent > 0:
            maximum = min(maximum, side / left_extent)
        if right_extent > 0:
            maximum = min(maximum, side / right_extent)
        if up_extent > 0:
            maximum = min(maximum, max(1.0, ground_y - 10.0) / up_extent)
        if down_extent > 0:
            maximum = min(maximum, max(1.0, canvas_size - ground_y - 7.0) / down_extent)
    if maximum <= 0.0 or maximum >= 999.0:
        raise ValueError("Could not determine shared RUN scale")
    return maximum


def _render_pose(pose: ExtractedPose, scale: float, canvas_size: int, ground_y: int) -> Image.Image:
    target_w = max(1, round(pose.image.width * scale))
    target_h = max(1, round(pose.image.height * scale))
    resized = pose.image.resize((target_w, target_h), Image.Resampling.LANCZOS)
    anchor_x = pose.anchor_x * scale
    anchor_y = pose.anchor_y * scale
    x = round(canvas_size * 0.5 - anchor_x)
    y = round(ground_y - anchor_y)
    canvas = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    canvas.alpha_composite(resized, (x, y))
    return canvas


def _write_contact_sheet(paths: Sequence[tuple[int, int, Path]], destination: Path, tile_size: int = 160) -> None:
    sheet = Image.new("RGBA", (8 * tile_size, 8 * tile_size), (28, 31, 34, 255))
    draw = ImageDraw.Draw(sheet)
    for row, column, path in paths:
        with Image.open(path) as source:
            frame = source.convert("RGBA")
        thumb = frame.resize((tile_size, tile_size), Image.Resampling.LANCZOS)
        sheet.alpha_composite(thumb, (column * tile_size, row * tile_size))
        draw.text((column * tile_size + 4, row * tile_size + 4), f"{row + 1}:{column + 1}", fill=(245, 245, 245, 255))
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
    if len(directions) != 8:
        raise ValueError(f"Expected 8 directions, got {len(directions)}")
    if not 0 < ground_y < canvas_size:
        raise ValueError("ground_y must lie inside the runtime canvas")

    with Image.open(source_path) as source_file:
        source = source_file.convert("RGBA")
    row_centers, column_centers = _discover_centers(source, 8, 8)

    poses: list[tuple[int, int, ExtractedPose]] = []
    for row in range(8):
        top, bottom = _axis_bounds(row_centers, row, source.height)
        for column in range(8):
            left, right = _axis_bounds(column_centers, column, source.width)
            cell = source.crop((left, top, right, bottom))
            expected_x = column_centers[column] - left
            pose = _extract_pose(cell, expected_x)
            poses.append((row, column, pose))

    scale = _shared_scale([pose for _row, _column, pose in poses], canvas_size, ground_y)
    destination = Path(output_dir)
    destination.mkdir(parents=True, exist_ok=True)
    built: list[Path] = []
    contact_paths: list[tuple[int, int, Path]] = []
    for row, column, pose in poses:
        frame = _render_pose(pose, scale, canvas_size, ground_y)
        path = destination / f"run_{directions[row]}_{column:02d}.png"
        frame.save(path)
        built.append(path)
        contact_paths.append((row, column, path))

    if contact_sheet_path is not None:
        _write_contact_sheet(contact_paths, Path(contact_sheet_path))
    return built
