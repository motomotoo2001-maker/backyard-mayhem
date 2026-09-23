extends RefCounted

const TestUtils = preload("res://tests/test_utils.gd")

func run() -> void:
    var path := "res://scripts/art/water_vfx_sequence_profile.gd"
    if not ResourceLoader.exists(path):
        TestUtils.failures.append("water VFX sequence profile must exist")
        return

    var script_resource = load(path)
    if script_resource == null or not script_resource is Script:
        TestUtils.failures.append("water VFX sequence profile must load as Script")
        return

    var script: Script = script_resource as Script
    if not script.can_instantiate():
        TestUtils.failures.append("water VFX sequence profile must instantiate")
        return

    var kinds: Array = script.kinds()
    TestUtils.assert_eq(kinds.size(), 6, "water VFX must define six canonical sequence families")
    for required_kind in [&"stream", &"projectile", &"splash", &"impact", &"foam", &"vortex"]:
        TestUtils.assert_true(kinds.has(required_kind), "water VFX kind %s must exist" % required_kind)

    var stream: Dictionary = script.profile(&"stream")
    TestUtils.assert_eq(int(stream.get("frames", 0)), 8, "stream should use eight frames")
    TestUtils.assert_near(float(stream.get("fps", 0.0)), 12.0, 0.001, "stream should animate at 12 FPS")
    TestUtils.assert_true(bool(stream.get("loop", false)), "stream should loop")
    TestUtils.assert_eq(StringName(stream.get("origin_role", &"")), &"nozzle_left", "stream origin must stay fixed at nozzle-left")

    var projectile: Dictionary = script.profile(&"projectile")
    TestUtils.assert_eq(int(projectile.get("frames", 0)), 4, "projectile should use four frames")
    TestUtils.assert_near(float(projectile.get("fps", 0.0)), 14.0, 0.001, "projectile should animate at 14 FPS")
    TestUtils.assert_true(bool(projectile.get("loop", false)), "projectile should loop")

    var splash: Dictionary = script.profile(&"splash")
    TestUtils.assert_eq(int(splash.get("frames", 0)), 6, "splash should use six frames")
    TestUtils.assert_near(float(splash.get("fps", 0.0)), 16.0, 0.001, "splash should animate at 16 FPS")
    TestUtils.assert_true(not bool(splash.get("loop", true)), "splash should be one-shot")

    var impact: Dictionary = script.profile(&"impact")
    TestUtils.assert_eq(int(impact.get("frames", 0)), 5, "impact should use five frames")
    TestUtils.assert_near(float(impact.get("fps", 0.0)), 18.0, 0.001, "impact should animate at 18 FPS")
    TestUtils.assert_true(not bool(impact.get("loop", true)), "impact should be one-shot")

    var foam: Dictionary = script.profile(&"foam")
    TestUtils.assert_eq(int(foam.get("frames", 0)), 6, "foam should use six frames")
    TestUtils.assert_near(float(foam.get("fps", 0.0)), 12.0, 0.001, "foam should animate at 12 FPS")
    TestUtils.assert_true(not bool(foam.get("loop", true)), "foam should be one-shot")

    var vortex: Dictionary = script.profile(&"vortex")
    TestUtils.assert_eq(int(vortex.get("frames", 0)), 8, "vortex should use eight frames")
    TestUtils.assert_near(float(vortex.get("fps", 0.0)), 14.0, 0.001, "vortex should animate at 14 FPS")
    TestUtils.assert_true(bool(vortex.get("loop", false)), "vortex should loop while active")

    TestUtils.assert_true(script.profile(&"unknown").is_empty(), "unknown water VFX kinds must be rejected")
