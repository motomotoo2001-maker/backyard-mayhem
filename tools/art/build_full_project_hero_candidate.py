#!/usr/bin/env python3
"""Build hero runtime art in the canonical full project using the tested authored RUN pipeline."""

from __future__ import annotations

import importlib.util
import tempfile
from pathlib import Path
from statistics import median
from typing import Sequence

from PIL import Image


HERE = Path(__file__).resolve().parent
BUILDER_PATH = HERE / "build_new_reference_hero.py"
PIPELINE_PATH = HERE / "hero_authored_run_pipeline.py"


def _load_module(path: Path, name: str):
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Cannot load {name} from {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _print_sheet_diagnostics(pipeline, source_path: Path) -> None:
    with Image.open(source_path) as source_file:
        source = source_file.convert("RGBA")
    raw = pipeline._connected_components(source)
    candidates = [
        component
        for component in raw
        if pipeline._is_character_candidate(component, source.size, 8, 8)
    ]
    rows = pipeline._cluster_rows(candidates, 8)
    print("AUTHORED RUN SHEET DIAGNOSTICS")
    for row_index, row in enumerate(rows):
        ordered = sorted(row, key=lambda component: component.center_x)
        centers = [round(component.center_x, 1) for component in ordered]
        sizes = [(component.width, component.height, component.pixels) for component in ordered]
        tops = [component.bbox[1] for component in ordered]
        bottoms = [component.bbox[3] for component in ordered]
        print(
            f"row={row_index} count={len(ordered)} "
            f"centers={centers} sizes={sizes} "
            f"median_top={median(tops):.1f} median_bottom={median(bottoms):.1f}"
        )


def _authored_run_adapter(pipeline, source_path, directions: Sequence[str], canvas_size, ground_y: int):
    size = int(canvas_size[0] if isinstance(canvas_size, tuple) else canvas_size)
    if isinstance(canvas_size, tuple) and canvas_size[0] != canvas_size[1]:
        raise ValueError(f"Authored RUN runtime canvas must be square, got {canvas_size}")

    with tempfile.TemporaryDirectory(prefix="backyard-authored-run-") as temp_dir:
        output_dir = Path(temp_dir) / "frames"
        built = pipeline.build_authored_run_frames(
            source_path,
            output_dir,
            directions=directions,
            canvas_size=size,
            ground_y=int(ground_y),
        )
        result = {direction: [] for direction in directions}
        for frame_path in built:
            stem = frame_path.stem
            matched_direction = None
            matched_index = None
            for direction in directions:
                prefix = f"run_{direction}_"
                if stem.startswith(prefix):
                    matched_direction = direction
                    matched_index = int(stem[len(prefix):])
                    break
            if matched_direction is None or matched_index is None:
                raise RuntimeError(f"Unexpected authored RUN filename: {frame_path.name}")
            with Image.open(frame_path) as source:
                frame = source.convert("RGBA").copy()
            result[matched_direction].append((matched_index, frame))

        normalized = {}
        for direction in directions:
            ordered = sorted(result[direction], key=lambda item: item[0])
            indexes = [index for index, _frame in ordered]
            if indexes != list(range(8)):
                raise RuntimeError(f"{direction}: expected RUN indexes 0..7, got {indexes}")
            normalized[direction] = [frame for _index, frame in ordered]
        return normalized


def main() -> None:
    builder = _load_module(BUILDER_PATH, "backyard_hero_builder")
    pipeline = _load_module(PIPELINE_PATH, "backyard_authored_run_pipeline")
    _print_sheet_diagnostics(pipeline, builder.MOVE_SRC)

    def build_authored_run_frames(source_path, directions=builder.DIRECTIONS, canvas_size=builder.CANVAS, ground_y=builder.ANCHOR[1]):
        return _authored_run_adapter(
            pipeline,
            source_path,
            directions=directions,
            canvas_size=canvas_size,
            ground_y=ground_y,
        )

    builder.build_authored_run_frames = build_authored_run_frames

    movement = builder.movement_frames()
    actions = builder.action_frames(movement)
    generated = builder.save_frames(movement, actions)
    builder.write_spriteframes(generated)

    run_count = len(generated[("run", "front")])
    if run_count != 8:
        raise RuntimeError(f"Expected 8 authored RUN frames per direction, got {run_count}")
    print("movement directions:", len(builder.DIRECTIONS), "run frames each:", run_count)
    print(
        "build:", len(generated[("build", "generic")]),
        "hurt:", len(generated[("hurt", "generic")]),
        "defeat:", len(generated[("defeat", "generic")]),
    )


if __name__ == "__main__":
    main()
