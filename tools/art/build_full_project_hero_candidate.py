#!/usr/bin/env python3
"""Build hero runtime art with authored RUN frames without risking live runtime assets.

Default mode writes a complete candidate into artifacts/hero_candidate. Nothing in
assets/runtime is changed until the operator has visually reviewed the contact sheet
and reruns this command with --apply.
"""

from __future__ import annotations

import argparse
import importlib.util
import shutil
import tempfile
from pathlib import Path
from statistics import median
from typing import Sequence

from PIL import Image, ImageDraw


HERE = Path(__file__).resolve().parent
PROJECT_ROOT = HERE.parents[1]
BUILDER_PATH = HERE / "build_new_reference_hero.py"
PIPELINE_PATH = HERE / "hero_authored_run_pipeline.py"
RECOVERY_PATH = HERE / "hero_authored_run_recovery_v2.py"
DEFAULT_CANDIDATE_DIR = PROJECT_ROOT / "artifacts" / "hero_candidate"


def _load_module(path: Path, name: str):
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Cannot load {name} from {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--candidate-dir",
        type=Path,
        default=DEFAULT_CANDIDATE_DIR,
        help="staging directory for reviewed hero frames and contact sheet",
    )
    parser.add_argument(
        "--apply",
        action="store_true",
        help="publish the already validated candidate into assets/runtime",
    )
    return parser.parse_args()


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


def _load_frames_from_paths(paths, directions: Sequence[str]):
    result = {direction: [] for direction in directions}
    match_order = sorted(directions, key=len, reverse=True)
    for frame_path in paths:
        stem = Path(frame_path).stem
        matched_direction = None
        matched_index = None
        for direction in match_order:
            prefix = f"run_{direction}_"
            if stem.startswith(prefix):
                matched_direction = direction
                matched_index = int(stem[len(prefix):])
                break
        if matched_direction is None or matched_index is None:
            raise RuntimeError(f"Unexpected authored RUN filename: {Path(frame_path).name}")
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


def _authored_run_adapter(
    pipeline,
    recovery,
    source_path,
    directions: Sequence[str],
    canvas_size,
    ground_y: int,
):
    size = int(canvas_size[0] if isinstance(canvas_size, tuple) else canvas_size)
    if isinstance(canvas_size, tuple) and canvas_size[0] != canvas_size[1]:
        raise ValueError(f"Authored RUN runtime canvas must be square, got {canvas_size}")

    with tempfile.TemporaryDirectory(prefix="backyard-authored-run-") as temp_dir:
        output_dir = Path(temp_dir) / "frames"
        try:
            built = pipeline.build_authored_run_frames(
                source_path,
                output_dir,
                directions=directions,
                canvas_size=size,
                ground_y=int(ground_y),
            )
            print("Authored RUN detector: connected-component primary")
        except ValueError as exc:
            print(f"Primary authored RUN detector failed: {exc}")
            print("Authored RUN detector: projection recovery fallback")
            built = recovery.build_recovered_run_frames(
                source_path,
                output_dir,
                directions=directions,
                canvas_size=size,
                ground_y=int(ground_y),
            )
        return _load_frames_from_paths(built, directions)


def _validate_candidate_frames(
    frames_dir: Path,
    generated,
    directions: Sequence[str],
    canvas_size,
    ground_y: int,
) -> None:
    expected_size = tuple(canvas_size) if isinstance(canvas_size, tuple) else (int(canvas_size), int(canvas_size))
    if not 0 < int(ground_y) < expected_size[1]:
        raise RuntimeError(f"Invalid shared hero ground anchor: {ground_y}")

    # Baseline contract for every state: the resource must exist, be non-empty and
    # use the production canvas. Legacy action art has separate visual debt and must
    # not block the authored-RUN replacement milestone merely because it touches an
    # edge; RUN gets the strict safe-margin contract below.
    names = sorted({name for frame_names in generated.values() for name in frame_names})
    if not names:
        raise RuntimeError("Hero candidate did not generate any frames")
    for name in names:
        path = frames_dir / name
        if not path.is_file():
            raise RuntimeError(f"Missing candidate frame: {name}")
        with Image.open(path) as source:
            frame = source.convert("RGBA")
        if frame.size != expected_size:
            raise RuntimeError(f"{name}: expected canvas {expected_size}, got {frame.size}")
        bbox = frame.getchannel("A").getbbox()
        if bbox is None:
            raise RuntimeError(f"{name}: empty alpha")
        if not name.startswith("run_") and (
            bbox[0] <= 0
            or bbox[1] <= 0
            or bbox[2] >= expected_size[0]
            or bbox[3] >= expected_size[1]
        ):
            print(f"WARNING: legacy non-RUN frame touches runtime canvas edge: {name} {bbox}")

    # RUN gets the stricter production contract: 8 authored frames per direction,
    # safe margins and meaningful pose variation (not a duplicated static frame).
    for direction in directions:
        run_names = list(generated.get(("run", direction), []))
        if len(run_names) != 8:
            raise RuntimeError(f"{direction}: expected 8 authored RUN frames, got {len(run_names)}")
        unique_frames: set[bytes] = set()
        for name in run_names:
            with Image.open(frames_dir / name) as source:
                frame = source.convert("RGBA")
            bbox = frame.getchannel("A").getbbox()
            assert bbox is not None
            left, top, right, bottom = bbox
            if left < 8 or top < 8 or expected_size[0] - right < 8 or expected_size[1] - bottom < 8:
                raise RuntimeError(f"{name}: authored RUN safe-margin violation: {bbox}")
            unique_frames.add(frame.tobytes())
        if len(unique_frames) < 4:
            raise RuntimeError(
                f"{direction}: RUN sequence has only {len(unique_frames)} unique poses; "
                "refusing static/procedural-looking candidate"
            )

    spriteframes = frames_dir / "builder_hero_frames.tres"
    if not spriteframes.is_file() or spriteframes.stat().st_size <= 0:
        raise RuntimeError("Candidate SpriteFrames resource was not generated")


def _write_run_contact_sheet(frames_dir: Path, generated, directions: Sequence[str], path: Path) -> None:
    tile = 120
    sheet = Image.new("RGBA", (8 * tile, len(directions) * tile), (28, 32, 36, 255))
    draw = ImageDraw.Draw(sheet)
    for row, direction in enumerate(directions):
        names = list(generated[("run", direction)])
        for column, name in enumerate(names):
            with Image.open(frames_dir / name) as source:
                frame = source.convert("RGBA")
            thumb = frame.resize((tile, tile), Image.Resampling.LANCZOS)
            sheet.alpha_composite(thumb, (column * tile, row * tile))
            draw.text(
                (column * tile + 4, row * tile + 4),
                f"{direction} {column + 1}",
                fill=(245, 245, 245, 255),
            )
    path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(path)


def _publish_candidate(frames_dir: Path, runtime_dir: Path) -> None:
    runtime_dir.mkdir(parents=True, exist_ok=True)
    sources = sorted(frames_dir.glob("*.png"))
    spriteframes = frames_dir / "builder_hero_frames.tres"
    if not sources or not spriteframes.is_file():
        raise RuntimeError("Candidate is incomplete; refusing runtime publish")

    for path in runtime_dir.glob("*.png"):
        path.unlink()
    runtime_tres = runtime_dir / "builder_hero_frames.tres"
    if runtime_tres.exists():
        runtime_tres.unlink()

    for source in sources:
        shutil.copy2(source, runtime_dir / source.name)
    shutil.copy2(spriteframes, runtime_tres)


def main() -> None:
    args = _parse_args()
    builder = _load_module(BUILDER_PATH, "backyard_hero_builder")
    pipeline = _load_module(PIPELINE_PATH, "backyard_authored_run_pipeline")
    recovery = _load_module(RECOVERY_PATH, "backyard_authored_run_recovery_v2")
    _print_sheet_diagnostics(pipeline, builder.MOVE_SRC)

    def build_authored_run_frames(
        source_path,
        directions=builder.DIRECTIONS,
        canvas_size=builder.CANVAS,
        ground_y=builder.ANCHOR[1],
    ):
        return _authored_run_adapter(
            pipeline,
            recovery,
            source_path,
            directions=directions,
            canvas_size=canvas_size,
            ground_y=ground_y,
        )

    builder.build_authored_run_frames = build_authored_run_frames
    movement = builder.movement_frames()
    actions = builder.action_frames(movement)

    candidate_dir = args.candidate_dir.resolve()
    frames_dir = candidate_dir / "frames"
    if frames_dir.exists():
        shutil.rmtree(frames_dir)
    frames_dir.mkdir(parents=True, exist_ok=True)

    runtime_dir = Path(builder.OUT)
    original_out = builder.OUT
    try:
        builder.OUT = frames_dir
        generated = builder.save_frames(movement, actions)
        builder.write_spriteframes(generated)
    finally:
        builder.OUT = original_out

    _validate_candidate_frames(
        frames_dir,
        generated,
        builder.DIRECTIONS,
        builder.CANVAS,
        builder.ANCHOR[1],
    )
    contact_sheet = candidate_dir / "authored-run-contact-sheet.png"
    _write_run_contact_sheet(frames_dir, generated, builder.DIRECTIONS, contact_sheet)

    run_count = len(generated[("run", "front")])
    print("movement directions:", len(builder.DIRECTIONS), "run frames each:", run_count)
    print(
        "build:", len(generated[("build", "generic")]),
        "hurt:", len(generated[("hurt", "generic")]),
        "defeat:", len(generated[("defeat", "generic")]),
    )
    print(f"Candidate validated: {candidate_dir}")
    print(f"Review contact sheet: {contact_sheet}")

    if args.apply:
        _publish_candidate(frames_dir, runtime_dir)
        print(f"APPLIED validated hero candidate to: {runtime_dir}")
    else:
        print("Runtime unchanged. Re-run with --apply only after visual review.")


if __name__ == "__main__":
    main()
