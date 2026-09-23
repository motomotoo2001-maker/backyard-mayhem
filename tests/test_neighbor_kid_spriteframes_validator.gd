extends RefCounted

const TestUtils = preload("res://tests/test_utils.gd")
const Profile = preload("res://scripts/art/neighbor_kid_animation_profile.gd")

func run() -> void:
    var validator_path := "res://scripts/art/neighbor_kid_spriteframes_validator.gd"
    if not ResourceLoader.exists(validator_path):
        TestUtils.failures.append("neighbor kid SpriteFrames validator must exist")
        return

    var Validator = load(validator_path)
    var good := _build_valid_frames()
    var good_result: Dictionary = Validator.validate(good)
    TestUtils.assert_true(good_result.get("ok", false), "complete canonical neighbor kid SpriteFrames must pass")
    TestUtils.assert_eq(good_result.get("checked_animations", 0), 5, "validator checks all five neighbor kid animations")

    var missing := _build_valid_frames()
    missing.remove_animation(&"attack")
    var missing_result: Dictionary = Validator.validate(missing)
    TestUtils.assert_true(not missing_result.get("ok", true), "missing neighbor kid animation must fail")
    TestUtils.assert_true(missing_result.get("missing", PackedStringArray()).has("attack"), "missing result identifies neighbor kid animation")

    var wrong_count := _build_valid_frames()
    wrong_count.remove_frame(&"run", 7)
    var count_result: Dictionary = Validator.validate(wrong_count)
    TestUtils.assert_true(not count_result.get("ok", true), "wrong neighbor kid frame count must fail")
    TestUtils.assert_true(count_result.get("bad_frame_counts", PackedStringArray()).has("run"), "frame-count result identifies neighbor kid animation")

    var wrong_speed := _build_valid_frames()
    wrong_speed.set_animation_speed(&"attack", 15.0)
    var speed_result: Dictionary = Validator.validate(wrong_speed)
    TestUtils.assert_true(not speed_result.get("ok", true), "wrong neighbor kid animation speed must fail")
    TestUtils.assert_true(speed_result.get("bad_speeds", PackedStringArray()).has("attack"), "speed result identifies neighbor kid animation")

    var wrong_loop := _build_valid_frames()
    wrong_loop.set_animation_loop(&"death", true)
    var loop_result: Dictionary = Validator.validate(wrong_loop)
    TestUtils.assert_true(not loop_result.get("ok", true), "wrong neighbor kid loop flag must fail")
    TestUtils.assert_true(loop_result.get("bad_loops", PackedStringArray()).has("death"), "loop result identifies neighbor kid animation")

    var missing_texture := _build_valid_frames()
    missing_texture.set_frame(&"hurt", 1, null)
    var texture_result: Dictionary = Validator.validate(missing_texture)
    TestUtils.assert_true(not texture_result.get("ok", true), "null neighbor kid runtime texture must fail")
    TestUtils.assert_true(texture_result.get("missing_textures", PackedStringArray()).has("hurt:01"), "texture result identifies neighbor kid frame")

func _build_valid_frames() -> SpriteFrames:
    var frames := SpriteFrames.new()
    if frames.has_animation(&"default"):
        frames.remove_animation(&"default")

    var image := Image.create(2, 2, false, Image.FORMAT_RGBA8)
    image.fill(Color.WHITE)
    var texture := ImageTexture.create_from_image(image)

    for action in Profile.actions():
        frames.add_animation(action)
        frames.set_animation_speed(action, Profile.fps(action))
        frames.set_animation_loop(action, Profile.loops(action))
        for frame_index in range(Profile.frame_count(action)):
            frames.add_frame(action, texture)
    return frames
