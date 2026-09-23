extends RefCounted

const TestUtils = preload("res://tests/test_utils.gd")

func run() -> void:
    var path := "res://scripts/art/skateboard_teen_animation_profile.gd"
    if not ResourceLoader.exists(path):
        TestUtils.failures.append("skateboard teen animation profile must exist")
        return

    var script_resource = load(path)
    if script_resource == null or not script_resource is Script:
        TestUtils.failures.append("skateboard teen animation profile must load as Script")
        return

    var script: Script = script_resource as Script
    if not script.can_instantiate():
        TestUtils.failures.append("skateboard teen animation profile must instantiate")
        return

    TestUtils.assert_eq(script.CANVAS_SIZE, Vector2i(288, 320), "skateboard teen should use a tall humanoid runtime canvas")
    TestUtils.assert_eq(script.GROUND_ANCHOR, Vector2i(144, 300), "skateboard teen wheel/foot anchor should remain stable")
    TestUtils.assert_true(script.ALLOW_HORIZONTAL_FLIP, "skateboard teen should use horizontal flip for mirrored facing")

    var actions: Array = script.actions()
    TestUtils.assert_eq(actions.size(), 5, "skateboard teen should define five canonical actions")
    for action in [&"idle", &"run", &"attack", &"hurt", &"death"]:
        TestUtils.assert_true(actions.has(action), "skateboard teen action %s must exist" % action)

    TestUtils.assert_eq(script.frame_count(&"idle"), 4, "skateboard teen idle should use four frames")
    TestUtils.assert_near(script.fps(&"idle"), 7.0, 0.001, "skateboard teen idle should use 7 FPS")
    TestUtils.assert_true(script.loops(&"idle"), "skateboard teen idle should loop")

    TestUtils.assert_eq(script.frame_count(&"run"), 8, "skateboard teen ride/run should use eight frames")
    TestUtils.assert_near(script.fps(&"run"), 15.0, 0.001, "skateboard teen movement should feel very fast")
    TestUtils.assert_true(script.loops(&"run"), "skateboard teen movement should loop")

    TestUtils.assert_eq(script.frame_count(&"attack"), 6, "skateboard teen ram/kick attack should use six frames")
    TestUtils.assert_near(script.fps(&"attack"), 14.0, 0.001, "skateboard teen attack should use 14 FPS")
    TestUtils.assert_true(not script.loops(&"attack"), "skateboard teen attack should be one-shot")
    TestUtils.assert_eq(script.event_frame(&"attack", &"hit"), 3, "skateboard teen attack should hit on frame 3")

    TestUtils.assert_eq(script.frame_count(&"hurt"), 3, "skateboard teen hurt should use three frames")
    TestUtils.assert_near(script.fps(&"hurt"), 13.0, 0.001, "skateboard teen hurt should be snappy")
    TestUtils.assert_true(not script.loops(&"hurt"), "skateboard teen hurt should be one-shot")

    TestUtils.assert_eq(script.frame_count(&"death"), 7, "skateboard teen wipeout death should use seven frames")
    TestUtils.assert_near(script.fps(&"death"), 10.0, 0.001, "skateboard teen death should use 10 FPS")
    TestUtils.assert_true(not script.loops(&"death"), "skateboard teen death should be one-shot")

    TestUtils.assert_eq(script.total_frames(), 28, "skateboard teen production set should contain 28 frames")
    TestUtils.assert_eq(script.frame_count(&"unknown"), 0, "unknown skateboard teen action should have zero frames")
