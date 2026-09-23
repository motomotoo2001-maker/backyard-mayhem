extends RefCounted

const TestUtils = preload("res://tests/test_utils.gd")
const RuntimeCoordinator = preload("res://scripts/gameplay/backyard_runtime_coordinator.gd")

func run() -> void:
    var path := "res://scripts/qa/backyard_snapshot_driver.gd"
    if not ResourceLoader.exists(path):
        TestUtils.failures.append("backyard snapshot driver must exist")
        return

    var driver = load(path)
    TestUtils.assert_true(driver != null, "snapshot driver should load")
    if driver == null:
        return

    var ids: Array = driver.scenario_ids()
    TestUtils.assert_eq(ids.size(), 3, "snapshot driver should define three visual scenarios")
    TestUtils.assert_true(ids.has(&"start"), "snapshot scenarios should include start")
    TestUtils.assert_true(ids.has(&"damaged_upgrade"), "snapshot scenarios should include damaged upgrade")
    TestUtils.assert_true(ids.has(&"boss"), "snapshot scenarios should include boss")

    var runtime = RuntimeCoordinator.new()
    var start: Dictionary = driver.prepare(runtime, &"start")
    TestUtils.assert_eq(int(start.get("current_wave", 0)), 1, "start capture should use wave 1")
    TestUtils.assert_eq(int(start.get("base_tier", -1)), 0, "start capture should use tier 0 base")
    TestUtils.assert_near(float(start.get("base_hp", 0.0)), 100.0, 0.001, "start capture should use full base HP")

    var damaged: Dictionary = driver.prepare(runtime, &"damaged_upgrade")
    TestUtils.assert_eq(int(damaged.get("current_wave", 0)), 2, "damaged capture should use wave 2")
    TestUtils.assert_eq(int(damaged.get("base_tier", -1)), 1, "damaged capture should show first base upgrade")
    TestUtils.assert_true(float(damaged.get("base_hp", 100.0)) < float(damaged.get("base_max_hp", 100.0)), "damaged capture should visibly reduce base HP")
    TestUtils.assert_true(String(damaged.get("base_visual", {}).get("state", "fresh")) != "fresh", "damaged capture should expose a non-fresh visual state")

    var boss: Dictionary = driver.prepare(runtime, &"boss")
    TestUtils.assert_eq(int(boss.get("current_wave", 0)), 5, "boss capture should use wave 5")
    TestUtils.assert_true(bool(boss.get("is_boss_wave", false)), "boss capture should enable boss wave state")
    TestUtils.assert_eq(StringName(boss.get("state", &"")), &"wave", "boss capture should be in active wave state")

    TestUtils.assert_eq(String(driver.file_name(&"start")), "backyard-wave1.png", "start capture file name should be stable")
    TestUtils.assert_eq(String(driver.file_name(&"damaged_upgrade")), "backyard-damaged-tier1.png", "damaged capture file name should be stable")
    TestUtils.assert_eq(String(driver.file_name(&"boss")), "backyard-boss-wave5.png", "boss capture file name should be stable")
