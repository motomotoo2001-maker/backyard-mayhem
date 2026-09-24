#!/usr/bin/env python3
"""Ground-normalizing wrapper for projection-based authored RUN recovery."""

from __future__ import annotations

import importlib.util
from pathlib import Path
from typing import Sequence

from PIL import Image, ImageDraw


BASE_PATH = Path(__file__).with_name("hero_authored_run_recovery.py")


def _load_base():
    spec = importlib.util.spec_from_file_location("hero_authored_run_recovery_base", BASE_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Cannot load recovery base from {BASE_PATH}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _normalize_ground(path: Path, canvas_size: int, ground_y: int) -> None:
    with Image.open(path) as source:
        image = source.convert("RGBA")
    bbox = image.getchannel("A").point(lambda value: 255 if value > 16 else 0).getbbox()
    if bbox is None:
        raise ValueError(f"Recovered frame is empty: {path.name}")
    shift_y = ground_y - bbox[3]
    if shift_y == 0:
        return
    shifted = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    shifted.alpha_composite(image, (0, shift_y))
    normalized_bbox = shifted.getchannel("A").point(lambda value: 255 if value > 16 else 0).getbbox()
    if normalized_bbox is None or normalized_bbox[3] != ground_y:
        raise ValueError(
            f"Could not normalize {path.name} to ground {ground_y}; bbox={normalized_bbox}"
        )
    if normalized_bbox[1] < 6:
        raise ValueError(f"Ground normalization clips top margin in {path.name}: {normalized_bbox[1]}")
    shifted.save(path)


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
