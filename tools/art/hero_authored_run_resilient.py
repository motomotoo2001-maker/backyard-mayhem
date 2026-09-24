#!/usr/bin/env python3
"""Resilient production entrypoint for authored hero RUN extraction.

The strict component detector remains useful for clean sheets and diagnostics. Real
production sheets may contain narrow vertical bridges that merge adjacent direction
rows into a single connected component. In that case this wrapper falls back to the
projection-based recovery pipeline, which is independently regression-tested.

Both extraction paths are followed by a conservative presentation-chrome cleanup.
This specifically removes short, wide label bands that can be pulled above a pose
when neighboring authored rows are vertically joined, without relying on label color.
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


def _strip_upper_presentation_band(image: Image.Image) -> Image.Image:
    """Remove a short wide label band near the top of an extracted runtime frame.

    Joined source rows can place the previous row's RUN label above the recovered
    character. Hero body silhouettes do not form a long horizontal slab in the top
    third, so require a wide, shallow band before removing anything. Once such a
    band is confirmed, clear only low-alpha resize halo immediately around it.
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
        for yy in range(start, end):
            for xx in range(left, right):
                pixels[xx, yy] = (0, 0, 0, 0)
        removed_ranges.append((start, end))

    if not removed_ranges:
        return rgba

    # Lanczos resize can leave a 1-2 px semi-transparent halo outside a removed
    # opaque label. Limit cleanup to a narrow neighborhood of a confirmed band
    # and only to low-alpha pixels, so body/weapon antialiasing elsewhere stays.
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
        return _sanitize_built_frames([Path(path) for path in built])
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
        return _sanitize_built_frames([Path(path) for path in built])
