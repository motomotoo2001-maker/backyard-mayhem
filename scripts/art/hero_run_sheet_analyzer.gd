class_name HeroRunSheetAnalyzer
extends RefCounted

const DEFAULT_WHITE_THRESHOLD := 0.96
const DEFAULT_ALPHA_THRESHOLD := 0.05
const DEFAULT_ROW_GAP_TOLERANCE := 2

static func find_character_bands(
    image: Image,
    min_row_ink: int = 12,
    min_band_height: int = 24,
    white_threshold: float = DEFAULT_WHITE_THRESHOLD
) -> Array[Rect2i]:
    var active_rows: Array[bool] = []
    active_rows.resize(image.get_height())

    for y in range(image.get_height()):
        var ink_count := 0
        for x in range(image.get_width()):
            if _is_foreground(image.get_pixel(x, y), white_threshold):
                ink_count += 1
        active_rows[y] = ink_count >= min_row_ink

    var row_segments := _segments_from_activity(active_rows, DEFAULT_ROW_GAP_TOLERANCE)
    var bands: Array[Rect2i] = []
    for segment in row_segments:
        var y0 := segment.x
        var y1 := segment.y
        if y1 - y0 + 1 < min_band_height:
            continue
        var bounds := _foreground_bounds(image, Rect2i(0, y0, image.get_width(), y1 - y0 + 1), white_threshold)
        if bounds.size.x > 0 and bounds.size.y > 0:
            bands.append(bounds)
    return bands

static func find_frame_boxes(
    image: Image,
    band: Rect2i,
    min_vertical_coverage: float = 0.22,
    min_frame_width: int = 16,
    max_internal_gap: int = 8,
    white_threshold: float = DEFAULT_WHITE_THRESHOLD
) -> Array[Rect2i]:
    var clipped := band.intersection(Rect2i(0, 0, image.get_width(), image.get_height()))
    if clipped.size.x <= 0 or clipped.size.y <= 0:
        return []

    var active_columns: Array[bool] = []
    active_columns.resize(clipped.size.x)
    var required_ink := maxi(1, int(ceil(float(clipped.size.y) * min_vertical_coverage)))

    for local_x in range(clipped.size.x):
        var x := clipped.position.x + local_x
        var ink_count := 0
        for y in range(clipped.position.y, clipped.end.y):
            if _is_foreground(image.get_pixel(x, y), white_threshold):
                ink_count += 1
        active_columns[local_x] = ink_count >= required_ink

    var column_segments := _segments_from_activity(active_columns, max_internal_gap)
    var frames: Array[Rect2i] = []
    for segment in column_segments:
        var local_x0 := segment.x
        var local_x1 := segment.y
        if local_x1 - local_x0 + 1 < min_frame_width:
            continue
        var search_rect := Rect2i(
            clipped.position.x + local_x0,
            clipped.position.y,
            local_x1 - local_x0 + 1,
            clipped.size.y
        )
        var bounds := _foreground_bounds(image, search_rect, white_threshold)
        if bounds.size.x >= min_frame_width and bounds.size.y > 0:
            frames.append(bounds)
    return frames

static func _segments_from_activity(activity: Array[bool], max_gap: int) -> Array[Vector2i]:
    var segments: Array[Vector2i] = []
    var start := -1
    var last_active := -1

    for index in range(activity.size()):
        if activity[index]:
            if start < 0:
                start = index
            last_active = index
        elif start >= 0 and index - last_active - 1 > max_gap:
            segments.append(Vector2i(start, last_active))
            start = -1
            last_active = -1

    if start >= 0:
        segments.append(Vector2i(start, last_active))
    return segments

static func _foreground_bounds(image: Image, rect: Rect2i, white_threshold: float) -> Rect2i:
    var min_x := rect.end.x
    var min_y := rect.end.y
    var max_x := -1
    var max_y := -1

    for y in range(rect.position.y, rect.end.y):
        for x in range(rect.position.x, rect.end.x):
            if not _is_foreground(image.get_pixel(x, y), white_threshold):
                continue
            min_x = mini(min_x, x)
            min_y = mini(min_y, y)
            max_x = maxi(max_x, x)
            max_y = maxi(max_y, y)

    if max_x < min_x or max_y < min_y:
        return Rect2i()
    return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)

static func _is_foreground(color: Color, white_threshold: float) -> bool:
    if color.a <= DEFAULT_ALPHA_THRESHOLD:
        return false
    return not (
        color.r >= white_threshold
        and color.g >= white_threshold
        and color.b >= white_threshold
    )
