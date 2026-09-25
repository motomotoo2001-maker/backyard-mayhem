#!/usr/bin/env python3
"""Resilient production entrypoint for authored hero RUN extraction.

The strict component detector remains useful for clean sheets and diagnostics. Real
production sheets may contain narrow vertical bridges that merge adjacent direction
rows into a single connected component. In that case this wrapper falls back to the
projection-based recovery pipeline, which is independently regression-tested.

Both extraction paths are followed by a conservative presentation-chrome cleanup.
Detached short, wide label bands may be removed, but connected hero geometry is never
cut just because shoulders, robe or the leaf-blower form a broad horizontal run.

A final ground-stability gate rejects sequences whose support line jumps far between
frames. This catches a visually expensive failure mode where otherwise valid authored
poses appear to hop vertically because one crop was normalized against the wrong band.
"""

from __future__ import annotations

import importlib.util
import shutil
from pathlib import Path
from typing import Sequence

from PIL import Image


HERE = Path(__file__).resolve().parent
PRIMARY_PATH = HERE / "hero_authored_run_pipeline.py"
RECOVERY_PATH = HERE / "hero_authored_run_recovery_v2.py"
MAX_GROUND_DRIFT_PX = 24


def _load_module(path: Path, name: str):
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Cannot load {name} from {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


_primary = _load_module(PRIMARY_PATH, "hero_authored_run_primary")
DEFAULT_DIRECTIONS = list(_primary.DEFAULT_DIRECTIONS)


def _reset_output_dir(path: Path) -> None:
    if path.exists():
        shutil.rmtree(path)
    path.mkdir(parents=True, exist_ok=True)


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


def _band_touches_foreground_outside(
    alpha,
    start: int,
    end: int,
    left: int,
    right: int,
    image_height: int,
) -> bool:
    """Return True when a candidate band is physically connected to hero geometry.

    A broad shoulder/weapon row can look like presentation chrome in a projection,
    but it remains 8-connected to the body directly above or below the band. A real
    detached RUN label has a transparent gap. Only detached bands are safe to erase.
    """

    for x in range(left, right):
        # Check diagonal/vertical connectivity across the top band boundary.
        if start > 0:
            for nx in range(max(left, x - 1), min(right, x + 2)):
                if alpha[x, start] > 16 and alpha[nx, start - 1] > 16:
                    return True
        # Check diagonal/vertical connectivity across the bottom band boundary.
        if end < image_height:
            for nx in range(max(left, x - 1), min(right, x + 2)):
                if alpha[x, end - 1] > 16 and alpha[nx, end] > 16:
                    return True
    return False


def _strip_upper_presentation_band(image: Image.Image) -> Image.Image:
    """Remove only a detached short wide presentation band near the frame top.

    Earlier versions deleted every wide/shallow row band and could slice through the
    connected shoulder/leaf-blower silhouette. This version requires a real transparent
    separation from foreground outside the candidate band before it removes pixels.
    """

    rgba = image.convert("RGBA")
    bbox = _alpha_bbox(rgba)
    if bbox is None:
        return rgba
    left, top, right, bottom = bbox
    width = right - left
    height = bottom - top
    if width < 20 or height < 32:
        return rgba

    alpha = rgba.getchannel("A").load()
    wide_threshold = max(14, int(width * 0.52))
    scan_bottom = min(bottom, top + max(12, int(height * 0.34)))
    bands: list[tuple[int, int, int]] = []
    y = top
    while y < scan_bottom:
        run = _longest_run(alpha, y, left, right)
        if run < wide_threshold:
            y += 1
            continue
        start = y
        peak = run
        y += 1
        while y < scan_bottom:
            row_run = _longest_run(alpha, y, left, right)
            if row_run < wide_threshold:
                break
            peak = max(peak, row_run)
            y += 1
        bands.append((start, y, peak))

    if not bands:
        return rgba

    cleaned = rgba.copy()
    pixels = cleaned.load()
    removed_ranges: list[tuple[int, int]] = []
    max_band_height = max(12, int(height * 0.18))
    for start, end, peak in bands:
        band_height = end - start
        if band_height < 2 or band_height > max_band_height:
            continue
        # A presentation label is deliberately much wider than it is tall.
        if peak < band_height * 2.8:
            continue
        # Never cut connected hero geometry. Shoulders, robe or the blower may be
        # wide, but a detached label is separated by transparent pixels.
        if _band_touches_foreground_outside(alpha, start, end, left, right, rgba.height):
            continue
        for yy in range(start, end):
            for xx in range(left, right):
                pixels[xx, yy] = (0, 0, 0, 0)
        removed_ranges.append((start, end))

    if not removed_ranges:
        return rgba

    # Lanczos resize can leave a 1-2 px semi-transparent halo outside a removed
    # opaque label. Limit cleanup to a narrow neighborhood of a confirmed detached
    # band and only to low-alpha pixels, so body/weapon antialiasing elsewhere stays.
    for start, end in removed_ranges:
        halo_top = max(top, start - 6)
        halo_bottom = min(bottom, end + 6)
        for yy in range(halo_top, halo_bottom):
            for xx in range(left, right):
                r, g, b, a = pixels[xx, yy]
                if 0 < a <= 24:
                    pixels[xx, yy] = (0, 0, 0, 0)

    return cleaned


def _sanitize_built_frames(paths: Sequence[Path]) -> list[Path]:
    sanitized: list[Path] = []
    for raw_path in paths:
        path = Path(raw_path)
        with Image.open(path) as source:
            image = source.convert("RGBA")
        cleaned = _strip_upper_presentation_band(image)
        cleaned.save(path)
        sanitized.append(path)
    return sanitized


def _parse_run_frame_name(path: Path, directions: Sequence[str]) -> tuple[str, int]:
    stem = path.stem
    for direction in sorted(directions, key=len, reverse=True):
        prefix = f"run_{direction}_"
        if not stem.startswith(prefix):
            continue
        raw_index = stem[len(prefix):]
        try:
            return direction, int(raw_index)
        except ValueError as exc:
            raise RuntimeError(f"Invalid authored RUN frame index: {path.name}") from exc
    raise RuntimeError(f"Unexpected authored RUN filename: {path.name}")


def _validate_ground_stability(
    paths: Sequence[Path],
    directions: Sequence[str] = DEFAULT_DIRECTIONS,
    ground_y: int = 292,
    max_drift_px: int = MAX_GROUND_DRIFT_PX,
) -> None:
    """Reject vertically unstable authored RUN sequences before runtime publish."""

    if max_drift_px < 0:
        raise ValueError(f"max_drift_px must be non-negative, got {max_drift_px}")

    grouped: dict[str, list[tuple[int, int]]] = {direction: [] for direction in directions}
    for raw_path in paths:
        path = Path(raw_path)
        direction, index = _parse_run_frame_name(path, directions)
        with Image.open(path) as source:
            frame = source.convert("RGBA")
        bbox = _alpha_bbox(frame)
        if bbox is None:
            raise RuntimeError(f"{path.name}: empty authored RUN alpha")
        grouped[direction].append((index, int(bbox[3])))

    for direction in directions:
        ordered = sorted(grouped[direction], key=lambda item: item[0])
        indexes = [index for index, _bottom in ordered]
        if indexes != list(range(8)):
            raise RuntimeError(
                f"{direction}: expected 8 RUN frames with indexes 0..7, got {indexes}"
            )

        bottoms = [bottom for _index, bottom in ordered]
        drift = max(bottoms) - min(bottoms)
        if drift > max_drift_px:
            raise RuntimeError(
                f"{direction}: authored RUN ground-anchor drift {drift}px exceeds "
                f"{max_drift_px}px (ground_y={ground_y}, bottoms={bottoms})"
            )


def _finalize_built_frames(
    paths: Sequence[Path],
    directions: Sequence[str],
    ground_y: int,
) -> list[Path]:
    sanitized = _sanitize_built_frames(paths)
    _validate_ground_stability(
        sanitized,
        directions=directions,
        ground_y=ground_y,
        max_drift_px=MAX_GROUND_DRIFT_PX,
    )
    return sanitized


def build_authored_run_frames(
    source_path: Path | str,
    output_dir: Path | str,
    directions: Sequence[str] = DEFAULT_DIRECTIONS,
    canvas_size: int = 320,
    ground_y: int = 292,
    contact_sheet_path: Path | str | None = None,
) -> list[Path]:
    """Build production RUN frames using strict detection with tested recovery fallback."""

    destination = Path(output_dir)
    _reset_output_dir(destination)
    try:
        built = _primary.build_authored_run_frames(
            source_path,
            destination,
            directions=directions,
            canvas_size=canvas_size,
            ground_y=ground_y,
            contact_sheet_path=contact_sheet_path,
        )
        print("Authored RUN detector: connected-component primary")
        return _finalize_built_frames([Path(path) for path in built], directions, ground_y)
    except ValueError as primary_error:
        print(f"Primary authored RUN detector failed: {primary_error}")
        print("Authored RUN detector: projection recovery fallback")
        _reset_output_dir(destination)
        recovery = _load_module(RECOVERY_PATH, "hero_authored_run_recovery_v2_runtime")
        built = recovery.build_recovered_run_frames(
            source_path,
            destination,
            directions=directions,
            canvas_size=canvas_size,
            ground_y=ground_y,
            contact_sheet_path=contact_sheet_path,
        )
        if len(built) != len(directions) * 8:
            raise RuntimeError(
                f"Projection recovery produced {len(built)} frames after primary failure: {primary_error}"
            )
        return _finalize_built_frames([Path(path) for path in built], directions, ground_y)
