extends RefCounted

const TestUtils = preload("res://tests/test_utils.gd")

func run() -> void:
    var path := "res://scripts/gameplay/backyard_runtime_coordinator.gd"
    if not ResourceLoader.exists(path):
        TestUtils.failures.append("backyard runtime coordinator must exist")
        return

    var script_resource = load(path)
    if script_resource == null or not script_resource is Script:
        TestUtils.failures.append("backyard runtime coordinator must load as Script")
        return

    var script: Script = script_resource as Script
    if not script.can_instantiate():
        TestUtils.failures.append("backyard runtime coordinator must instantiate")
        return

    var coordinator = script.new()
    var initial: Dictionary = coordinator.snapshot()
    TestUtils.assert_eq(int(initial.get("current_wave", 0)), 1, "runtime should start on wave 1")
    TestUtils.assert_eq(StringName(initial.get("state", &"")), &"wave", "runtime should start in wave state")
    TestUtils.assert_eq(int(initial.get("threat_budget", 0)), 10, "wave 1 should expose threat budget")
    TestUtils.assert_eq(int(initial.get("base_tier", -1)), 0, "base should start at tier 0")
    TestUtils.assert_eq(int((initial.get("base_visual", {}) as Dictionary).get("turret_slots", -1)), 0, "tier 0 base should expose no turret slots")

    var intermission: Dictionary = coordinator.complete_wave()
    TestUtils.assert_eq(StringName(intermission.get("state", &"")), &"intermission", "wave completion should enter intermission")
    TestUtils.assert_eq(int(intermission.get("coins", 0)), 100, "wave 1 reward should be granted")
    TestUtils.assert_eq((intermission.get("offers", []) as Array).size(), 3, "intermission should expose three strategic offers")

    TestUtils.assert_true(coordinator.purchase_upgrade(&"base", &"base_fortification"), "base upgrade should be purchasable after wave 1")
    var upgraded: Dictionary = coordinator.snapshot()
    TestUtils.assert_eq(int(upgraded.get("base_tier", -1)), 1, "base purchase should raise visual tier")
    TestUtils.assert_eq(int((upgraded.get("base_visual", {}) as Dictionary).get("turret_slots", -1)), 1, "tier 1 should expose one turret slot")

    TestUtils.assert_true(coordinator.start_next_wave(), "runtime should start wave 2 after intermission")
    var wave_two: Dictionary = coordinator.snapshot()
    TestUtils.assert_eq(int(wave_two.get("current_wave", 0)), 2, "runtime should advance to wave 2")
    TestUtils.assert_true((wave_two.get("enemy_pool", []) as Array).has(&"cat"), "wave 2 should introduce cat pressure")

    var hero_events: Array = coordinator.hero_frame_events(&"fire", 1)
    TestUtils.assert_true(hero_events.has(&"muzzle"), "runtime should forward hero combat VFX events")

    var boss_warning: Dictionary = coordinator.boss_warning(&"radial_slam")
    TestUtils.assert_eq(StringName(boss_warning.get("hud_kind", &"")), &"boss_warning", "runtime should expose boss warning HUD data")
    TestUtils.assert_true(float(boss_warning.get("telegraph_radius", 0.0)) >= 180.0, "radial slam should keep readable danger radius")
