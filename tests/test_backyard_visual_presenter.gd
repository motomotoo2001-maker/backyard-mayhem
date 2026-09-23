extends RefCounted

const TestUtils = preload("res://tests/test_utils.gd")
const RuntimeCoordinator = preload("res://scripts/gameplay/backyard_runtime_coordinator.gd")

func run() -> void:
    var path := "res://scripts/gameplay/backyard_visual_presenter.gd"
    if not ResourceLoader.exists(path):
        TestUtils.failures.append("backyard visual presenter must exist")
        return

    var script_resource = load(path)
    if script_resource == null or not script_resource is Script:
        TestUtils.failures.append("backyard visual presenter must load as Script")
        return

    var script: Script = script_resource as Script
    if not script.can_instantiate():
        TestUtils.failures.append("backyard visual presenter must instantiate")
        return

    var runtime = RuntimeCoordinator.new()
    var tier_zero: Dictionary = script.from_runtime(runtime.snapshot())
    TestUtils.assert_eq(int(tier_zero.get("turret_slots", -1)), 0, "tier 0 should expose zero turret sockets")
    TestUtils.assert_true(not bool(tier_zero.get("show_sandbags", true)), "tier 0 should not show sandbags")
    TestUtils.assert_near(float(tier_zero.get("base_scale", 0.0)), 1.0, 0.001, "tier 0 should keep base scale")
    TestUtils.assert_eq(String(tier_zero.get("base_health_state", "")), "fresh", "healthy base should present fresh state")
    TestUtils.assert_true(not bool(tier_zero.get("show_cracks", true)), "healthy base should not show cracks")
    TestUtils.assert_true(not bool(tier_zero.get("boss_alert_visible", true)), "wave 1 should not show boss alert")

    TestUtils.assert_true(runtime.damage_base(40.0), "presenter test should damage the base")
    var damaged: Dictionary = script.from_runtime(runtime.snapshot())
    TestUtils.assert_eq(String(damaged.get("base_health_state", "")), "damaged", "damaged base should expose damaged state")
    TestUtils.assert_true(bool(damaged.get("show_cracks", false)), "damaged base should expose cracks")
    TestUtils.assert_true(not bool(damaged.get("show_smoke", true)), "damaged base should not smoke before critical state")

    TestUtils.assert_true(runtime.damage_base(35.0), "presenter test should reach critical health")
    var critical: Dictionary = script.from_runtime(runtime.snapshot())
    TestUtils.assert_eq(String(critical.get("base_health_state", "")), "critical", "critical base should expose critical state")
    TestUtils.assert_true(bool(critical.get("show_smoke", false)), "critical base should expose smoke")

    runtime.reset()
    runtime.complete_wave()
    TestUtils.assert_true(runtime.purchase_upgrade(&"base", &"base_fortification"), "tier test should buy base fortification")
    var tier_one: Dictionary = script.from_runtime(runtime.snapshot())
    TestUtils.assert_eq(int(tier_one.get("turret_slots", -1)), 1, "tier 1 should expose one turret socket")
    TestUtils.assert_true(bool(tier_one.get("show_sandbags", false)), "tier 1 should show sandbags")
    TestUtils.assert_true(float(tier_one.get("base_scale", 1.0)) > 1.0, "tier 1 should grow the base silhouette")

    var boss_state := runtime.snapshot()
    boss_state["state"] = &"wave"
    boss_state["current_wave"] = 5
    boss_state["is_boss_wave"] = true
    boss_state["focus"] = &"finale"
    var boss_view: Dictionary = script.from_runtime(boss_state)
    TestUtils.assert_true(bool(boss_view.get("boss_alert_visible", false)), "boss wave should show boss alert")
    TestUtils.assert_eq(String(boss_view.get("boss_alert_text", "")), "BOSS WAVE — WATCH THE TELEGRAPHS", "boss alert copy should be explicit")
    TestUtils.assert_true(int(boss_view.get("boss_alert_priority", 0)) >= 100, "boss alert should use highest HUD priority")
