extends RefCounted

const TestUtils = preload("res://tests/test_utils.gd")

func run() -> void:
    var path := "res://scripts/art/pigeon_animation_profile.gd"
    if not ResourceLoader.exists(path):
        TestUtils.failures.append("pigeon animation profile must exist")
        return

    var script_resource = load(path)
    if script_resource == null or not script_resource is Script:
        TestUtils.failures.append("pigeon animation profile must load as Script")
        return

    var script: Script = script_resource as Script
    if not script.can_instantiate():
        TestUtils.failures.append("pigeon animation profile must instantiate")
        return

    TestUtils.assert_eq(script.CANVAS_SIZE, Vector2i(256, 256), "pigeon runtime frames should use 256x256 canvas")
    TestUtils.assert_eq(script.FLIGHT_ANCHOR, Vector2i(128, 156), "pigeon flight anchor should remain stable near body center")
    TestUtils.assert_true(script.ALLOW_HORIZONTAL_FLIP, "pigeon should use horizontal flip for mirrored facing")

    var actions: Array = script.actions()
    TestUtils.assert_eq(actions.size(), 5, "pigeon should define five canonical actions")
    for action in [&"idle", &"fly", &"attack", &"hurt", &"death"]:
        TestUtils.assert_true(actions.has(action), "pigeon action %s must exist" % action)

    TestUtils.assert_eq(script.frame_count(&"idle"), 4, "pigeon idle should use four frames")
    TestUtils.assert_near(script.fps(&"idle"), 6.0, 0.001, "pigeon idle should use 6 FPS")
    TestUtils.assert_true(script.loops(&"idle"), "pigeon idle should loop")

    TestUtils.assert_eq(script.frame_count(&"fly"), 8, "pigeon fly should use eight frames")
    TestUtils.assert_near(script.fps(&"fly"), 12.0, 0.001, "pigeon fly should use 12 FPS")
    TestUtils.assert_true(script.loops(&"fly"), "pigeon fly should loop")

    TestUtils.assert_eq(script.frame_count(&"attack"), 6, "pigeon bombing attack should use six frames")
    TestUtils.assert_near(script.fps(&"attack"), 11.0, 0.001, "pigeon attack should use readable 11 FPS timing")
    TestUtils.assert_true(not script.loops(&"attack"), "pigeon attack should be one-shot")
    TestUtils.assert_eq(script.event_frame(&"attack", &"bomb_release"), 3, "pigeon should release splat bomb on frame 3")

    TestUtils.assert_eq(script.frame_count(&"hurt"), 3, "pigeon hurt should use three frames")
    TestUtils.assert_near(script.fps(&"hurt"), 12.0, 0.001, "pigeon hurt should use 12 FPS")
    TestUtils.assert_true(not script.loops(&"hurt"), "pigeon hurt should be one-shot")

    TestUtils.assert_eq(script.frame_count(&"death"), 6, "pigeon death/fall should use six frames")
    TestUtils.assert_near(script.fps(&"death"), 9.0, 0.001, "pigeon death should use 9 FPS")
    TestUtils.assert_true(not script.loops(&"death"), "pigeon death should be one-shot")

    TestUtils.assert_eq(script.total_frames(), 27, "pigeon production set should contain 27 frames")
    TestUtils.assert_eq(script.frame_count(&"unknown"), 0, "unknown pigeon action should have zero frames")
