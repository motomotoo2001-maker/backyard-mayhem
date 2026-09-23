extends RefCounted

const TestUtils = preload("res://tests/test_utils.gd")

func run() -> void:
    var validator_path := "res://scripts/art/enemy_frame_validator.gd"
    TestUtils.assert_true(ResourceLoader.exists(validator_path), "enemy frame validator must exist")
    if not ResourceLoader.exists(validator_path):
        return

    var Validator = load(validator_path)
    var canvas := Vector2i(64, 64)

    var clean := _make_frame(canvas, Rect2i(18, 10, 28, 48))
    var clean_result: Dictionary = Validator.validate_image(clean, canvas, 4, 4, 4, 4)
    TestUtils.assert_true(bool(clean_result.get("ok", false)), "clean transparent enemy frame passes")

    var clipped := _make_frame(canvas, Rect2i(18, 0, 28, 58))
    var clipped_result: Dictionary = Validator.validate_image(clipped, canvas, 4, 4, 4, 4)
    TestUtils.assert_true(not bool(clipped_result.get("ok", true)), "top-clipped enemy frame is rejected")

    var matte := Image.create(canvas.x, canvas.y, false, Image.FORMAT_RGBA8)
    matte.fill(Color.WHITE)
    var matte_result: Dictionary = Validator.validate_image(matte, canvas, 4, 4, 4, 4)
    TestUtils.assert_true(not bool(matte_result.get("ok", true)), "opaque white concept-sheet matte is rejected")

    var debris := _make_frame(canvas, Rect2i(18, 10, 28, 48))
    for y in range(4, 8):
        for x in range(52, 56):
            debris.set_pixel(x, y, Color.WHITE)
    var debris_result: Dictionary = Validator.validate_image(debris, canvas, 4, 4, 4, 4)
    TestUtils.assert_true(not bool(debris_result.get("ok", true)), "large detached alpha debris is rejected")

    var anchor_a := _make_frame(canvas, Rect2i(18, 10, 28, 48))
    var anchor_b := _make_frame(canvas, Rect2i(18, 5, 28, 48))
    var sequence_result: Dictionary = Validator.validate_sequence([anchor_a, anchor_b], canvas, 2, 4, 4, 4, 4)
    TestUtils.assert_true(not bool(sequence_result.get("ok", true)), "enemy sequence rejects excessive ground-anchor drift")

func _make_frame(size: Vector2i, body: Rect2i) -> Image:
    var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
    image.fill(Color.TRANSPARENT)
    for y in range(body.position.y, body.position.y + body.size.y):
        for x in range(body.position.x, body.position.x + body.size.x):
            image.set_pixel(x, y, Color.WHITE)
    return image
