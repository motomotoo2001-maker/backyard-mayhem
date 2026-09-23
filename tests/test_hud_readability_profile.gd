extends RefCounted

const TestUtils = preload("res://tests/test_utils.gd")
const ProfilePath := "res://scripts/art/hud_readability_profile.gd"

func run() -> void:
    TestUtils.assert_true(ResourceLoader.exists(ProfilePath), "HUD readability profile must exist")
    if not ResourceLoader.exists(ProfilePath):
        return

    var Profile = load(ProfilePath)
    TestUtils.assert_true(Profile != null and Profile.can_instantiate(), "HUD readability profile must instantiate")
    if Profile == null or not Profile.can_instantiate():
        return

    var boss_size: Vector2i = Profile.card_min_size(&"boss_warning")
    TestUtils.assert_true(boss_size.x >= 340 and boss_size.y >= 60, "boss warning has enough visual space")

    var dash_size: Vector2i = Profile.card_min_size(&"dash")
    TestUtils.assert_true(dash_size.x >= 220 and dash_size.y >= 44, "dash card remains readable")

    TestUtils.assert_true(Profile.priority(&"boss_warning") > Profile.priority(&"wave_transition"), "boss warning outranks wave text")
    TestUtils.assert_true(Profile.priority(&"critical_health") > Profile.priority(&"upgrade_hint"), "critical health outranks upgrade hint")
    TestUtils.assert_true(Profile.should_replace(&"status", &"boss_warning"), "boss warning replaces low-priority status")
    TestUtils.assert_true(not Profile.should_replace(&"boss_warning", &"status"), "status cannot hide boss warning")
    TestUtils.assert_eq(Profile.max_transient_cards(), 2, "HUD limits transient stack to preserve playfield")
