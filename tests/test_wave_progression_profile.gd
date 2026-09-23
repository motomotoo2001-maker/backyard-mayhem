extends RefCounted

const TestUtils = preload("res://tests/test_utils.gd")
const ProfilePath := "res://scripts/gameplay/wave_progression_profile.gd"

func run() -> void:
    TestUtils.assert_true(ResourceLoader.exists(ProfilePath), "wave progression profile must exist")
    if not ResourceLoader.exists(ProfilePath):
        return

    var Profile = load(ProfilePath)
    TestUtils.assert_true(Profile != null and Profile.can_instantiate(), "wave progression profile must instantiate")
    if Profile == null or not Profile.can_instantiate():
        return

    TestUtils.assert_eq(Profile.wave_count(), 5, "vertical slice has exactly five waves")

    var previous_budget := 0
    var previous_reward := 0
    for wave_number in range(1, 6):
        var wave: Dictionary = Profile.wave(wave_number)
        TestUtils.assert_eq(int(wave.number), wave_number, "wave number is stable")
        TestUtils.assert_true(int(wave.threat_budget) > previous_budget, "threat budget rises every wave")
        TestUtils.assert_true(int(wave.reward_coins) >= previous_reward, "between-wave reward never decreases")
        TestUtils.assert_true(float(wave.intermission_seconds) >= 8.0, "player gets enough time to read upgrade choice")
        previous_budget = int(wave.threat_budget)
        previous_reward = int(wave.reward_coins)

    var wave1: Dictionary = Profile.wave(1)
    TestUtils.assert_true((wave1.enemy_pool as Array).has(&"raccoon"), "wave 1 teaches basic raccoon pressure")
    TestUtils.assert_true(not (wave1.enemy_pool as Array).has(&"boss"), "boss never appears in wave 1")

    var wave2: Dictionary = Profile.wave(2)
    TestUtils.assert_true((wave2.enemy_pool as Array).has(&"cat"), "wave 2 introduces fast burst enemy")

    var wave3: Dictionary = Profile.wave(3)
    TestUtils.assert_true((wave3.enemy_pool as Array).has(&"bulldog"), "wave 3 introduces heavy enemy")
    TestUtils.assert_true((wave3.enemy_pool as Array).has(&"pigeon"), "wave 3 introduces aerial pressure")

    var wave4: Dictionary = Profile.wave(4)
    TestUtils.assert_true((wave4.enemy_pool as Array).has(&"neighbor_kid"), "wave 4 introduces ranged pressure")
    TestUtils.assert_true((wave4.enemy_pool as Array).has(&"skateboard_teen"), "wave 4 introduces mobile lane pressure")

    var wave5: Dictionary = Profile.wave(5)
    TestUtils.assert_true((wave5.enemy_pool as Array).has(&"boss"), "wave 5 contains boss")
    TestUtils.assert_true(bool(wave5.is_boss_wave), "wave 5 is explicitly marked boss wave")
    TestUtils.assert_true(int(wave5.reward_coins) >= 300, "boss wave gives milestone reward")

    var fallback: Dictionary = Profile.wave(99)
    TestUtils.assert_eq(int(fallback.number), 5, "out-of-range wave requests clamp to finale")
