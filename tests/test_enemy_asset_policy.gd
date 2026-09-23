extends RefCounted

const TestUtils = preload("res://tests/test_utils.gd")

func run() -> void:
    var policy_path := "res://scripts/art/enemy_asset_policy.gd"
    TestUtils.assert_true(ResourceLoader.exists(policy_path), "enemy runtime asset policy must exist")
    if not ResourceLoader.exists(policy_path):
        return

    var Policy = load(policy_path)

    TestUtils.assert_true(
        Policy.is_valid_runtime_frame_path("res://assets/runtime/enemies/raccoon/run/run_00.png"),
        "normalized raccoon frame is allowed"
    )
    TestUtils.assert_true(
        Policy.is_valid_runtime_frame_path("res://assets/runtime/enemies/cat/attack/attack_05.png"),
        "normalized cat attack frame is allowed"
    )
    TestUtils.assert_true(
        Policy.is_valid_runtime_frame_path("res://assets/runtime/enemies/pigeon/death/death_03.png"),
        "normalized pigeon death frame is allowed"
    )

    TestUtils.assert_true(
        not Policy.is_valid_runtime_frame_path("res://assets/source/user_pack/Raccoon_animation_sprite_sheet.png"),
        "raw user-pack concept sheet is rejected"
    )
    TestUtils.assert_true(
        not Policy.is_valid_runtime_frame_path("res://assets/runtime/enemies/bulldog/Bulldog_enemy_animation_sprite_sheet.png"),
        "runtime folder cannot hide an unsliced sprite sheet"
    )
    TestUtils.assert_true(
        not Policy.is_valid_runtime_frame_path("res://assets/runtime/enemies/unknown/run/run_00.png"),
        "unknown enemy family is rejected"
    )
    TestUtils.assert_true(
        not Policy.is_valid_runtime_frame_path("res://assets/runtime/enemies/raccoon/run/frame.png"),
        "frame name must use action_NN convention"
    )
    TestUtils.assert_true(
        not Policy.is_valid_runtime_frame_path("res://assets/runtime/enemies/raccoon/run/run_000.png"),
        "frame index must use exactly two digits"
    )

    var result: Dictionary = Policy.validate_runtime_paths(PackedStringArray([
        "res://assets/runtime/enemies/raccoon/run/run_00.png",
        "res://assets/runtime/enemies/bulldog/hurt/hurt_01.png",
        "res://assets/source/reference/cat_sheet.png",
    ]))
    TestUtils.assert_true(not bool(result.get("ok", true)), "mixed runtime/source list fails validation")
    TestUtils.assert_eq(int(result.get("checked_count", 0)), 3, "policy reports checked count")
    TestUtils.assert_eq((result.get("invalid", PackedStringArray()) as PackedStringArray).size(), 1, "policy isolates the invalid source asset")
