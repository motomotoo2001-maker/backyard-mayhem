extends RefCounted

const TestUtils = preload("res://tests/test_utils.gd")

func run() -> void:
    var profile_path := "res://scripts/art/enemy_hit_feedback_profile.gd"
    TestUtils.assert_true(ResourceLoader.exists(profile_path), "enemy hit feedback profile must exist")
    if not ResourceLoader.exists(profile_path):
        return

    var Profile = load(profile_path)
    var standard: Dictionary = Profile.profile(&"standard")
    var heavy: Dictionary = Profile.profile(&"heavy")
    var boss: Dictionary = Profile.profile(&"boss")

    for data in [standard, heavy, boss]:
        TestUtils.assert_true(float(data.get("flash_seconds", 0.0)) > 0.0, "hit flash must be visible")
        TestUtils.assert_true(float(data.get("hit_stop_seconds", -1.0)) >= 0.0, "hit-stop cannot be negative")
        TestUtils.assert_true(float(data.get("hit_stop_seconds", 1.0)) <= 0.06, "hit-stop must stay responsive")
        TestUtils.assert_true(float(data.get("shake_seconds", 0.0)) > 0.0, "camera shake needs duration")
        TestUtils.assert_true(float(data.get("death_burst_scale", 0.0)) >= 0.75, "death burst must remain readable")

    TestUtils.assert_true(float(standard.knockback_speed) > float(heavy.knockback_speed), "heavy enemies resist knockback")
    TestUtils.assert_true(float(heavy.knockback_speed) > float(boss.knockback_speed), "boss resists knockback most")
    TestUtils.assert_true(float(boss.shake_strength) > float(heavy.shake_strength), "boss hits shake harder than heavy enemies")
    TestUtils.assert_true(float(heavy.shake_strength) > float(standard.shake_strength), "heavy hits shake harder than standard enemies")
    TestUtils.assert_true(float(boss.death_burst_scale) > float(heavy.death_burst_scale), "boss death burst is largest")

    var fallback: Dictionary = Profile.profile(&"unknown")
    TestUtils.assert_eq(fallback, standard, "unknown enemy feedback falls back to standard")
