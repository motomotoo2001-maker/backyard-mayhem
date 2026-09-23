extends RefCounted

const TestUtils = preload("res://tests/test_utils.gd")

func run() -> void:
    var path := "res://scripts/art/raccoon_animation_profile.gd"
    if not ResourceLoader.exists(path):
        TestUtils.failures.append("raccoon animation profile must exist")
        return

    var script_resource = load(path)
    if script_resource == null or not script_resource is Script:
        TestUtils.failures.append("raccoon animation profile must load as Script")
        return

    var script: Script = script_resource as Script
    if not script.can_instantiate():
        TestUtils.failures.append("raccoon animation profile must instantiate")
        return

    TestUtils.assert_eq(script.CANVAS_SIZE, Vector2i(256, 256), "raccoon runtime frames should use 256x256 canvas")
    TestUtils.assert_eq(script.GROUND_ANCHOR, Vector2i(128, 236), "raccoon ground anchor should be bottom-center and stable")
    TestUtils.assert_true(script.ALLOW_HORIZONTAL_FLIP, "raccoon should support horizontal flip instead of duplicate mirrored art")

    var actions: Array = script.actions()
    TestUtils.assert_eq(actions.size(), 5, "raccoon should define five canonical actions")
    for action in [&"idle", &"run", &"attack", &"hurt", &"death"]:
        TestUtils.assert_true(actions.has(action), "raccoon action %s must exist" % action)

    TestUtils.assert_eq(script.frame_count(&"idle"), 4, "raccoon idle should use four frames")
    TestUtils.assert_near(script.fps(&"idle"), 6.0, 0.001, "raccoon idle should run at 6 FPS")
    TestUtils.assert_true(script.loops(&"idle"), "raccoon idle should loop")

    TestUtils.assert_eq(script.frame_count(&"run"), 8, "raccoon run should use eight frames")
    TestUtils.assert_near(script.fps(&"run"), 12.0, 0.001, "raccoon run should run at 12 FPS")
    TestUtils.assert_true(script.loops(&"run"), "raccoon run should loop")

    TestUtils.assert_eq(script.frame_count(&"attack"), 6, "raccoon attack should use six frames")
    TestUtils.assert_near(script.fps(&"attack"), 12.0, 0.001, "raccoon attack should run at 12 FPS")
    TestUtils.assert_true(not script.loops(&"attack"), "raccoon attack should be one-shot")
    TestUtils.assert_eq(script.event_frame(&"attack", &"hit"), 3, "raccoon hit should land on attack frame 3")

    TestUtils.assert_eq(script.frame_count(&"hurt"), 3, "raccoon hurt should use three frames")
    TestUtils.assert_near(script.fps(&"hurt"), 12.0, 0.001, "raccoon hurt should run at 12 FPS")
    TestUtils.assert_true(not script.loops(&"hurt"), "raccoon hurt should be one-shot")

    TestUtils.assert_eq(script.frame_count(&"death"), 6, "raccoon death should use six frames")
    TestUtils.assert_near(script.fps(&"death"), 9.0, 0.001, "raccoon death should run at 9 FPS")
    TestUtils.assert_true(not script.loops(&"death"), "raccoon death should be one-shot")

    TestUtils.assert_eq(script.total_frames(), 27, "raccoon production set should contain 27 frames")
    TestUtils.assert_eq(script.frame_count(&"unknown"), 0, "unknown raccoon action should have zero frames")
