extends RefCounted

const TestUtils = preload("res://tests/test_utils.gd")

func run() -> void:
    var profile_path := "res://scripts/art/hero_animation_profile.gd"
    TestUtils.assert_true(ResourceLoader.exists(profile_path), "hero animation profile must exist")
    if not ResourceLoader.exists(profile_path):
        return

    var Profile = load(profile_path)

    TestUtils.assert_eq(Profile.DIRECTIONS.size(), 8, "hero must use 8 directions")
    TestUtils.assert_eq(Profile.DIRECTIONS[0], "front", "direction order starts at front")
    TestUtils.assert_eq(Profile.DIRECTIONS[1], "front_right", "front-right direction must be second")
    TestUtils.assert_eq(Profile.DIRECTIONS[7], "front_left", "direction order ends at front-left")

    TestUtils.assert_eq(Profile.frame_count(&"idle"), 4, "idle frame count")
    TestUtils.assert_eq(Profile.frame_count(&"run"), 8, "run frame count")
    TestUtils.assert_eq(Profile.frame_count(&"fire"), 4, "fire frame count")
    TestUtils.assert_eq(Profile.frame_count(&"build"), 6, "build frame count")
    TestUtils.assert_eq(Profile.frame_count(&"hurt"), 3, "hurt frame count")
    TestUtils.assert_eq(Profile.frame_count(&"dash"), 4, "dash frame count")
    TestUtils.assert_eq(Profile.frame_count(&"death"), 6, "death frame count")

    TestUtils.assert_eq(Profile.fps(&"idle"), 5.0, "idle FPS")
    TestUtils.assert_eq(Profile.fps(&"run"), 12.0, "run FPS")
    TestUtils.assert_eq(Profile.fps(&"fire"), 14.0, "fire FPS")
    TestUtils.assert_eq(Profile.fps(&"dash"), 18.0, "dash FPS")

    TestUtils.assert_true(Profile.loops(&"idle"), "idle must loop")
    TestUtils.assert_true(Profile.loops(&"run"), "run must loop")
    TestUtils.assert_true(not Profile.loops(&"fire"), "fire must not loop")
    TestUtils.assert_true(not Profile.loops(&"death"), "death must not loop")

    TestUtils.assert_eq(Profile.frame_name(&"run", "front_right", 3), "run_front_right_03.png", "frame naming must be deterministic")
    TestUtils.assert_eq(Profile.animation_name(&"fire", "back_left"), "fire_back_left", "animation naming must be deterministic")
    TestUtils.assert_eq(Profile.total_required_frames(), 280, "full hero set must contain 280 frames")
