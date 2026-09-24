extends RefCounted

const TestUtils = preload("res://tests/test_utils.gd")
const PlayerScript = preload("res://scripts/player/player.gd")

func run() -> void:
    var player = PlayerScript.new()
    var weapon := Node2D.new()
    weapon.name = "TestWeapon"
    weapon.position = Vector2(12, 4)
    player.add_child(weapon)
    player.weapon_controller = weapon
    player._facing_vector = Vector2.RIGHT

    if not player.has_method("_ensure_vfx_emitter"):
        TestUtils.failures.append("BackyardPlayer must create a dedicated PlayerVFXEmitter")
        player.free()
        return

    var emitter: Node2D = player._ensure_vfx_emitter()
    TestUtils.assert_true(emitter != null, "player must create a VFX emitter")
    if emitter == null:
        player.free()
        return
    TestUtils.assert_true(emitter.get_parent() == player, "player VFX emitter must live under the player root")

    var muzzle_response: Dictionary = player._builtin_feedback_for_event(&"muzzle", &"fire")
    player._apply_feedback_response(muzzle_response)
    TestUtils.assert_eq(emitter.get_child_count(), 1, "muzzle frame feedback must spawn one transient effect")
    if emitter.get_child_count() == 1:
        var effect := emitter.get_child(0) as Node2D
        TestUtils.assert_eq(String(effect.get_meta("effect_name", "")), "muzzle_flash", "spawned player effect must be the muzzle flash")
        TestUtils.assert_true(effect.position.x > weapon.position.x, "right-facing muzzle flash must spawn in front of the weapon mount")

    player.free()
