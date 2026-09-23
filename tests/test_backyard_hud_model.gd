extends RefCounted

const TestUtils = preload("res://tests/test_utils.gd")
const RuntimeCoordinator = preload("res://scripts/gameplay/backyard_runtime_coordinator.gd")

func run() -> void:
    var path := "res://scripts/gameplay/backyard_hud_model.gd"
    if not ResourceLoader.exists(path):
        TestUtils.failures.append("backyard HUD model must exist")
        return

    var script_resource = load(path)
    if script_resource == null or not script_resource is Script:
        TestUtils.failures.append("backyard HUD model must load as Script")
        return

    var script: Script = script_resource as Script
    if not script.can_instantiate():
        TestUtils.failures.append("backyard HUD model must instantiate")
        return

    var runtime = RuntimeCoordinator.new()
    var wave_view: Dictionary = script.from_runtime(runtime.snapshot())
    TestUtils.assert_eq(String(wave_view.get("wave_text", "")), "WAVE 1 / 5", "wave HUD should show current/total wave")
    TestUtils.assert_eq(String(wave_view.get("coins_text", "")), "COINS 0", "wave HUD should show coins")
    TestUtils.assert_eq(String(wave_view.get("base_text", "")), "BASE TIER 0", "wave HUD should show base tier")
    TestUtils.assert_eq(StringName(wave_view.get("primary_card", &"")), &"status", "normal wave should use status card")
    TestUtils.assert_true(float(wave_view.get("wave_progress", 0.0)) > 0.0, "wave HUD should expose progress ratio")

    runtime.complete_wave()
    var intermission_view: Dictionary = script.from_runtime(runtime.snapshot())
    TestUtils.assert_eq(StringName(intermission_view.get("primary_card", &"")), &"upgrade_hint", "intermission should prioritize upgrade hint")
    TestUtils.assert_eq(String(intermission_view.get("state_text", "")), "CHOOSE AN UPGRADE", "intermission should have actionable copy")
    TestUtils.assert_eq((intermission_view.get("offers", []) as Array).size(), 3, "intermission HUD should expose three offers")

    TestUtils.assert_true(runtime.purchase_upgrade(&"base", &"base_fortification"), "base upgrade should be purchasable")
    var upgraded_view: Dictionary = script.from_runtime(runtime.snapshot())
    TestUtils.assert_eq(String(upgraded_view.get("base_text", "")), "BASE TIER 1", "HUD should immediately reflect base upgrade")

    runtime.start_next_wave()
    var wave_two_view: Dictionary = script.from_runtime(runtime.snapshot())
    TestUtils.assert_eq(String(wave_two_view.get("wave_text", "")), "WAVE 2 / 5", "HUD should advance with runtime")
    TestUtils.assert_eq(String(wave_two_view.get("focus_text", "")), "SPEED PRESSURE", "HUD should expose readable wave focus")
