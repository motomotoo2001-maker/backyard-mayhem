from pathlib import Path
from PIL import Image
import numpy as np

ROOT = Path(__file__).resolve().parents[2]
MOVE_SRC = ROOT / 'assets/source/user_pack/hero_new_8dir_movement_sheet.png'
CLEAN_SRC = ROOT / 'assets/source/user_pack/hero_clean_8dir_reference.png'
ACTION_SRC = ROOT / 'assets/source/user_pack/hero_new_action_sheet.png'
OUT = ROOT / 'assets/runtime/characters/builder_hero'
OUT.mkdir(parents=True, exist_ok=True)
CANVAS = (320, 320)
ANCHOR = (160, 306)
TARGET_MAIN_HEIGHT = 244
DIRECTIONS = ['front','front_right','right','back_right','back','back_left','left','front_left']


def component_boxes(alpha: np.ndarray, min_area=40):
    mask = alpha > 18
    h, w = mask.shape
    labels = np.zeros((h, w), dtype=np.int32)
    comps = []
    idx = 0
    for y in range(h):
        for x in range(w):
            if not mask[y, x] or labels[y, x] != 0:
                continue
            idx += 1
            stack = [(x, y)]
            labels[y, x] = idx
            area = 0
            x0 = x1 = x
            y0 = y1 = y
            while stack:
                px, py = stack.pop()
                area += 1
                x0 = min(x0, px)
                x1 = max(x1, px)
                y0 = min(y0, py)
                y1 = max(y1, py)
                for nx, ny in ((px - 1, py), (px + 1, py), (px, py - 1), (px, py + 1)):
                    if 0 <= nx < w and 0 <= ny < h and mask[ny, nx] and labels[ny, nx] == 0:
                        labels[ny, nx] = idx
                        stack.append((nx, ny))
            if area >= min_area:
                comps.append((area, idx, x0, y0, x1 - x0 + 1, y1 - y0 + 1))
    comps.sort(reverse=True)
    return labels, comps


def bbox_gap(a, b):
    _, _, ax, ay, aw, ah = a
    _, _, bx, by, bw, bh = b
    ar, ab = ax + aw, ay + ah
    br, bb = bx + bw, by + bh
    dx = max(0, bx - ar, ax - br)
    dy = max(0, by - ab, ay - bb)
    return dx, dy


def extract_cell(image: Image.Image, box, keep_near=False):
    cell = image.crop(tuple(map(int, box))).convert('RGBA')
    arr = np.array(cell)
    labels, comps = component_boxes(arr[:, :, 3], 35)
    if not comps:
        raise RuntimeError(f'no foreground in {box}')
    main = comps[0]
    keep = {main[1]}
    if keep_near:
        main_area, _, _, _, main_w, main_h = main
        for comp in comps[1:]:
            area, idx, _, _, w, h = comp
            if area < max(45, int(main_area * 0.012)):
                continue
            dx, dy = bbox_gap(main, comp)
            # Detached weapon / hose parts stay near the body. Short wide text labels do not.
            looks_like_label = h < max(12, int(main_h * 0.13)) and w > h * 2.8
            if not looks_like_label and dx <= max(75, int(main_w * 0.55)) and dy <= max(40, int(main_h * 0.16)):
                keep.add(idx)
    alpha = np.zeros(arr.shape[:2], dtype=np.uint8)
    for idx in keep:
        alpha[labels == idx] = arr[:, :, 3][labels == idx]
    arr[:, :, 3] = alpha
    ys, xs = np.nonzero(alpha > 0)
    if len(xs) == 0:
        raise RuntimeError(f'empty foreground in {box}')
    _, _, mx, my, mw, mh = main
    x0, x1 = xs.min(), xs.max() + 1
    y0, y1 = ys.min(), ys.max() + 1
    crop = Image.fromarray(arr[y0:y1, x0:x1], 'RGBA')
    main_rel = (mx - x0, my - y0, mw, mh)
    return crop, main_rel


def normalize_to_canvas(
    crop: Image.Image,
    main_rel,
    target_h=TARGET_MAIN_HEIGHT,
    canvas_size=CANVAS,
    anchor_x=ANCHOR[0],
    ground_y=ANCHOR[1],
):
    mx, my, mw, mh = main_rel
    scale = target_h / max(1, mh)
    max_w = max(1, canvas_size[0] - 14)
    max_h = max(1, ground_y - 6)
    scale = min(scale, max_w / max(1, crop.width), max_h / max(1, crop.height))
    nw = max(1, round(crop.width * scale))
    nh = max(1, round(crop.height * scale))
    resized = crop.resize((nw, nh), Image.Resampling.LANCZOS)
    main_bottom = (my + mh) * scale
    main_center_x = (mx + mw / 2) * scale
    px = round(anchor_x - main_center_x)
    py = round(ground_y - main_bottom)
    canvas = Image.new('RGBA', canvas_size, (0, 0, 0, 0))
    canvas.alpha_composite(resized, (px, py))
    return canvas


def subtle_idle(base: Image.Image, dy: int):
    out = Image.new('RGBA', CANVAS, (0, 0, 0, 0))
    out.alpha_composite(base, (0, dy))
    return out


def white_background_to_rgba(image: Image.Image):
    """Convert presentation-sheet white background to clean alpha without OCR."""
    rgb = np.array(image.convert('RGB')).astype(np.float32)
    distance = 255.0 - rgb.min(axis=2)
    alpha = np.clip((distance - 5.0) * 10.0, 0.0, 255.0)
    af = np.maximum(alpha / 255.0, 1e-4)
    foreground = (rgb - 255.0 * (1.0 - af[:, :, None])) / af[:, :, None]
    rgba = np.dstack([
        np.clip(foreground, 0, 255).astype(np.uint8),
        alpha.astype(np.uint8),
    ])
    return Image.fromarray(rgba, 'RGBA')


def _column_character_candidates(sheet_rgba: Image.Image, x0: int, x1: int, expected_rows: int):
    """Find the dominant character body in each non-uniform row for one RUN column."""
    column = sheet_rgba.crop((x0, 0, x1, sheet_rgba.height))
    alpha = np.array(column)[:, :, 3]
    _, comps = component_boxes(alpha, 120)
    min_h = max(48, int(sheet_rgba.height / expected_rows * 0.28))
    min_w = max(18, int((x1 - x0) * 0.10))
    candidates = []
    for comp in comps:
        area, _, _, y, w, h = comp
        # RUN labels are short/wide. A character body is tall and occupies meaningful area.
        if h < min_h or w < min_w:
            continue
        if w / max(1, h) > 2.2:
            continue
        candidates.append(comp)
    if len(candidates) < expected_rows:
        raise RuntimeError(
            f'authored RUN extraction found only {len(candidates)} character rows in column '
            f'{x0}:{x1}; expected {expected_rows}'
        )
    # If the sheet contains extra large decorations, keep the strongest expected_rows bodies,
    # then restore their real top-to-bottom ordering. No equal-height row slicing is used.
    candidates = sorted(candidates, key=lambda item: item[0], reverse=True)[:expected_rows]
    candidates.sort(key=lambda item: item[3] + item[5] / 2.0)
    return candidates


def build_authored_run_frames(
    source_path,
    directions=DIRECTIONS,
    canvas_size=CANVAS,
    ground_y=ANCHOR[1],
):
    """Extract 8 authored RUN frames for every direction from the presentation sheet.

    The movement sheet has non-uniform vertical row spacing, so equal H/8 row slicing is
    intentionally forbidden. Each of the eight horizontal RUN columns is analysed by
    connected components; tall character bodies establish the real row centres while
    short/wide RUN labels are ignored.
    """
    source = Image.open(source_path)
    sheet = white_background_to_rgba(source)
    width, height = sheet.size
    frame_count = 8
    row_count = len(directions)
    col_width = width / float(frame_count)

    per_column = []
    for col in range(frame_count):
        x0 = int(round(col * col_width))
        x1 = int(round((col + 1) * col_width))
        per_column.append(_column_character_candidates(sheet, x0, x1, row_count))

    result = {direction: [] for direction in directions}
    for row, direction in enumerate(directions):
        for col in range(frame_count):
            x0 = int(round(col * col_width))
            x1 = int(round((col + 1) * col_width))
            main = per_column[col][row]
            _, _, _, y, _, h = main
            pad_y = max(20, int(h * 0.18))
            y0 = max(0, y - pad_y)
            y1 = min(height, y + h + pad_y)
            crop, main_rel = extract_cell(sheet, (x0, y0, x1, y1), keep_near=True)
            frame = normalize_to_canvas(
                crop,
                main_rel,
                canvas_size=canvas_size,
                anchor_x=canvas_size[0] // 2,
                ground_y=ground_y,
            )
            result[direction].append(frame)
    return result


def clean_reference_frames():
    im = Image.open(CLEAN_SRC).convert('RGB')
    W, H = im.size
    cw = W // 4
    boxes = []
    for row in range(2):
        y0, y1 = (18, 356) if row == 0 else (397, 716)
        for col in range(4):
            boxes.append((col * cw, y0, (col + 1) * cw, y1))
    result = {}
    for direction, box in zip(DIRECTIONS, boxes):
        rgb = np.array(im.crop(box)).astype(np.float32)
        dist = 255 - rgb.min(axis=2)
        alpha = np.clip((dist - 5) * 10, 0, 255)
        af = np.maximum(alpha / 255.0, 1e-4)
        fg = (rgb - 255 * (1 - af[:, :, None])) / af[:, :, None]
        rgba = np.dstack([np.clip(fg, 0, 255).astype(np.uint8), alpha.astype(np.uint8)])
        ys, xs = np.nonzero(alpha > 16)
        x0, x1 = xs.min(), xs.max() + 1
        y0, y1 = ys.min(), ys.max() + 1
        crop = Image.fromarray(rgba[y0:y1, x0:x1], 'RGBA')
        result[direction] = normalize_to_canvas(crop, (0, 0, crop.width, crop.height))
    return result


def movement_frames():
    clean = clean_reference_frames()
    authored_run = build_authored_run_frames(
        MOVE_SRC,
        directions=DIRECTIONS,
        canvas_size=CANVAS,
        ground_y=ANCHOR[1],
    )
    result = {}
    for direction in DIRECTIONS:
        base = clean[direction]
        result[(direction, 'idle')] = [subtle_idle(base, dy) for dy in (0, -1, -2, -1)]
        result[(direction, 'run')] = authored_run[direction]
    return result


def action_frames(movement):
    im = Image.open(ACTION_SRC).convert('RGBA')
    W, H = im.size
    result = {}
    colw = W / 8.0
    fire_rows = [(72, 220), (220, 375), (375, 530)]
    for c, direction in enumerate(DIRECTIONS):
        frames = []
        for y0, y1 in fire_rows:
            box = (c * colw, y0, (c + 1) * colw, y1)
            crop, main = extract_cell(im, box, True)
            frames.append(normalize_to_canvas(crop, main))
        frames.append(movement[(direction, 'idle')][0].copy())
        result[(direction, 'fire')] = frames

    build = []
    for c in range(8):
        box = (c * colw, 555, (c + 1) * colw, 755)
        crop, main = extract_cell(im, box, False)
        build.append(normalize_to_canvas(crop, main))
    result[('generic', 'build')] = build

    hurt = []
    hurt_x1 = 930.0
    hurt_col = hurt_x1 / 6.0
    for c in range(6):
        box = (c * hurt_col, 775, (c + 1) * hurt_col, 941)
        crop, main = extract_cell(im, box, False)
        hurt.append(normalize_to_canvas(crop, main))
    result[('generic', 'hurt')] = hurt

    defeat = []
    dx0 = 930.0
    dcol = (W - dx0) / 4.0
    for c in range(4):
        box = (dx0 + c * dcol, 785, dx0 + (c + 1) * dcol, 900)
        crop, main = extract_cell(im, box, False)
        defeat.append(normalize_to_canvas(crop, main))
    result[('generic', 'defeat')] = defeat
    return result


def save_frames(movement, actions):
    for p in OUT.glob('*.png'):
        p.unlink()
    generated = {}
    for (direction, state), frames in movement.items():
        names = []
        for i, frame in enumerate(frames):
            name = f'{state}_{direction}_{i:02d}.png'
            frame.save(OUT / name)
            names.append(name)
        generated[(state, direction)] = names
    for (direction, state), frames in actions.items():
        names = []
        keydir = direction
        for i, frame in enumerate(frames):
            name = f'{state}_{keydir}_{i:02d}.png' if keydir != 'generic' else f'{state}_{i:02d}.png'
            frame.save(OUT / name)
            names.append(name)
        generated[(state, keydir)] = names
    fallback = 'front_right'
    for state in ['idle', 'run', 'fire']:
        src_names = generated[(state, fallback)]
        generic = []
        for i, name in enumerate(src_names):
            src = Image.open(OUT / name).convert('RGBA')
            outname = f'{state}_{i:02d}.png'
            src.save(OUT / outname)
            generic.append(outname)
        generated[(state, 'generic')] = generic
    build_names = generated[('build', 'generic')]
    for direction in DIRECTIONS:
        generated[('build', direction)] = build_names
    return generated


def write_spriteframes(generated):
    specs = []

    def add(name, names, loop, speed):
        specs.append((name, names, loop, speed))

    add('idle', generated[('idle', 'generic')], True, 4.5)
    add('run', generated[('run', 'generic')], True, 11.5)
    add('fire', generated[('fire', 'generic')], False, 13.0)
    add('build', generated[('build', 'generic')], False, 12.0)
    add('hurt', generated[('hurt', 'generic')], False, 11.0)
    add('defeat', generated[('defeat', 'generic')], False, 6.0)
    for direction in DIRECTIONS:
        add(f'idle_{direction}', generated[('idle', direction)], True, 4.5)
        add(f'run_{direction}', generated[('run', direction)], True, 11.5)
        add(f'fire_{direction}', generated[('fire', direction)], False, 13.0)
        add(f'build_{direction}', generated[('build', direction)], False, 12.0)

    ext = []
    blocks = []
    rid = 0
    for name, names, loop, speed in specs:
        ids = []
        for file in names:
            rid += 1
            eid = f't{rid}'
            ids.append(eid)
            ext.append(f'[ext_resource type="Texture2D" path="res://assets/runtime/characters/builder_hero/{file}" id="{eid}"]')
        fr = ', '.join(f'{{"duration": 1.0, "texture": ExtResource("{eid}")}}' for eid in ids)
        blocks.append('{\n' + f'"frames": [{fr}],\n"loop": {str(loop).lower()},\n"name": &"{name}",\n"speed": {speed:.1f}\n' + '}')
    text = '\n'.join([
        f'[gd_resource type="SpriteFrames" load_steps={rid + 1} format=3]',
        '',
        *ext,
        '',
        '[resource]',
        'animations = [',
        ', '.join(blocks),
        ']',
        '',
    ])
    (OUT / 'builder_hero_frames.tres').write_text(text, encoding='utf-8')


if __name__ == '__main__':
    movement = movement_frames()
    actions = action_frames(movement)
    generated = save_frames(movement, actions)
    write_spriteframes(generated)
    print('movement directions:', len(DIRECTIONS), 'run frames each:', len(generated[('run', 'front')]))
    print('build:', len(generated[('build', 'generic')]), 'hurt:', len(generated[('hurt', 'generic')]), 'defeat:', len(generated[('defeat', 'generic')]))
