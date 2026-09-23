extends RefCounted

const TestUtils = preload("res://tests/test_utils.gd")

func run() -> void:
    var path := "res://scripts/art/bulldog_animation_profile.gd"
    if not ResourceLoader.exists(path):
        TestUtils.failures.append("bulldog animation profile must exist")
        return

    var script_resource = load(path)
    if script_resource == null or not script_resource is Script:
        TestUtils.failures.append("bulldog animation profile must load as Script")
        return

    var script: Script = script_resource as Script
    if not script.can_instantiate():
        TestUtils.failures.append("bulldog animation profile must instantiate")
        return

    TestUtils.assert_eq(script.CANVAS_SIZE, Vector2i(288, 288), "bulldog should use a larger 288x288 runtime canvas")
    TestUtils.assert_eq(script.GROUND_ANCHOR, Vector2i(144, 268), "bulldog anchor should remain bottom-center")
    TestUtils.assert_true(script.ALLOW_HORIZONTAL_FLIP, "bulldog should use horizontal flip for mirrored facing")

    var actions: Array = script.actions()
    TestUtils.assert_eq(actions.size(), 5, "bulldog should define five canonical actions")
    for action in [&"idle", &"run", &"attack", &"hurt", &"death"]:
        TestUtils.assert_true(actions.has(action), "bulldog action %s must exist" % action)

    TestUtils.assert_eq(script.frame_count(&"idle"), 4, "bulldog idle should use four frames")
    TestUtils.assert_near(script.fps(&"idle"), 5.0, 0.001, "bulldog idle should feel heavy")
    TestUtils.assert_true(script.loops(&"idle"), "bulldog idle should loop")

    TestUtils.assert_eq(script.frame_count(&"run"), 8, "bulldog run should use eight frames")
    TestUtils.assert_near(script.fps(&"run"), 9.0, 0.001, "bulldog run should be slower than raccoon/cat")
    TestUtils.assert_true(script.loops(&"run"), "bulldog run should loop")

    TestUtils.assert_eq(script.frame_count(&"attack"), 7, "bulldog heavy bite/charge should use seven frames")
    TestUtils.assert_near(script.fps(&"attack"), 10.0, 0.001, "bulldog attack should have readable windup")
    TestUtils.assert_true(not script.loops(&"attack"), "bulldog attack should be one-shot")
    TestUtils.assert_eq(script.event_frame(&"attack", &"hit"), 4, "bulldog heavy hit should land on frame 4")

    TestUtils.assert_eq(script.frame_count(&"hurt"), 3, "bulldog hurt should use three frames")
    TestUtils.assert_near(script.fps(&"hurt"), 9.0, 0.001, "bulldog hurt should feel weighty")
    TestUtils.assert_true(not script.loops(&"hurt"), "bulldog hurt should be one-shot")

    TestUtils.assert_eq(script.frame_count(&"death"), 6, "bulldog death should use six frames")
    TestUtils.assert_near(script.fps(&"death"), 8.0, 0.001, "bulldog death should use 8 FPS")
    TestUtils.assert_true(not script.loops(&"death"), "bulldog death should be one-shot")

    TestUtils.assert_eq(script.total_frames(), 28, "bulldog production set should contain 28 frames")
    TestUtils.assert_eq(script.frame_count(&"unknown"), 0, "unknown bulldog action should have zero frames")
