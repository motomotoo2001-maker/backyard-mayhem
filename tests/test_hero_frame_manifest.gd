extends RefCounted

const TestUtils = preload("res://tests/test_utils.gd")

func run() -> void:
    var manifest_path := "res://scripts/art/hero_frame_manifest.gd"
    TestUtils.assert_true(ResourceLoader.exists(manifest_path), "hero frame manifest must exist")
    if not ResourceLoader.exists(manifest_path):
        return

    var Manifest = load(manifest_path)
    var expected: PackedStringArray = Manifest.expected_frame_names()

    TestUtils.assert_eq(expected.size(), 280, "hero manifest must require exactly 280 frames")

    var unique := {}
    for file_name in expected:
        unique[file_name] = true
    TestUtils.assert_eq(unique.size(), expected.size(), "hero manifest frame names must be unique")

    TestUtils.assert_true(expected.has("idle_front_00.png"), "manifest includes first idle frame")
    TestUtils.assert_true(expected.has("run_front_right_07.png"), "manifest includes final front-right run frame")
    TestUtils.assert_true(expected.has("fire_back_left_03.png"), "manifest includes final back-left fire frame")
    TestUtils.assert_true(expected.has("death_front_left_05.png"), "manifest includes final front-left death frame")

    var complete_result: Dictionary = Manifest.validate_names(expected)
    TestUtils.assert_true(complete_result.get("ok", false), "complete canonical frame list must pass")

    var missing := expected.duplicate()
    missing.remove_at(missing.find("run_right_03.png"))
    var missing_result: Dictionary = Manifest.validate_names(missing)
    TestUtils.assert_true(not missing_result.get("ok", true), "missing runtime frame must fail")
    TestUtils.assert_true(missing_result.get("missing", PackedStringArray()).has("run_right_03.png"), "missing result identifies exact frame")

    var unexpected := expected.duplicate()
    unexpected.append("run_front_99.png")
    var unexpected_result: Dictionary = Manifest.validate_names(unexpected)
    TestUtils.assert_true(not unexpected_result.get("ok", true), "unexpected hero frame must fail")
    TestUtils.assert_true(unexpected_result.get("unexpected", PackedStringArray()).has("run_front_99.png"), "unexpected result identifies exact file")

    var duplicate := expected.duplicate()
    duplicate.append("idle_front_00.png")
    var duplicate_result: Dictionary = Manifest.validate_names(duplicate)
    TestUtils.assert_true(not duplicate_result.get("ok", true), "duplicate hero frame must fail")
    TestUtils.assert_true(duplicate_result.get("duplicates", PackedStringArray()).has("idle_front_00.png"), "duplicate result identifies exact file")
