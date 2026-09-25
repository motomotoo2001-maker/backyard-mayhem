#!/usr/bin/env python3
"""Build reviewed hero runtime art without risking live runtime assets.

Default mode writes a complete candidate into artifacts/hero_candidate. Nothing in
assets/runtime is changed until the operator has visually reviewed the authored RUN
and FIRE contact sheets and reruns this command with --apply.
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
        help="staging directory for reviewed hero frames and contact sheets",
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
    """Explicit recovery utility kept for diagnostics/manual repair only.

    Production staging intentionally does not monkeypatch this adapter into the builder.
    The full candidate must pass the same shared extractor that production uses.
    """
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


def _validate_authored_fire_frames(
    frames_dir: Path,
    generated,
    directions: Sequence[str],
    canvas_size,
    ground_y: int,
) -> None:
    """Require a real three-pose FIRE sequence plus one recovery frame per direction."""
    expected_size = tuple(canvas_size) if isinstance(canvas_size, tuple) else (int(canvas_size), int(canvas_size))
    if not 0 < int(ground_y) < expected_size[1]:
        raise RuntimeError(f"Invalid shared hero FIRE ground anchor: {ground_y}")

    for direction in directions:
        names = list(generated.get(("fire", direction), []))
        if len(names) != 4:
            raise RuntimeError(f"{direction}: expected 4 FIRE frames (3 authored + recovery), got {len(names)}")

        unique_authored: set[bytes] = set()
        for frame_index, name in enumerate(names):
            path = frames_dir / name
            if not path.is_file():
                raise RuntimeError(f"Missing FIRE candidate frame: {name}")
            with Image.open(path) as source:
                frame = source.convert("RGBA")
            if frame.size != expected_size:
                raise RuntimeError(f"{name}: expected canvas {expected_size}, got {frame.size}")
            bbox = frame.getchannel("A").getbbox()
            if bbox is None:
                raise RuntimeError(f"{name}: empty FIRE alpha")
            left, top, right, bottom = bbox
            if left < 8 or top < 8 or expected_size[0] - right < 8 or expected_size[1] - bottom < 8:
                raise RuntimeError(f"{name}: authored FIRE safe-margin violation: {bbox}")
            if frame_index < 3:
                unique_authored.add(frame.tobytes())

        if len(unique_authored) != 3:
            raise RuntimeError(
                f"{direction}: FIRE sequence has only {len(unique_authored)} unique authored poses; "
                "expected three distinct firing poses before recovery"
            )


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
        if not name.startswith(("run_", "fire_")) and (
            bbox[0] <= 0
            or bbox[1] <= 0
            or bbox[2] >= expected_size[0]
            or bbox[3] >= expected_size[1]
        ):
            print(f"WARNING: legacy non-authored frame touches runtime canvas edge: {name} {bbox}")

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

    _validate_authored_fire_frames(frames_dir, generated, directions, expected_size, ground_y)

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


def _write_fire_contact_sheet(frames_dir: Path, generated, directions: Sequence[str], path: Path) -> None:
    tile = 120
    sheet = Image.new("RGBA", (4 * tile, len(directions) * tile), (28, 32, 36, 255))
    draw = ImageDraw.Draw(sheet)
    for row, direction in enumerate(directions):
        names = list(generated[("fire", direction)])
        if len(names) != 4:
            raise RuntimeError(f"{direction}: FIRE contact sheet expected 4 frames, got {len(names)}")
        for column, name in enumerate(names):
            with Image.open(frames_dir / name) as source:
                frame = source.convert("RGBA")
            thumb = frame.resize((tile, tile), Image.Resampling.LANCZOS)
            sheet.alpha_composite(thumb, (column * tile, row * tile))
            label = "REC" if column == 3 else f"F{column + 1}"
            draw.text(
                (column * tile + 4, row * tile + 4),
                f"{direction} {label}",
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


def _chair_visual_offset() -> tuple[float, float]:
    """Match the placed Chair Sprite2D visual offset exactly."""
    return (0.0, -32.0)


def _replace_grounding_block(path: Path, old: str, new: str) -> None:
    text = path.read_text(encoding="utf-8")
    if new in text:
        return
    if old not in text:
        raise RuntimeError(f"Grounding patch contract changed unexpectedly: {path}")
    path.write_text(text.replace(old, new, 1), encoding="utf-8")


def _patch_full_project_grounding(project_root: Path) -> None:
    """Align hero/chair shadows and make the green Chair preview use the placed visual anchor."""
    player_scene = project_root / "scenes/player/player.tscn"
    chair_scene = project_root / "scenes/defenses/chair_barricade.tscn"
    build_controller = project_root / "scripts/build/build_controller.gd"
    for path in (player_scene, chair_scene, build_controller):
        if not path.is_file():
            raise RuntimeError(f"Grounding target missing from full project: {path}")

    _replace_grounding_block(
        player_scene,
        '[node name="Shadow" type="Polygon2D" parent="VisualRoot"]\npolygon = PackedVector2Array(-34, -2, -24, -8, 24, -8, 34, -2, 24, 5, -24, 5)\nposition = Vector2(0, 30)',
        '[node name="Shadow" type="Polygon2D" parent="VisualRoot"]\npolygon = PackedVector2Array(-34, -2, -24, -8, 24, -8, 34, -2, 24, 5, -24, 5)\nposition = Vector2(0, 6)',
    )
    _replace_grounding_block(
        chair_scene,
        '[node name="Shadow" type="Polygon2D" parent="."]\npolygon = PackedVector2Array(-38, 0, -27, -8, 27, -8, 38, 0, 27, 8, -27, 8)\nposition = Vector2(0, 24)',
        '[node name="Shadow" type="Polygon2D" parent="."]\npolygon = PackedVector2Array(-38, 0, -27, -8, 27, -8, 38, 0, 27, 8, -27, 8)\nposition = Vector2(0, 6)',
    )

    process_old = '''    if active and _ghost != null:\n        _ghost.global_position = get_parent().get_global_mouse_position()\n        var valid := _is_valid_position(_ghost.global_position)\n        _ghost.modulate = Color(0.45,1.0,0.45,0.55) if valid else Color(1.0,0.25,0.25,0.55)\n        _ghost.visible = not is_building()\n        _refresh_range_preview(_ghost.global_position, valid)'''
    process_new = '''    if active and _ghost != null:\n        var build_position: Vector2 = get_parent().get_global_mouse_position()\n        _ghost.global_position = build_position + _preview_visual_offset_for(selected)\n        var valid := _is_valid_position(build_position)\n        _ghost.modulate = Color(0.45,1.0,0.45,0.55) if valid else Color(1.0,0.25,0.25,0.55)\n        _ghost.visible = not is_building()\n        _refresh_range_preview(build_position, valid)'''
    _replace_grounding_block(build_controller, process_old, process_new)

    select_old = '''        _ensure_ghost()\n        _ensure_range_preview()\n        _refresh_range_preview(_ghost.global_position, _is_valid_position(_ghost.global_position))'''
    select_new = '''        _ensure_ghost()\n        _ensure_range_preview()\n        var preview_position: Vector2 = get_parent().get_global_mouse_position() if get_parent() is Node2D else Vector2.ZERO\n        _ghost.global_position = preview_position + _preview_visual_offset_for(selected)\n        _refresh_range_preview(preview_position, _is_valid_position(preview_position))'''
    _replace_grounding_block(build_controller, select_old, select_new)

    offset_marker = '''\nfunc _ghost_scale_for(kind: StringName) -> float:\n'''
    offset_function = '''\nfunc _preview_visual_offset_for(kind: StringName) -> Vector2:\n    match kind:\n        &"chair": return Vector2(0, -32)\n    return Vector2.ZERO\n\nfunc _ghost_scale_for(kind: StringName) -> float:\n'''
    _replace_grounding_block(build_controller, offset_marker, offset_function)
    print("Applied full-project grounding patch: hero shadow, Chair shadow, Chair build preview")


def main() -> None:
    args = _parse_args()
    builder = _load_module(BUILDER_PATH, "backyard_hero_builder")
    pipeline = _load_module(PIPELINE_PATH, "backyard_authored_run_pipeline")
    _print_sheet_diagnostics(pipeline, builder.MOVE_SRC)

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
    run_contact_sheet = candidate_dir / "authored-run-contact-sheet.png"
    fire_contact_sheet = candidate_dir / "authored-fire-contact-sheet.png"
    _write_run_contact_sheet(frames_dir, generated, builder.DIRECTIONS, run_contact_sheet)
    _write_fire_contact_sheet(frames_dir, generated, builder.DIRECTIONS, fire_contact_sheet)

    run_count = len(generated[("run", "front")])
    fire_count = len(generated[("fire", "front")])
    print("movement directions:", len(builder.DIRECTIONS), "run frames each:", run_count)
    print("fire frames each:", fire_count, "(3 authored + recovery)")
    print(
        "build:", len(generated[("build", "generic")]),
        "hurt:", len(generated[("hurt", "generic")]),
        "defeat:", len(generated[("defeat", "generic")]),
    )
    print(f"Candidate validated: {candidate_dir}")
    print(f"Review RUN contact sheet: {run_contact_sheet}")
    print(f"Review FIRE contact sheet: {fire_contact_sheet}")

    if args.apply:
        _publish_candidate(frames_dir, runtime_dir)
        _patch_full_project_grounding(PROJECT_ROOT)
        print(f"APPLIED validated hero candidate to: {runtime_dir}")
    else:
        print("Runtime unchanged. Re-run with --apply only after visual review.")


if __name__ == "__main__":
    main()
