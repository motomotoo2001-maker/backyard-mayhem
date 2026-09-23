extends RefCounted

const TestUtils = preload("res://tests/test_utils.gd")
const RuntimeCoordinator = preload("res://scripts/gameplay/backyard_runtime_coordinator.gd")

func run() -> void:
    var runtime = RuntimeCoordinator.new()
    var initial: Dictionary = runtime.snapshot()
    TestUtils.assert_near(float(initial.get("base_hp", 0.0)), 100.0, 0.001, "base should start at 100 HP")
    TestUtils.assert_near(float(initial.get("base_max_hp", 0.0)), 100.0, 0.001, "base should start at 100 max HP")
    TestUtils.assert_eq(String((initial.get("base_visual", {}) as Dictionary).get("state", "")), "fresh", "full-health base should look fresh")

    TestUtils.assert_true(runtime.damage_base(40.0), "base should accept damage during a wave")
    var damaged: Dictionary = runtime.snapshot()
    TestUtils.assert_near(float(damaged.get("base_hp", 0.0)), 60.0, 0.001, "base HP should drop after damage")
    TestUtils.assert_eq(String((damaged.get("base_visual", {}) as Dictionary).get("state", "")), "damaged", "60 percent HP should use damaged visuals")
    TestUtils.assert_true(bool((damaged.get("base_visual", {}) as Dictionary).get("show_cracks", false)), "damaged base should show cracks")

    TestUtils.assert_true(runtime.damage_base(35.0), "base should accept further damage")
    var critical: Dictionary = runtime.snapshot()
    TestUtils.assert_near(float(critical.get("base_hp", 0.0)), 25.0, 0.001, "base HP should reach critical range")
    TestUtils.assert_eq(String((critical.get("base_visual", {}) as Dictionary).get("state", "")), "critical", "25 percent HP should use critical visuals")
    TestUtils.assert_true(bool((critical.get("base_visual", {}) as Dictionary).get("show_smoke", false)), "critical base should show smoke")

    TestUtils.assert_true(runtime.damage_base(30.0), "lethal damage should be applied")
    var defeated: Dictionary = runtime.snapshot()
    TestUtils.assert_near(float(defeated.get("base_hp", 1.0)), 0.0, 0.001, "lethal damage should clamp base HP to zero")
    TestUtils.assert_eq(StringName(defeated.get("state", &"")), &"defeat", "destroyed base should end the run in defeat")
    TestUtils.assert_eq(String((defeated.get("base_visual", {}) as Dictionary).get("state", "")), "broken", "destroyed base should use broken visuals")
    TestUtils.assert_true(bool((defeated.get("base_visual", {}) as Dictionary).get("show_debris", false)), "broken base should show debris")
    var coins_before := int(defeated.get("coins", 0))
    runtime.complete_wave()
    TestUtils.assert_eq(int(runtime.snapshot().get("coins", 0)), coins_before, "defeat must not grant wave rewards")

    runtime.reset()
    runtime.complete_wave()
    TestUtils.assert_true(runtime.purchase_upgrade(&"base", &"base_fortification"), "base fortification should be purchasable after wave 1")
    var fortified: Dictionary = runtime.snapshot()
    TestUtils.assert_eq(int(fortified.get("base_tier", -1)), 1, "fortification should increase base tier")
    TestUtils.assert_near(float(fortified.get("base_max_hp", 0.0)), 125.0, 0.001, "tier 1 should increase max HP")
    TestUtils.assert_near(float(fortified.get("base_hp", 0.0)), 125.0, 0.001, "fortification should grant the added HP capacity")

    runtime.reset()
    runtime.damage_base(45.0)
    runtime.complete_wave()
    TestUtils.assert_true(runtime.purchase_upgrade(&"utility", &"emergency_repair"), "emergency repair should be purchasable")
    TestUtils.assert_near(float(runtime.snapshot().get("base_hp", 0.0)), 100.0, 0.001, "emergency repair should restore base health")
