extends RefCounted

const TestUtils = preload("res://tests/test_utils.gd")
const AssetPolicy = preload("res://scripts/art/water_vfx_asset_policy.gd")

func run() -> void:
    var path := "res://scripts/art/water_vfx_manifest.gd"
    if not ResourceLoader.exists(path):
        TestUtils.failures.append("water VFX frame manifest must exist")
        return

    var script_resource = load(path)
    if script_resource == null or not script_resource is Script:
        TestUtils.failures.append("water VFX frame manifest must load as Script")
        return

    var script: Script = script_resource as Script
    if not script.can_instantiate():
        TestUtils.failures.append("water VFX frame manifest must instantiate")
        return

    var names: Array = script.required_filenames()
    TestUtils.assert_eq(names.size(), 37, "water VFX manifest should contain exactly 37 frames")

    var unique := {}
    for filename_variant in names:
        var filename := String(filename_variant)
        TestUtils.assert_true(not unique.has(filename), "water VFX filename must be unique: %s" % filename)
        unique[filename] = true

    TestUtils.assert_true(names.has("stream_00.png"), "manifest should start stream sequence at 00")
    TestUtils.assert_true(names.has("stream_07.png"), "manifest should include final stream frame 07")
    TestUtils.assert_true(names.has("projectile_03.png"), "manifest should include final projectile frame 03")
    TestUtils.assert_true(names.has("splash_05.png"), "manifest should include final splash frame 05")
    TestUtils.assert_true(names.has("impact_04.png"), "manifest should include final impact frame 04")
    TestUtils.assert_true(names.has("foam_05.png"), "manifest should include final foam frame 05")
    TestUtils.assert_true(names.has("vortex_07.png"), "manifest should include final vortex frame 07")

    var paths: Array = script.required_paths()
    TestUtils.assert_eq(paths.size(), names.size(), "every water VFX filename should have a runtime path")
    for runtime_path_variant in paths:
        var runtime_path := String(runtime_path_variant)
        TestUtils.assert_true(AssetPolicy.is_allowed_runtime_path(runtime_path), "manifest path must satisfy water asset policy: %s" % runtime_path)
