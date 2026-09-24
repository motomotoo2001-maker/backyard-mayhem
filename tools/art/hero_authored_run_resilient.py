#!/usr/bin/env python3
"""Resilient production entrypoint for authored hero RUN extraction.

The strict component detector remains useful for clean sheets and diagnostics. Real
production sheets may contain narrow vertical bridges that merge adjacent direction
rows into a single connected component. In that case this wrapper falls back to the
projection-based recovery pipeline, which is independently regression-tested.
"""

from __future__ import annotations

import importlib.util
import shutil
from pathlib import Path
from typing import Sequence


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
        return [Path(path) for path in built]
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
        return [Path(path) for path in built]
