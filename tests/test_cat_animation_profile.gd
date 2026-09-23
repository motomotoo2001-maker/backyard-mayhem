extends RefCounted

const TestUtils = preload("res://tests/test_utils.gd")

func run() -> void:
    var path := "res://scripts/art/cat_animation_profile.gd"
    if not ResourceLoader.exists(path):
        TestUtils.failures.append("cat animation profile must exist")
        return

    var script_resource = load(path)
    if script_resource == null or not script_resource is Script:
        TestUtils.failures.append("cat animation profile must load as Script")
        return

    var script: Script = script_resource as Script
    if not script.can_instantiate():
        TestUtils.failures.append("cat animation profile must instantiate")
        return

    TestUtils.assert_eq(script.CANVAS_SIZE, Vector2i(256, 256), "cat runtime frames should use 256x256 canvas")
    TestUtils.assert_eq(script.GROUND_ANCHOR, Vector2i(128, 238), "cat ground anchor should remain bottom-center")
    TestUtils.assert_true(script.ALLOW_HORIZONTAL_FLIP, "cat should use horizontal flip for mirrored facing")

    var actions: Array = script.actions()
    TestUtils.assert_eq(actions.size(), 5, "cat should define five canonical actions")
    for action in [&"idle", &"run", &"attack", &"hurt", &"death"]:
        TestUtils.assert_true(actions.has(action), "cat action %s must exist" % action)

    TestUtils.assert_eq(script.frame_count(&"idle"), 4, "cat idle should use four frames")
    TestUtils.assert_near(script.fps(&"idle"), 7.0, 0.001, "cat idle should use 7 FPS")
    TestUtils.assert_true(script.loops(&"idle"), "cat idle should loop")

    TestUtils.assert_eq(script.frame_count(&"run"), 8, "cat run should use eight frames")
    TestUtils.assert_near(script.fps(&"run"), 14.0, 0.001, "cat run should feel faster than raccoon")
    TestUtils.assert_true(script.loops(&"run"), "cat run should loop")

    TestUtils.assert_eq(script.frame_count(&"attack"), 6, "cat pounce should use six frames")
    TestUtils.assert_near(script.fps(&"attack"), 14.0, 0.001, "cat attack should use 14 FPS")
    TestUtils.assert_true(not script.loops(&"attack"), "cat attack should be one-shot")
    TestUtils.assert_eq(script.event_frame(&"attack", &"hit"), 3, "cat pounce hit should land on frame 3")

    TestUtils.assert_eq(script.frame_count(&"hurt"), 3, "cat hurt should use three frames")
    TestUtils.assert_near(script.fps(&"hurt"), 13.0, 0.001, "cat hurt should be snappy")
    TestUtils.assert_true(not script.loops(&"hurt"), "cat hurt should be one-shot")

    TestUtils.assert_eq(script.frame_count(&"death"), 6, "cat death should use six frames")
    TestUtils.assert_near(script.fps(&"death"), 10.0, 0.001, "cat death should use 10 FPS")
    TestUtils.assert_true(not script.loops(&"death"), "cat death should be one-shot")

    TestUtils.assert_eq(script.total_frames(), 27, "cat production set should contain 27 frames")
    TestUtils.assert_eq(script.frame_count(&"unknown"), 0, "unknown cat action should have zero frames")
