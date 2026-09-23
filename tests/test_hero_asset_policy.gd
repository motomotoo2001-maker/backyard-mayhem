extends RefCounted

const TestUtils = preload("res://tests/test_utils.gd")

func run() -> void:
    var policy_path := "res://scripts/art/hero_asset_policy.gd"
    TestUtils.assert_true(ResourceLoader.exists(policy_path), "hero asset policy must exist")
    if not ResourceLoader.exists(policy_path):
        return

    var Policy = load(policy_path)

    var good := "res://assets/runtime/characters/builder_hero/run_front_right_03.png"
    TestUtils.assert_true(Policy.is_valid_runtime_frame_path(good), "normalized runtime hero frame path must pass")

    var source_sheet := "res://assets/source/user_pack/hero_new_8dir_movement_sheet.png"
    TestUtils.assert_true(not Policy.is_valid_runtime_frame_path(source_sheet), "source/user_pack sheet must never be referenced as runtime hero frame")

    var labeled_reference := "res://assets/source/user_pack/Man_sprite_sheet_rotation_frames_20260922182829.png"
    TestUtils.assert_true(not Policy.is_valid_runtime_frame_path(labeled_reference), "labeled reference sheet must never be referenced as runtime hero frame")

    var wrong_runtime_name := "res://assets/runtime/characters/builder_hero/run_front_right_sheet.png"
    TestUtils.assert_true(not Policy.is_valid_runtime_frame_path(wrong_runtime_name), "runtime hero path must use canonical manifest frame name")

    var wrong_extension := "res://assets/runtime/characters/builder_hero/run_front_right_03.webp"
    TestUtils.assert_true(not Policy.is_valid_runtime_frame_path(wrong_extension), "runtime hero frame must be canonical PNG")

    var paths := PackedStringArray([
        good,
        "res://assets/runtime/characters/builder_hero/fire_left_00.png",
        source_sheet,
    ])
    var result: Dictionary = Policy.validate_runtime_paths(paths)
    TestUtils.assert_true(not result.get("ok", true), "mixed runtime/source hero paths must fail")
    TestUtils.assert_true(result.get("invalid", PackedStringArray()).has(source_sheet), "policy result identifies source-sheet leak")
