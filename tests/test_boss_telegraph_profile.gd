extends RefCounted

const TestUtils = preload("res://tests/test_utils.gd")
const ProfilePath := "res://scripts/art/boss_telegraph_profile.gd"

func run() -> void:
    TestUtils.assert_true(ResourceLoader.exists(ProfilePath), "boss telegraph profile must exist")
    if not ResourceLoader.exists(ProfilePath):
        return

    var Profile = load(ProfilePath)
    TestUtils.assert_true(Profile != null and Profile.can_instantiate(), "boss telegraph profile must instantiate")
    if Profile == null or not Profile.can_instantiate():
        return

    var swing: Dictionary = Profile.for_attack(&"heavy_swing")
    TestUtils.assert_true(float(swing.windup_seconds) >= 0.40, "heavy swing gives readable reaction time")
    TestUtils.assert_true(float(swing.telegraph_radius) >= 90.0, "heavy swing telegraph is visible around boss")
    TestUtils.assert_eq(swing.pulse_count, 2, "heavy swing uses two anticipation pulses")
    TestUtils.assert_true(float(swing.impact_shake) > 0.0, "heavy swing has impact feedback")

    var slam: Dictionary = Profile.for_attack(&"radial_slam")
    TestUtils.assert_true(float(slam.windup_seconds) > float(swing.windup_seconds), "radial slam has longer anticipation than swing")
    TestUtils.assert_true(float(slam.telegraph_radius) > float(swing.telegraph_radius), "radial slam communicates larger danger area")
    TestUtils.assert_true(int(slam.pulse_count) >= 3, "radial slam uses escalating pulses")
    TestUtils.assert_true(float(slam.impact_shake) > float(swing.impact_shake), "radial slam impact feels heavier")

    var fallback: Dictionary = Profile.for_attack(&"unknown")
    TestUtils.assert_true(float(fallback.windup_seconds) > 0.0, "unknown boss attacks still get a safe readable fallback")
