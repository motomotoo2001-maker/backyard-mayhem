extends RefCounted

const TestUtils = preload("res://tests/test_utils.gd")

func run() -> void:
    var path := "res://scripts/art/boss_animation_profile.gd"
    if not ResourceLoader.exists(path):
        TestUtils.failures.append("boss animation profile must exist")
        return

    var script_resource = load(path)
    if script_resource == null or not script_resource is Script:
        TestUtils.failures.append("boss animation profile must load as Script")
        return

    var script: Script = script_resource as Script
    if not script.can_instantiate():
        TestUtils.failures.append("boss animation profile must instantiate")
        return

    TestUtils.assert_eq(script.CANVAS_SIZE, Vector2i(384, 384), "boss should use a large runtime canvas")
    TestUtils.assert_eq(script.GROUND_ANCHOR, Vector2i(192, 356), "boss ground anchor should remain stable")
    TestUtils.assert_true(script.ALLOW_HORIZONTAL_FLIP, "boss may mirror horizontal facing")

    var actions: Array = script.actions()
    TestUtils.assert_eq(actions.size(), 6, "boss should define six canonical actions")
    for action in [&"idle", &"run", &"heavy_swing", &"radial_slam", &"hurt", &"death"]:
        TestUtils.assert_true(actions.has(action), "boss action %s must exist" % action)

    TestUtils.assert_eq(script.frame_count(&"idle"), 4, "boss idle should use four frames")
    TestUtils.assert_near(script.fps(&"idle"), 4.5, 0.001, "boss idle should feel heavy")
    TestUtils.assert_true(script.loops(&"idle"), "boss idle should loop")

    TestUtils.assert_eq(script.frame_count(&"run"), 8, "boss run should use eight frames")
    TestUtils.assert_near(script.fps(&"run"), 7.0, 0.001, "boss movement should stay weighty")
    TestUtils.assert_true(script.loops(&"run"), "boss run should loop")

    TestUtils.assert_eq(script.frame_count(&"heavy_swing"), 8, "heavy swing should use eight frames")
    TestUtils.assert_near(script.fps(&"heavy_swing"), 9.0, 0.001, "heavy swing should use 9 FPS")
    TestUtils.assert_true(not script.loops(&"heavy_swing"), "heavy swing should be one-shot")
    TestUtils.assert_eq(script.event_frame(&"heavy_swing", &"hit"), 5, "heavy swing should connect on frame 5")

    TestUtils.assert_eq(script.frame_count(&"radial_slam"), 10, "radial slam should use ten frames")
    TestUtils.assert_near(script.fps(&"radial_slam"), 10.0, 0.001, "radial slam should use 10 FPS")
    TestUtils.assert_true(not script.loops(&"radial_slam"), "radial slam should be one-shot")
    TestUtils.assert_eq(script.event_frame(&"radial_slam", &"impact"), 7, "radial slam should impact on frame 7")

    TestUtils.assert_eq(script.frame_count(&"hurt"), 3, "boss hurt should use three frames")
    TestUtils.assert_near(script.fps(&"hurt"), 8.0, 0.001, "boss hurt should remain readable")
    TestUtils.assert_true(not script.loops(&"hurt"), "boss hurt should be one-shot")

    TestUtils.assert_eq(script.frame_count(&"death"), 8, "boss death should use eight frames")
    TestUtils.assert_near(script.fps(&"death"), 7.0, 0.001, "boss death should have a weighty finish")
    TestUtils.assert_true(not script.loops(&"death"), "boss death should be one-shot")

    TestUtils.assert_eq(script.total_frames(), 41, "boss production set should contain 41 frames")
    TestUtils.assert_eq(script.frame_count(&"unknown"), 0, "unknown boss action should have zero frames")
