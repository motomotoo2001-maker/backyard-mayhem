extends RefCounted

const TestUtils = preload("res://tests/test_utils.gd")
const PlayerVFXEmitter = preload("res://scripts/player/player_vfx_emitter.gd")

func run() -> void:
    var muzzle: Node2D = PlayerVFXEmitter.build_effect_node(&"muzzle_flash", Vector2.RIGHT, 1.0)
    TestUtils.assert_true(muzzle != null, "muzzle_flash must build a visible Node2D")
    if muzzle != null:
        TestUtils.assert_eq(String(muzzle.get_meta("effect_name", "")), "muzzle_flash", "muzzle node must keep effect identity")
        TestUtils.assert_true(muzzle.get_child_count() >= 4, "muzzle flash should use layered flash and spark geometry")
        TestUtils.assert_true(muzzle.has_node("OuterFlash"), "muzzle flash needs an outer silhouette")
        TestUtils.assert_true(muzzle.has_node("CoreFlash"), "muzzle flash needs a hot core")
        TestUtils.assert_true(muzzle.has_node("SparkTop"), "muzzle flash needs an upper spark streak")
        TestUtils.assert_true(muzzle.has_node("SparkBottom"), "muzzle flash needs a lower spark streak")
        TestUtils.assert_near(muzzle.rotation, 0.0, 0.001, "right-facing muzzle flash should point right")
        muzzle.free()

    var blast: Node2D = PlayerVFXEmitter.build_effect_node(&"air_blast", Vector2.DOWN, 1.0)
    TestUtils.assert_true(blast != null, "air_blast must build a visible Node2D")
    if blast != null:
        TestUtils.assert_eq(String(blast.get_meta("effect_name", "")), "air_blast", "air-blast node must keep effect identity")
        TestUtils.assert_true(blast.get_child_count() >= 4, "air blast should use layered arcs and wisps")
        TestUtils.assert_true(blast.has_node("InnerArc"), "air blast needs an inner pressure arc")
        TestUtils.assert_true(blast.has_node("OuterArc"), "air blast needs an outer pressure arc")
        TestUtils.assert_true(blast.has_node("UpperWisp"), "air blast needs an upper trailing wisp")
        TestUtils.assert_true(blast.has_node("LowerWisp"), "air blast needs a lower trailing wisp")
        TestUtils.assert_near(blast.rotation, PI * 0.5, 0.001, "down-facing air blast should rotate with aim direction")
        blast.free()

    var emitter := PlayerVFXEmitter.new()
    var spawned: Node2D = emitter.spawn_effect(&"muzzle_flash", Vector2(24, -6), Vector2.RIGHT, 1.25, 0.08)
    TestUtils.assert_true(spawned != null, "scene-facing emitter must spawn a muzzle node")
    if spawned != null:
        TestUtils.assert_eq(spawned.position, Vector2(24, -6), "spawned VFX must honor local origin")
        TestUtils.assert_near(spawned.scale.x, 1.25, 0.001, "spawned VFX must honor effect scale")
        TestUtils.assert_near(float(spawned.get_meta("effect_lifetime", 0.0)), 0.08, 0.001, "spawned VFX must retain cleanup lifetime")
        TestUtils.assert_true(spawned.get_parent() == emitter, "spawned VFX must be parented to emitter")
    emitter.free()

    var missing: Node2D = PlayerVFXEmitter.build_effect_node(&"unknown", Vector2.RIGHT, 1.0)
    TestUtils.assert_true(missing == null, "unknown VFX names must fail closed")
