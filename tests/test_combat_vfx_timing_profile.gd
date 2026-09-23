extends RefCounted

const TestUtils = preload("res://tests/test_utils.gd")

func run() -> void:
    var profile_path := "res://scripts/art/combat_vfx_timing_profile.gd"
    TestUtils.assert_true(ResourceLoader.exists(profile_path), "combat VFX timing profile must exist")
    if not ResourceLoader.exists(profile_path):
        return

    var Profile = load(profile_path)

    TestUtils.assert_eq(Profile.event_frame(&"fire", &"muzzle"), 1, "fire muzzle triggers on contact frame 1")
    TestUtils.assert_eq(Profile.event_frame(&"fire", &"recoil_peak"), 1, "fire recoil peaks with muzzle")
    TestUtils.assert_eq(Profile.event_frame(&"fire", &"air_blast"), 1, "air blast matches muzzle frame")
    TestUtils.assert_eq(Profile.event_frame(&"fire", &"recovery"), 3, "fire recovery uses final frame")

    TestUtils.assert_eq(Profile.event_frame(&"dash", &"trail_start"), 0, "dash trail starts immediately")
    TestUtils.assert_eq(Profile.event_frame(&"dash", &"trail_peak"), 1, "dash trail peaks after launch")
    TestUtils.assert_eq(Profile.event_frame(&"dash", &"trail_end"), 3, "dash trail ends on final frame")

    TestUtils.assert_eq(Profile.event_frame(&"hurt", &"impact"), 0, "hurt impact is immediate")
    TestUtils.assert_eq(Profile.event_frame(&"hurt", &"recovery"), 2, "hurt recovery uses final frame")

    TestUtils.assert_true(Profile.has_event(&"fire", &"muzzle"), "known event is discoverable")
    TestUtils.assert_true(not Profile.has_event(&"idle", &"muzzle"), "invalid action/event pair is rejected")
    TestUtils.assert_eq(Profile.event_frame(&"idle", &"muzzle"), -1, "invalid event frame returns -1")

    var muzzle_time := Profile.event_time_seconds(&"fire", &"muzzle")
    TestUtils.assert_true(absf(muzzle_time - (1.0 / 14.0)) < 0.0001, "muzzle timing derives from fire FPS")
    var dash_peak_time := Profile.event_time_seconds(&"dash", &"trail_peak")
    TestUtils.assert_true(absf(dash_peak_time - (1.0 / 18.0)) < 0.0001, "dash trail timing derives from canonical dash FPS")
