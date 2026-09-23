class_name EnemyFrameValidator
extends RefCounted

const HeroFrameValidator = preload("res://scripts/art/hero_frame_validator.gd")
const DEFAULT_ALPHA_THRESHOLD := 0.02
const DEFAULT_GUARD_PADDING := 4

static func validate_image(
    image: Image,
    expected_size: Vector2i,
    top_margin: int = 4,
    bottom_margin: int = 4,
    side_margin: int = 4,
    max_detached_component_pixels: int = 8
) -> Dictionary:
    return HeroFrameValidator.validate_image(
        image,
        expected_size,
        top_margin,
        bottom_margin,
        side_margin,
        DEFAULT_ALPHA_THRESHOLD,
        max_detached_component_pixels,
        DEFAULT_GUARD_PADDING
    )

static func validate_sequence(
    images: Array,
    expected_size: Vector2i,
    max_anchor_drift: int = 3,
    top_margin: int = 4,
    bottom_margin: int = 4,
    side_margin: int = 4,
    max_detached_component_pixels: int = 8
) -> Dictionary:
    var errors: Array[String] = []
    var base_bottom := -1

    for index in range(images.size()):
        var image: Image = images[index]
        var result: Dictionary = validate_image(
            image,
            expected_size,
            top_margin,
            bottom_margin,
            side_margin,
            max_detached_component_pixels
        )
        if not bool(result.get("ok", false)):
            errors.append("frame_%d_invalid" % index)
            continue

        var bounds: Rect2i = result.get("bounds", Rect2i())
        var frame_bottom := bounds.position.y + bounds.size.y
        if base_bottom < 0:
            base_bottom = frame_bottom
        elif absi(frame_bottom - base_bottom) > max_anchor_drift:
            errors.append("frame_%d_anchor_drift" % index)

    return {
        "ok": errors.is_empty(),
        "errors": errors,
    }
