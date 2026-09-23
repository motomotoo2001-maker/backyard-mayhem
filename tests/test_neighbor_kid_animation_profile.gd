extends RefCounted

const TestUtils = preload("res://tests/test_utils.gd")

func run() -> void:
    var path := "res://scripts/art/neighbor_kid_animation_profile.gd"
    if not ResourceLoader.exists(path):
        TestUtils.failures.append("neighbor kid animation profile must exist")
        return

    var script_resource = load(path)
    if script_resource == null or not script_resource is Script:
        TestUtils.failures.append("neighbor kid animation profile must load as Script")
        return

    var script: Script = script_resource as Script
    if not script.can_instantiate():
        TestUtils.failures.append("neighbor kid animation profile must instantiate")
        return

    TestUtils.assert_eq(script.CANVAS_SIZE, Vector2i(288, 320), "neighbor kid should use a taller humanoid runtime canvas")
    TestUtils.assert_eq(script.GROUND_ANCHOR, Vector2i(144, 300), "neighbor kid foot anchor should remain stable")
    TestUtils.assert_true(script.ALLOW_HORIZONTAL_FLIP, "neighbor kid should use horizontal flip for mirrored facing")

    var actions: Array = script.actions()
    TestUtils.assert_eq(actions.size(), 5, "neighbor kid should define five canonical actions")
    for action in [&"idle", &"run", &"attack", &"hurt", &"death"]:
        TestUtils.assert_true(actions.has(action), "neighbor kid action %s must exist" % action)

    TestUtils.assert_eq(script.frame_count(&"idle"), 4, "neighbor kid idle should use four frames")
    TestUtils.assert_near(script.fps(&"idle"), 5.0, 0.001, "neighbor kid idle should use 5 FPS")
    TestUtils.assert_true(script.loops(&"idle"), "neighbor kid idle should loop")

    TestUtils.assert_eq(script.frame_count(&"run"), 8, "neighbor kid run should use eight frames")
    TestUtils.assert_near(script.fps(&"run"), 10.0, 0.001, "neighbor kid run should use 10 FPS")
    TestUtils.assert_true(script.loops(&"run"), "neighbor kid run should loop")

    TestUtils.assert_eq(script.frame_count(&"attack"), 6, "neighbor kid ranged attack should use six frames")
    TestUtils.assert_near(script.fps(&"attack"), 11.0, 0.001, "neighbor kid ranged attack should use 11 FPS")
    TestUtils.assert_true(not script.loops(&"attack"), "neighbor kid attack should be one-shot")
    TestUtils.assert_eq(script.event_frame(&"attack", &"projectile_release"), 3, "neighbor kid projectile should release on frame 3")

    TestUtils.assert_eq(script.frame_count(&"hurt"), 3, "neighbor kid hurt should use three frames")
    TestUtils.assert_near(script.fps(&"hurt"), 11.0, 0.001, "neighbor kid hurt should be readable but snappy")
    TestUtils.assert_true(not script.loops(&"hurt"), "neighbor kid hurt should be one-shot")

    TestUtils.assert_eq(script.frame_count(&"death"), 6, "neighbor kid death should use six frames")
    TestUtils.assert_near(script.fps(&"death"), 8.0, 0.001, "neighbor kid death should use 8 FPS")
    TestUtils.assert_true(not script.loops(&"death"), "neighbor kid death should be one-shot")

    TestUtils.assert_eq(script.total_frames(), 27, "neighbor kid production set should contain 27 frames")
    TestUtils.assert_eq(script.frame_count(&"unknown"), 0, "unknown neighbor kid action should have zero frames")
