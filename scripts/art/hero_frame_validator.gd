class_name HeroFrameValidator
extends RefCounted

const DEFAULT_SIZE := Vector2i(320, 320)
const DEFAULT_TOP_MARGIN := 18
const DEFAULT_BOTTOM_MARGIN := 12
const DEFAULT_SIDE_MARGIN := 8
const DEFAULT_ALPHA_THRESHOLD := 0.02

static func validate_image(
    image: Image,
    expected_size: Vector2i = DEFAULT_SIZE,
    top_margin: int = DEFAULT_TOP_MARGIN,
    bottom_margin: int = DEFAULT_BOTTOM_MARGIN,
    side_margin: int = DEFAULT_SIDE_MARGIN,
    alpha_threshold: float = DEFAULT_ALPHA_THRESHOLD
) -> Dictionary:
    var errors: Array[String] = []
    if image == null:
        errors.append("image_is_null")
        return {"ok": false, "errors": errors, "bounds": Rect2i()}

    if image.get_size() != expected_size:
        errors.append("invalid_canvas_size")

    var scan := _find_alpha_bounds(image, alpha_threshold)
    if not scan.found:
        errors.append("empty_alpha")
        return {"ok": false, "errors": errors, "bounds": Rect2i()}

    var bounds: Rect2i = scan.bounds
    var image_size := image.get_size()
    var left := bounds.position.x
    var top := bounds.position.y
    var right := image_size.x - (bounds.position.x + bounds.size.x)
    var bottom := image_size.y - (bounds.position.y + bounds.size.y)

    if top < top_margin:
        errors.append("top_margin_too_small")
    if bottom < bottom_margin:
        errors.append("bottom_margin_too_small")
    if left < side_margin:
        errors.append("left_margin_too_small")
    if right < side_margin:
        errors.append("right_margin_too_small")

    return {
        "ok": errors.is_empty(),
        "errors": errors,
        "bounds": bounds,
        "margins": {
            "top": top,
            "bottom": bottom,
            "left": left,
            "right": right,
        },
    }

static func validate_sequence(images: Array, max_anchor_drift: int = 3) -> Dictionary:
    var errors: Array[String] = []
    var base_bottom := -1

    for index in range(images.size()):
        var image: Image = images[index]
        var result := validate_image(image)
        if not result.ok:
            errors.append("frame_%d_invalid" % index)
            continue

        var bounds: Rect2i = result.bounds
        var frame_bottom := bounds.position.y + bounds.size.y
        if base_bottom < 0:
            base_bottom = frame_bottom
        elif absi(frame_bottom - base_bottom) > max_anchor_drift:
            errors.append("frame_%d_anchor_drift" % index)

    return {
        "ok": errors.is_empty(),
        "errors": errors,
    }

static func _find_alpha_bounds(image: Image, alpha_threshold: float) -> Dictionary:
    var min_x := image.get_width()
    var min_y := image.get_height()
    var max_x := -1
    var max_y := -1

    for y in range(image.get_height()):
        for x in range(image.get_width()):
            if image.get_pixel(x, y).a <= alpha_threshold:
                continue
            min_x = mini(min_x, x)
            min_y = mini(min_y, y)
            max_x = maxi(max_x, x)
            max_y = maxi(max_y, y)

    if max_x < 0 or max_y < 0:
        return {"found": false, "bounds": Rect2i()}

    return {
        "found": true,
        "bounds": Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1),
    }
