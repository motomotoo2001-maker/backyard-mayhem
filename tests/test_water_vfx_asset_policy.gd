extends RefCounted

const TestUtils = preload("res://tests/test_utils.gd")

func run() -> void:
    var policy_path := "res://scripts/art/water_vfx_asset_policy.gd"
    TestUtils.assert_true(ResourceLoader.exists(policy_path), "water VFX asset policy must exist")
    if not ResourceLoader.exists(policy_path):
        return

    var Policy = load(policy_path)

    TestUtils.assert_true(
        Policy.is_valid_runtime_path("res://assets/runtime/vfx/water/stream/stream_00.png"),
        "normalized stream frame is allowed"
    )
    TestUtils.assert_true(
        Policy.is_valid_runtime_path("res://assets/runtime/vfx/water/splash/splash_05.png"),
        "normalized splash frame is allowed"
    )
    TestUtils.assert_true(
        Policy.is_valid_runtime_path("res://assets/runtime/vfx/water/projectile/projectile_07.png"),
        "normalized projectile frame is allowed"
    )

    TestUtils.assert_true(
        not Policy.is_valid_runtime_path("res://assets/source/user_pack/Water_turret_effect_sprite_sheet.png"),
        "raw concept sheet is rejected"
    )
    TestUtils.assert_true(
        not Policy.is_valid_runtime_path("res://assets/runtime/vfx/water/stream_sheet.png"),
        "runtime root cannot contain unsliced sheet"
    )
    TestUtils.assert_true(
        not Policy.is_valid_runtime_path("res://assets/runtime/vfx/water/stream/stream_frame_one.png"),
        "noncanonical frame name is rejected"
    )
    TestUtils.assert_true(
        not Policy.is_valid_runtime_path("res://assets/runtime/vfx/water/turret/turret_00.png"),
        "turret body cannot be baked into water VFX family"
    )

    var result: Dictionary = Policy.validate_runtime_paths(PackedStringArray([
        "res://assets/runtime/vfx/water/stream/stream_00.png",
        "res://assets/runtime/vfx/water/impact/impact_03.png",
        "res://assets/source/reference/water_sheet.png",
    ]))
    TestUtils.assert_true(not bool(result.get("ok", true)), "mixed path list fails validation")
    TestUtils.assert_eq(int(result.get("checked_count", 0)), 3, "policy reports checked path count")
    TestUtils.assert_eq((result.get("invalid", PackedStringArray()) as PackedStringArray).size(), 1, "policy isolates invalid source path")
