extends RefCounted

const TestUtils = preload("res://tests/test_utils.gd")
const PlayerVFXEmitter = preload("res://scripts/player/player_vfx_emitter.gd")

func run() -> void:
    var muzzle: Node2D = PlayerVFXEmitter.build_effect_node(&"muzzle_flash", Vector2.RIGHT, 1.0)
    TestUtils.assert_true(muzzle != null, "muzzle_flash must build a visible Node2D")
    if muzzle != null:
        TestUtils.assert_eq(String(muzzle.get_meta("effect_name", "")), "muzzle_flash", "muzzle node must keep effect identity")
        TestUtils.assert_true(muzzle.get_child_count() >= 2, "muzzle flash should have outer and core geometry")
        TestUtils.assert_near(muzzle.rotation, 0.0, 0.001, "right-facing muzzle flash should point right")
        muzzle.free()

    var blast: Node2D = PlayerVFXEmitter.build_effect_node(&"air_blast", Vector2.DOWN, 1.0)
    TestUtils.assert_true(blast != null, "air_blast must build a visible Node2D")
    if blast != null:
        TestUtils.assert_eq(String(blast.get_meta("effect_name", "")), "air_blast", "air-blast node must keep effect identity")
        TestUtils.assert_true(blast.get_child_count() >= 2, "air blast should use layered arc geometry")
        TestUtils.assert_near(blast.rotation, PI * 0.5, 0.001, "down-facing air blast should rotate with aim direction")
        blast.free()

    var missing: Node2D = PlayerVFXEmitter.build_effect_node(&"unknown", Vector2.RIGHT, 1.0)
    TestUtils.assert_true(missing == null, "unknown VFX names must fail closed")
