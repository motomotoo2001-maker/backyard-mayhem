extends RefCounted

const TestUtils = preload("res://tests/test_utils.gd")
const Profile = preload("res://scripts/art/water_vfx_sequence_profile.gd")

func run() -> void:
    var validator_path := "res://scripts/art/water_vfx_spriteframes_validator.gd"
    if not ResourceLoader.exists(validator_path):
        TestUtils.failures.append("water VFX SpriteFrames validator must exist")
        return

    var Validator = load(validator_path)
    var good := _build_valid_frames()
    var good_result: Dictionary = Validator.validate(good)
    TestUtils.assert_true(good_result.get("ok", false), "complete canonical Water VFX SpriteFrames must pass")
    TestUtils.assert_eq(good_result.get("checked_animations", 0), 6, "validator checks all six water animations")

    var missing := _build_valid_frames()
    missing.remove_animation(&"splash")
    var missing_result: Dictionary = Validator.validate(missing)
    TestUtils.assert_true(not missing_result.get("ok", true), "missing water animation must fail")
    TestUtils.assert_true(missing_result.get("missing", PackedStringArray()).has("splash"), "missing result identifies water animation")

    var wrong_count := _build_valid_frames()
    wrong_count.remove_frame(&"impact", 4)
    var count_result: Dictionary = Validator.validate(wrong_count)
    TestUtils.assert_true(not count_result.get("ok", true), "wrong water frame count must fail")
    TestUtils.assert_true(count_result.get("bad_frame_counts", PackedStringArray()).has("impact"), "frame-count result identifies water animation")

    var wrong_speed := _build_valid_frames()
    wrong_speed.set_animation_speed(&"stream", 7.0)
    var speed_result: Dictionary = Validator.validate(wrong_speed)
    TestUtils.assert_true(not speed_result.get("ok", true), "wrong water animation speed must fail")
    TestUtils.assert_true(speed_result.get("bad_speeds", PackedStringArray()).has("stream"), "speed result identifies water animation")

    var wrong_loop := _build_valid_frames()
    wrong_loop.set_animation_loop(&"splash", true)
    var loop_result: Dictionary = Validator.validate(wrong_loop)
    TestUtils.assert_true(not loop_result.get("ok", true), "wrong water loop flag must fail")
    TestUtils.assert_true(loop_result.get("bad_loops", PackedStringArray()).has("splash"), "loop result identifies water animation")

    var missing_texture := _build_valid_frames()
    missing_texture.set_frame(&"foam", 2, null)
    var texture_result: Dictionary = Validator.validate(missing_texture)
    TestUtils.assert_true(not texture_result.get("ok", true), "null water runtime texture must fail")
    TestUtils.assert_true(texture_result.get("missing_textures", PackedStringArray()).has("foam:02"), "texture result identifies water frame")

func _build_valid_frames() -> SpriteFrames:
    var frames := SpriteFrames.new()
    if frames.has_animation(&"default"):
        frames.remove_animation(&"default")

    var image := Image.create(2, 2, false, Image.FORMAT_RGBA8)
    image.fill(Color.WHITE)
    var texture := ImageTexture.create_from_image(image)

    for kind in Profile.kinds():
        frames.add_animation(kind)
        frames.set_animation_speed(kind, Profile.fps(kind))
        frames.set_animation_loop(kind, Profile.loops(kind))
        for frame_index in range(Profile.frame_count(kind)):
            frames.add_frame(kind, texture)
    return frames
