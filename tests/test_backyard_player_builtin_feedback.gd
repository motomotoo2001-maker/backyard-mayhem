extends RefCounted

const TestUtils = preload("res://tests/test_utils.gd")
const PlayerScript = preload("res://scripts/player/player.gd")

func run() -> void:
    var player = PlayerScript.new()
    if not player.has_method("_builtin_feedback_for_event"):
        TestUtils.failures.append("BackyardPlayer must expose deterministic built-in frame feedback")
        player.free()
        return

    var recoil: Dictionary = player._builtin_feedback_for_event(&"recoil_peak", &"fire")
    TestUtils.assert_true(float(recoil.get("weapon_recoil_px", 0.0)) >= 4.0, "fire recoil peak should kick the weapon visibly")

    var fire_recovery: Dictionary = player._builtin_feedback_for_event(&"recovery", &"fire")
    TestUtils.assert_true(bool(fire_recovery.get("reset_weapon", false)), "fire recovery should restore weapon transform")

    var trail_peak: Dictionary = player._builtin_feedback_for_event(&"trail_peak", &"dash")
    TestUtils.assert_true(float(trail_peak.get("dash_trail_scale", 1.0)) > 1.0, "dash trail peak should visually stretch the trail")

    var trail_end: Dictionary = player._builtin_feedback_for_event(&"trail_end", &"dash")
    TestUtils.assert_true(bool(trail_end.get("reset_dash_trail", false)), "dash trail end should restore the trail transform")

    var hurt: Dictionary = player._builtin_feedback_for_event(&"impact", &"hurt")
    TestUtils.assert_true(bool(hurt.get("hurt_flash", false)), "hurt impact should request a visible damage flash")

    var hurt_recovery: Dictionary = player._builtin_feedback_for_event(&"recovery", &"hurt")
    TestUtils.assert_true(bool(hurt_recovery.get("clear_hurt_flash", false)), "hurt recovery should clear the damage flash")

    player.free()
