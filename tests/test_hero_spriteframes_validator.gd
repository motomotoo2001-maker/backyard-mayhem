extends RefCounted

const TestUtils = preload("res://tests/test_utils.gd")
const Profile = preload("res://scripts/art/hero_animation_profile.gd")

func run() -> void:
    var validator_path := "res://scripts/art/hero_spriteframes_validator.gd"
    TestUtils.assert_true(ResourceLoader.exists(validator_path), "hero SpriteFrames validator must exist")
    if not ResourceLoader.exists(validator_path):
        return

    var Validator = load(validator_path)
    var good := _build_valid_frames()
    var good_result: Dictionary = Validator.validate(good)
    TestUtils.assert_true(good_result.get("ok", false), "complete canonical Hero SpriteFrames must pass")
    TestUtils.assert_eq(good_result.get("checked_animations", 0), 56, "validator checks all 56 action/direction animations")

    var missing := _build_valid_frames()
    missing.remove_animation(&"run_front_right")
    var missing_result: Dictionary = Validator.validate(missing)
    TestUtils.assert_true(not missing_result.get("ok", true), "missing directional animation must fail")
    TestUtils.assert_true(missing_result.get("missing", PackedStringArray()).has("run_front_right"), "missing result identifies animation")

    var wrong_count := _build_valid_frames()
    wrong_count.remove_frame(&"fire_left", 3)
    var count_result: Dictionary = Validator.validate(wrong_count)
    TestUtils.assert_true(not count_result.get("ok", true), "wrong frame count must fail")
    TestUtils.assert_true(count_result.get("bad_frame_counts", PackedStringArray()).has("fire_left"), "frame-count result identifies animation")

    var wrong_speed := _build_valid_frames()
    wrong_speed.set_animation_speed(&"dash_back", 7.0)
    var speed_result: Dictionary = Validator.validate(wrong_speed)
    TestUtils.assert_true(not speed_result.get("ok", true), "wrong animation speed must fail")
    TestUtils.assert_true(speed_result.get("bad_speeds", PackedStringArray()).has("dash_back"), "speed result identifies animation")

    var wrong_loop := _build_valid_frames()
    wrong_loop.set_animation_loop(&"death_front", true)
    var loop_result: Dictionary = Validator.validate(wrong_loop)
    TestUtils.assert_true(not loop_result.get("ok", true), "wrong loop flag must fail")
    TestUtils.assert_true(loop_result.get("bad_loops", PackedStringArray()).has("death_front"), "loop result identifies animation")

    var missing_texture := _build_valid_frames()
    missing_texture.set_frame(&"idle_right", 1, null)
    var texture_result: Dictionary = Validator.validate(missing_texture)
    TestUtils.assert_true(not texture_result.get("ok", true), "null runtime frame texture must fail")
    TestUtils.assert_true(texture_result.get("missing_textures", PackedStringArray()).has("idle_right:01"), "texture result identifies frame")

func _build_valid_frames() -> SpriteFrames:
    var frames := SpriteFrames.new()
    if frames.has_animation(&"default"):
        frames.remove_animation(&"default")

    var image := Image.create(2, 2, false, Image.FORMAT_RGBA8)
    image.fill(Color.WHITE)
    var texture := ImageTexture.create_from_image(image)

    var actions: Array[StringName] = [
        &"idle", &"run", &"fire", &"build", &"hurt", &"dash", &"death"
    ]
    for action in actions:
        for direction in Profile.DIRECTIONS:
            var animation := StringName(Profile.animation_name(action, direction))
            frames.add_animation(animation)
            frames.set_animation_speed(animation, Profile.fps(action))
            frames.set_animation_loop(animation, Profile.loops(action))
            for frame_index in range(Profile.frame_count(action)):
                frames.add_frame(animation, texture)
    return frames
