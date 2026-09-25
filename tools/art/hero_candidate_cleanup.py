#!/usr/bin/env python3
"""Clean staged hero runtime frames before they are published into the full project.

The source sheets contain occasional detached labels/neighbour fragments and some frames
arrive a few pixels above the shared ground line. This pass works only on already staged
320x320 authored RUN/FIRE frames: it removes far detached alpha islands, preserves nearby
weapon/hose pieces, and shifts the primary body component onto one shared ground anchor.
"""

from __future__ import annotations

import argparse
import json
import re
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw


DIRECTIONS = (
    "front",
    "front_right",
    "right",
    "back_right",
    "back",
    "back_left",
    "left",
    "front_left",
)
FRAME_RE = re.compile(
    r"^(run|fire)_(front|front_right|right|back_right|back|back_left|left|front_left)_(\d{2})\.png$"
)


@dataclass(frozen=True)
class Component:
    pixels: int
    bbox: tuple[int, int, int, int]
    points: tuple[tuple[int, int], ...]

    @property
    def width(self) -> int:
        return self.bbox[2] - self.bbox[0]

    @property
    def height(self) -> int:
        return self.bbox[3] - self.bbox[1]


def _alpha_components(image: Image.Image, alpha_threshold: int = 18) -> list[Component]:
    alpha = image.convert("RGBA").getchannel("A")
    width, height = alpha.size
    px = alpha.load()
    visited = bytearray(width * height)
    components: list[Component] = []

    def index(x: int, y: int) -> int:
        return y * width + x

    for y in range(height):
        for x in range(width):
            flat = index(x, y)
            if visited[flat] or px[x, y] <= alpha_threshold:
                continue
            stack = [(x, y)]
            visited[flat] = 1
            points: list[tuple[int, int]] = []
            left = right = x
            top = bottom = y
            while stack:
                cx, cy = stack.pop()
                points.append((cx, cy))
                left = min(left, cx)
                right = max(right, cx)
                top = min(top, cy)
                bottom = max(bottom, cy)
                for nx, ny in ((cx - 1, cy), (cx + 1, cy), (cx, cy - 1), (cx, cy + 1)):
                    if not (0 <= nx < width and 0 <= ny < height):
                        continue
                    ni = index(nx, ny)
                    if visited[ni] or px[nx, ny] <= alpha_threshold:
                        continue
                    visited[ni] = 1
                    stack.append((nx, ny))
            components.append(
                Component(
                    pixels=len(points),
                    bbox=(left, top, right + 1, bottom + 1),
                    points=tuple(points),
                )
            )
    components.sort(key=lambda component: component.pixels, reverse=True)
    return components


def _bbox_gap(a: tuple[int, int, int, int], b: tuple[int, int, int, int]) -> tuple[int, int]:
    al, at, ar, ab = a
    bl, bt, br, bb = b
    dx = max(0, bl - ar, al - br)
    dy = max(0, bt - ab, at - bb)
    return dx, dy


def _looks_like_upper_presentation_band(main: Component, component: Component) -> bool:
    """Identify a detached RUN/label band sitting immediately above the hero body.

    Real source sheets sometimes place a wide, shallow presentation label only a few
    pixels above the head. A plain proximity rule mistakes it for a detached weapon
    or hose segment. Require geometry that is characteristic of a label: fully above
    the body, close vertically, wide relative to the body, shallow, and strongly
    horizontal. This keeps small round/square weapon pieces intact.
    """

    if component.bbox[3] > main.bbox[1]:
        return False
    _dx, dy = _bbox_gap(main.bbox, component.bbox)
    if dy > max(14, int(main.height * 0.08)):
        return False

    width_ratio = component.width / max(1, main.width)
    height_ratio = component.height / max(1, main.height)
    aspect = component.width / max(1, component.height)
    area_ratio = component.pixels / max(1, main.pixels)
    return (
        width_ratio >= 0.28
        and height_ratio <= 0.18
        and aspect >= 2.4
        and area_ratio >= 0.02
    )


def _kept_components(components: list[Component]) -> tuple[Component, list[Component]]:
    if not components:
        raise RuntimeError("hero frame has no visible foreground")
    main = components[0]
    kept = [main]
    nearby_x = max(34, int(main.width * 0.55))
    nearby_y = max(24, int(main.height * 0.16))
    significant = max(28, int(main.pixels * 0.012))
    lower_slack = 2

    for component in components[1:]:
        dx, dy = _bbox_gap(main.bbox, component.bbox)
        # Joined source rows can leave a wide RUN label just 2-5 px above the
        # hero's head. Remove it before the generic proximity rule has a chance
        # to preserve it as if it were a detached hose/weapon segment.
        if _looks_like_upper_presentation_band(main, component):
            continue
        # Detached pieces below the main feet are crop contamination even when they
        # are spatially close in X/Y. Keeping them would constrain the frame shift
        # and make the actual hero float above the shared ground line.
        if component.bbox[3] > main.bbox[3] + lower_slack:
            continue
        # Preserve detached hose/weapon pieces only when they remain spatially tied
        # to the body and do not extend below its feet. Distant labels, neighbouring
        # limbs and sheet debris disappear.
        if dx <= nearby_x and dy <= nearby_y:
            kept.append(component)
        elif component.pixels >= significant:
            # A large distant island is exactly the crop failure we want to reject,
            # not silently keep. The caller turns it into an explicit diagnostic.
            continue
    return main, kept


def clean_frame(
    image: Image.Image,
    *,
    ground_y: int = 306,
    safe_margin: int = 8,
) -> tuple[Image.Image, dict[str, int]]:
    frame = image.convert("RGBA")
    if frame.size != (320, 320):
        raise RuntimeError(f"expected 320x320 hero frame, got {frame.size}")

    components = _alpha_components(frame)
    main, kept = _kept_components(components)

    data = frame.load()
    removed_pixels = 0
    for component in components:
        if component in kept:
            continue
        for x, y in component.points:
            if data[x, y][3] > 0:
                data[x, y] = (0, 0, 0, 0)
                removed_pixels += 1

    # Re-measure after cleanup and place the primary body on the shared floor line.
    components_after = _alpha_components(frame)
    if not components_after:
        raise RuntimeError("cleanup removed all hero foreground")
    body = components_after[0]
    body_bottom_pixel = body.bbox[3] - 1
    requested_shift = int(ground_y) - body_bottom_pixel

    visible_bbox = frame.getchannel("A").point(lambda p: 255 if p > 18 else 0).getbbox()
    if visible_bbox is None:
        raise RuntimeError("cleanup produced empty alpha")
    left, top, right, bottom = visible_bbox
    min_shift = safe_margin - top
    max_shift = (frame.height - safe_margin) - bottom
    shift_y = max(min(requested_shift, max_shift), min_shift)

    if shift_y:
        shifted = Image.new("RGBA", frame.size, (0, 0, 0, 0))
        shifted.alpha_composite(frame, (0, shift_y))
        frame = shifted

    final_components = _alpha_components(frame)
    final_main = final_components[0]
    final_bottom = final_main.bbox[3] - 1
    if abs(final_bottom - int(ground_y)) > 3:
        raise RuntimeError(
            f"body ground anchor drift remains {final_bottom - int(ground_y):+d}px after cleanup"
        )

    # Reject any still-significant island that remains visibly detached from the body.
    max_dx = max(42, int(final_main.width * 0.60))
    max_dy = max(28, int(final_main.height * 0.18))
    significant = max(36, int(final_main.pixels * 0.018))
    for component in final_components[1:]:
        if component.pixels < significant:
            continue
        dx, dy = _bbox_gap(final_main.bbox, component.bbox)
        if dx > max_dx or dy > max_dy:
            raise RuntimeError(
                f"detached alpha island remains after cleanup: area={component.pixels} gap=({dx},{dy})"
            )

    return frame, {
        "components_before": len(components),
        "components_after": len(final_components),
        "removed_pixels": removed_pixels,
        "shift_y": shift_y,
        "body_bottom": final_bottom,
    }


def _write_contact_sheet(frames_dir: Path, action: str, columns: int, output: Path) -> None:
    tile = 128
    label_w = 112
    sheet = Image.new("RGBA", (label_w + columns * tile, len(DIRECTIONS) * tile), (28, 31, 34, 255))
    draw = ImageDraw.Draw(sheet)
    for row, direction in enumerate(DIRECTIONS):
        draw.text((8, row * tile + 8), direction, fill=(245, 245, 245, 255))
        for index in range(columns):
            path = frames_dir / f"{action}_{direction}_{index:02d}.png"
            if not path.is_file():
                continue
            with Image.open(path) as source:
                frame = source.convert("RGBA")
            thumb = frame.resize((tile, tile), Image.Resampling.LANCZOS)
            sheet.alpha_composite(thumb, (label_w + index * tile, row * tile))
            draw.text(
                (label_w + index * tile + 4, row * tile + 4),
                str(index + 1),
                fill=(255, 230, 100, 255),
            )
    output.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(output)


def clean_candidate(candidate_dir: Path, ground_y: int = 306) -> dict[str, dict[str, int]]:
    frames_dir = candidate_dir / "frames"
    if not frames_dir.is_dir():
        raise RuntimeError(f"candidate frames directory missing: {frames_dir}")

    report: dict[str, dict[str, int]] = {}
    matched = 0
    for path in sorted(frames_dir.glob("*.png")):
        if not FRAME_RE.match(path.name):
            continue
        matched += 1
        with Image.open(path) as source:
            cleaned, stats = clean_frame(source, ground_y=ground_y)
        cleaned.save(path)
        report[path.name] = stats

    if matched != 96:
        raise RuntimeError(f"expected 96 authored RUN/FIRE frames, found {matched}")

    _write_contact_sheet(frames_dir, "run", 8, candidate_dir / "clean-run-contact-sheet.png")
    _write_contact_sheet(frames_dir, "fire", 4, candidate_dir / "clean-fire-contact-sheet.png")
    (candidate_dir / "cleanup-report.json").write_text(
        json.dumps(report, indent=2, sort_keys=True), encoding="utf-8"
    )
    return report


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--candidate-dir", type=Path, required=True)
    parser.add_argument("--ground-y", type=int, default=306)
    return parser.parse_args()


def main() -> None:
    args = _parse_args()
    report = clean_candidate(args.candidate_dir.resolve(), args.ground_y)
    removed = sum(item["removed_pixels"] for item in report.values())
    shifted = sum(1 for item in report.values() if item["shift_y"] != 0)
    print(f"Cleaned authored hero frames: {len(report)}")
    print(f"Removed detached alpha pixels: {removed}")
    print(f"Re-grounded frames: {shifted}")


if __name__ == "__main__":
    main()
