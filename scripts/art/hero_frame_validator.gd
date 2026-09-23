class_name HeroFrameValidator
extends RefCounted

const DEFAULT_SIZE := Vector2i(320, 320)
const DEFAULT_TOP_MARGIN := 18
const DEFAULT_BOTTOM_MARGIN := 12
const DEFAULT_SIDE_MARGIN := 8
const DEFAULT_ALPHA_THRESHOLD := 0.02
const DEFAULT_MAX_DETACHED_COMPONENT_PIXELS := 8
const DEFAULT_DETACHED_GUARD_PADDING := 6

static func validate_image(
    image: Image,
    expected_size: Vector2i = DEFAULT_SIZE,
    top_margin: int = DEFAULT_TOP_MARGIN,
    bottom_margin: int = DEFAULT_BOTTOM_MARGIN,
    side_margin: int = DEFAULT_SIDE_MARGIN,
    alpha_threshold: float = DEFAULT_ALPHA_THRESHOLD,
    max_detached_component_pixels: int = DEFAULT_MAX_DETACHED_COMPONENT_PIXELS,
    detached_guard_padding: int = DEFAULT_DETACHED_GUARD_PADDING
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

    # Runtime hero sprites should contain one primary character silhouette.
    # Small isolated export/antialias specks are tolerated, but larger islands
    # sitting away from the character usually mean labels, crop debris, or a
    # projectile/VFX element was accidentally baked into the frame.
    var components: Array = _find_alpha_components(image, alpha_threshold)
    var detached_pixels := 0
    var detached_components := 0
    if components.size() > 1:
        var main_index := 0
        var main_pixels := int(components[0].get("pixels", 0))
        for index in range(1, components.size()):
            var pixels := int(components[index].get("pixels", 0))
            if pixels > main_pixels:
                main_pixels = pixels
                main_index = index

        var main_bounds: Rect2i = components[main_index].get("bounds", Rect2i())
        var guard := Vector2i(detached_guard_padding, detached_guard_padding)
        var guarded_main := Rect2i(
            main_bounds.position - guard,
            main_bounds.size + guard * 2
        )

        for index in range(components.size()):
            if index == main_index:
                continue
            var component: Dictionary = components[index]
            var pixels := int(component.get("pixels", 0))
            var component_bounds: Rect2i = component.get("bounds", Rect2i())
            detached_pixels += pixels
            if pixels > max_detached_component_pixels and not guarded_main.intersects(component_bounds):
                detached_components += 1

        if detached_components > 0:
            errors.append("detached_alpha_artifact")

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
        "component_count": components.size(),
        "detached_component_count": detached_components,
        "detached_pixel_count": detached_pixels,
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

static func _find_alpha_components(image: Image, alpha_threshold: float) -> Array:
    var width := image.get_width()
    var height := image.get_height()
    var visited := PackedByteArray()
    visited.resize(width * height)
    var components: Array = []
    var neighbors := [
        Vector2i(1, 0),
        Vector2i(-1, 0),
        Vector2i(0, 1),
        Vector2i(0, -1),
    ]

    for y in range(height):
        for x in range(width):
            var start_index := y * width + x
            if visited[start_index] != 0:
                continue
            visited[start_index] = 1
            if image.get_pixel(x, y).a <= alpha_threshold:
                continue

            var stack: Array[Vector2i] = [Vector2i(x, y)]
            var pixel_count := 0
            var min_x := x
            var min_y := y
            var max_x := x
            var max_y := y

            while not stack.is_empty():
                var point: Vector2i = stack.pop_back()
                pixel_count += 1
                min_x = mini(min_x, point.x)
                min_y = mini(min_y, point.y)
                max_x = maxi(max_x, point.x)
                max_y = maxi(max_y, point.y)

                for offset in neighbors:
                    var next := point + offset
                    if next.x < 0 or next.y < 0 or next.x >= width or next.y >= height:
                        continue
                    var next_index := next.y * width + next.x
                    if visited[next_index] != 0:
                        continue
                    visited[next_index] = 1
                    if image.get_pixel(next.x, next.y).a > alpha_threshold:
                        stack.append(next)

            components.append({
                "pixels": pixel_count,
                "bounds": Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1),
            })

    return components
