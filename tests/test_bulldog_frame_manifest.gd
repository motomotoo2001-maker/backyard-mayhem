extends RefCounted

const TestUtils = preload("res://tests/test_utils.gd")
const EnemyPolicy = preload("res://scripts/art/enemy_asset_policy.gd")

func run() -> void:
    var path := "res://scripts/art/bulldog_frame_manifest.gd"
    if not ResourceLoader.exists(path):
        TestUtils.failures.append("bulldog frame manifest must exist")
        return

    var script_resource = load(path)
    if script_resource == null or not script_resource is Script:
        TestUtils.failures.append("bulldog frame manifest must load as Script")
        return

    var script: Script = script_resource as Script
    if not script.can_instantiate():
        TestUtils.failures.append("bulldog frame manifest must instantiate")
        return

    var names: Array = script.required_filenames()
    TestUtils.assert_eq(names.size(), 28, "bulldog manifest should contain exactly 28 frames")

    var unique := {}
    for filename_variant in names:
        var filename := String(filename_variant)
        TestUtils.assert_true(not unique.has(filename), "bulldog filename must be unique: %s" % filename)
        unique[filename] = true

    for expected in [
        "idle_00.png", "idle_03.png",
        "run_00.png", "run_07.png",
        "attack_00.png", "attack_06.png",
        "hurt_00.png", "hurt_02.png",
        "death_00.png", "death_05.png",
    ]:
        TestUtils.assert_true(names.has(expected), "bulldog manifest must include %s" % expected)

    var paths: Array = script.required_paths()
    TestUtils.assert_eq(paths.size(), names.size(), "every bulldog filename should have one runtime path")
    for runtime_path_variant in paths:
        var runtime_path := String(runtime_path_variant)
        TestUtils.assert_true(EnemyPolicy.is_valid_runtime_frame_path(runtime_path), "bulldog manifest path must satisfy enemy asset policy: %s" % runtime_path)
        TestUtils.assert_true(runtime_path.begins_with("res://assets/runtime/enemies/bulldog/"), "bulldog path must stay inside bulldog runtime folder")
