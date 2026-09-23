extends RefCounted

const TestUtils = preload("res://tests/test_utils.gd")
const SessionPath := "res://scripts/gameplay/vertical_slice_session.gd"
const Waves = preload("res://scripts/gameplay/wave_progression_profile.gd")

func run() -> void:
    TestUtils.assert_true(ResourceLoader.exists(SessionPath), "vertical slice session runtime must exist")
    if not ResourceLoader.exists(SessionPath):
        return

    var Session = load(SessionPath)
    TestUtils.assert_true(Session != null and Session.can_instantiate(), "vertical slice session runtime must instantiate")
    if Session == null or not Session.can_instantiate():
        return

    var session = Session.new()
    var initial: Dictionary = session.snapshot()
    TestUtils.assert_eq(int(initial.get("current_wave", 0)), 1, "run starts on wave 1")
    TestUtils.assert_eq(initial.get("state", &""), &"wave", "run starts in active-wave state")
    TestUtils.assert_eq(int(initial.get("coins", -1)), 0, "run starts with zero coins")
    TestUtils.assert_eq(int(initial.get("base_tier", -1)), 0, "base starts at visual tier 0")

    var after_wave_one: Dictionary = session.complete_current_wave()
    TestUtils.assert_eq(after_wave_one.get("state", &""), &"intermission", "non-final wave completion enters intermission")
    TestUtils.assert_eq(int(after_wave_one.get("coins", -1)), int(Waves.wave(1).reward_coins), "wave reward is credited once")
    TestUtils.assert_eq((after_wave_one.get("offers", []) as Array).size(), 3, "intermission exposes three strategic upgrade lanes")

    TestUtils.assert_true(session.purchase_upgrade(&"hero", &"golden_slipper"), "wave 1 reward can buy established hero upgrade")
    var after_hero_buy: Dictionary = session.snapshot()
    TestUtils.assert_true((after_hero_buy.get("owned_upgrades", []) as Array).has(&"golden_slipper"), "purchased hero upgrade is tracked")
    TestUtils.assert_eq(int(after_hero_buy.get("coins", -1)), 20, "hero purchase deducts the wave-1 lane cost")
    TestUtils.assert_true(not session.purchase_upgrade(&"utility", &"emergency_repair"), "only one strategic purchase is allowed per intermission")

    TestUtils.assert_true(session.start_next_wave(), "intermission can advance to wave 2")
    TestUtils.assert_eq(int(session.snapshot().get("current_wave", 0)), 2, "advancing increments wave number")

    session.complete_current_wave()
    TestUtils.assert_true(session.purchase_upgrade(&"base", &"base_fortification"), "wave 2 economy can purchase base fortification")
    TestUtils.assert_eq(int(session.snapshot().get("base_tier", -1)), 1, "base fortification advances visible base tier")
    TestUtils.assert_true(session.start_next_wave(), "run can advance to wave 3")

    session.complete_current_wave()
    TestUtils.assert_true(session.start_next_wave(), "intermission may be skipped without a purchase")
    session.complete_current_wave()
    TestUtils.assert_true(session.purchase_upgrade(&"base", &"turret_socket"), "late intermission can buy turret socket")
    TestUtils.assert_eq(int(session.snapshot().get("base_tier", -1)), 2, "turret socket also advances visible base tier")
    TestUtils.assert_true(session.start_next_wave(), "run can advance to final wave")

    var final_state: Dictionary = session.complete_current_wave()
    TestUtils.assert_eq(int(final_state.get("current_wave", 0)), 5, "final completion remains on wave 5")
    TestUtils.assert_eq(final_state.get("state", &""), &"victory", "final boss completion ends the run in victory")
    TestUtils.assert_eq((final_state.get("offers", []) as Array).size(), 0, "no shop is shown after victory")
    TestUtils.assert_true(not session.start_next_wave(), "victory cannot advance beyond wave 5")

    var coins_before_repeat := int(session.snapshot().get("coins", -1))
    var repeated: Dictionary = session.complete_current_wave()
    TestUtils.assert_eq(int(repeated.get("coins", -1)), coins_before_repeat, "completed final wave cannot grant its reward twice")
