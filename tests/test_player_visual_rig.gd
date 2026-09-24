extends RefCounted

const TestUtils = preload("res://tests/test_utils.gd")
const PlayerVisualRig = preload("res://scripts/player/player_visual_rig.gd")

func run() -> void:
    var muzzle: Dictionary = PlayerVisualRig.response_for_event(&"muzzle", &"fire")
    TestUtils.assert_eq(String(muzzle.get("spawn_effect", "")), "muzzle_flash", "fire muzzle event must request a muzzle-flash effect")
    TestUtils.assert_true(float(muzzle.get("effect_lifetime", 0.0)) > 0.0, "muzzle flash must have a finite lifetime")

    var air_blast: Dictionary = PlayerVisualRig.response_for_event(&"air_blast", &"fire")
    TestUtils.assert_eq(String(air_blast.get("spawn_effect", "")), "air_blast", "fire air-blast event must request an air-blast effect")
    TestUtils.assert_true(float(air_blast.get("effect_lifetime", 0.0)) > float(muzzle.get("effect_lifetime", 0.0)), "air blast should linger slightly longer than muzzle flash")

    var fire_peak: Dictionary = PlayerVisualRig.response_for_event(&"recoil_peak", &"fire")
    TestUtils.assert_eq(float(fire_peak.get("weapon_recoil_px", 0.0)), 6.0, "fire recoil peak should move the weapon mount by 6 px")

    var fire_recovery: Dictionary = PlayerVisualRig.response_for_event(&"recovery", &"fire")
    TestUtils.assert_true(bool(fire_recovery.get("reset_weapon", false)), "fire recovery must restore weapon position")

    var dash_peak: Dictionary = PlayerVisualRig.response_for_event(&"trail_peak", &"dash")
    TestUtils.assert_eq(float(dash_peak.get("dash_trail_scale", 0.0)), 1.2, "dash trail peak should scale to 1.2")

    var dash_end: Dictionary = PlayerVisualRig.response_for_event(&"trail_end", &"dash")
    TestUtils.assert_true(bool(dash_end.get("reset_dash_trail", false)), "dash trail end must restore trail scale")

    var hurt_impact: Dictionary = PlayerVisualRig.response_for_event(&"impact", &"hurt")
    TestUtils.assert_true(bool(hurt_impact.get("hurt_flash", false)), "hurt impact must request damage flash")

    var hurt_recovery: Dictionary = PlayerVisualRig.response_for_event(&"recovery", &"hurt")
    TestUtils.assert_true(bool(hurt_recovery.get("clear_hurt_flash", false)), "hurt recovery must clear damage flash")

    TestUtils.assert_true(bool(PlayerVisualRig.cleanup_for_action(&"fire").get("reset_weapon", false)), "interrupted fire must reset recoil")
    TestUtils.assert_true(bool(PlayerVisualRig.cleanup_for_action(&"dash").get("reset_dash_trail", false)), "interrupted dash must reset trail")
    TestUtils.assert_true(bool(PlayerVisualRig.cleanup_for_action(&"hurt").get("clear_hurt_flash", false)), "interrupted hurt must clear flash")
    TestUtils.assert_eq(PlayerVisualRig.cleanup_for_action(&"run").size(), 0, "locomotion must not need transient cleanup")
