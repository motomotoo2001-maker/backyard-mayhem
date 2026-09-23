extends RefCounted

const TestUtils = preload("res://tests/test_utils.gd")

func run() -> void:
    var path := "res://scripts/art/visual_feedback_orchestrator.gd"
    if not ResourceLoader.exists(path):
        TestUtils.failures.append("visual feedback orchestrator must exist")
        return

    var script_resource = load(path)
    if script_resource == null or not script_resource is Script:
        TestUtils.failures.append("visual feedback orchestrator must load as Script")
        return

    var script: Script = script_resource as Script
    if not script.can_instantiate():
        TestUtils.failures.append("visual feedback orchestrator must instantiate")
        return

    var muzzle_events: Array = script.hero_frame_events(&"fire", 1)
    TestUtils.assert_true(muzzle_events.has(&"muzzle"), "fire frame 1 should emit muzzle")
    TestUtils.assert_true(muzzle_events.has(&"recoil_peak"), "fire frame 1 should emit recoil peak")
    TestUtils.assert_true(muzzle_events.has(&"air_blast"), "fire frame 1 should emit air blast")
    TestUtils.assert_eq(script.hero_frame_events(&"fire", 0).size(), 0, "fire frame 0 should not emit combat VFX")

    var defense: Dictionary = script.defense_visual_snapshot(25.0, 100.0, true, 2, true)
    TestUtils.assert_eq(defense.get("state"), "critical", "25% HP should be critical")
    TestUtils.assert_true(bool(defense.get("show_smoke", false)), "critical defense should smoke")
    TestUtils.assert_true(bool(defense.get("show_electric", false)), "live electrified defense should show electric overlay")
    TestUtils.assert_eq(int(defense.get("turret_slots", -1)), 2, "base tier 2 should expose two turret slots")
    TestUtils.assert_true(bool(defense.get("show_armor", false)), "base tier 2 should show armor")

    var boss: Dictionary = script.boss_telegraph_snapshot(&"radial_slam")
    TestUtils.assert_eq(StringName(boss.get("hud_kind", &"")), &"boss_warning", "boss attack should use boss warning HUD")
    TestUtils.assert_eq(boss.get("card_min_size"), Vector2i(360, 64), "boss warning must keep readable card size")
    TestUtils.assert_eq(int(boss.get("hud_priority", 0)), 100, "boss warning should have top priority")
    TestUtils.assert_true(float(boss.get("telegraph_radius", 0.0)) >= 180.0, "radial slam should have large danger radius")
    TestUtils.assert_true(int(boss.get("pulse_count", 0)) >= 3, "radial slam should pulse at least three times")
