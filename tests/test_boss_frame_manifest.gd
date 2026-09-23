extends RefCounted

const TestUtils = preload("res://tests/test_utils.gd")
const EnemyPolicy = preload("res://scripts/art/enemy_asset_policy.gd")

func run() -> void:
    var path := "res://scripts/art/boss_frame_manifest.gd"
    if not ResourceLoader.exists(path):
        TestUtils.failures.append("boss frame manifest must exist")
        return

    var script_resource = load(path)
    if script_resource == null or not script_resource is Script:
        TestUtils.failures.append("boss frame manifest must load as Script")
        return

    var script: Script = script_resource as Script
    if not script.can_instantiate():
        TestUtils.failures.append("boss frame manifest must instantiate")
        return

    var names: Array = script.required_filenames()
    TestUtils.assert_eq(names.size(), 41, "boss manifest should contain exactly 41 frames")

    var unique := {}
    for filename_variant in names:
        var filename := String(filename_variant)
        TestUtils.assert_true(not unique.has(filename), "boss filename must be unique: %s" % filename)
        unique[filename] = true

    for expected in [
        "idle_00.png", "idle_03.png",
        "run_00.png", "run_07.png",
        "heavy_swing_00.png", "heavy_swing_07.png",
        "radial_slam_00.png", "radial_slam_09.png",
        "hurt_00.png", "hurt_02.png",
        "death_00.png", "death_07.png",
    ]:
        TestUtils.assert_true(names.has(expected), "boss manifest must include %s" % expected)

    var paths: Array = script.required_paths()
    TestUtils.assert_eq(paths.size(), names.size(), "every boss filename should have one runtime path")
    for runtime_path_variant in paths:
        var runtime_path := String(runtime_path_variant)
        TestUtils.assert_true(EnemyPolicy.is_valid_runtime_frame_path(runtime_path), "boss manifest path must satisfy enemy asset policy: %s" % runtime_path)
        TestUtils.assert_true(runtime_path.begins_with("res://assets/runtime/enemies/boss/"), "boss path must stay inside boss runtime folder")
