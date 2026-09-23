extends RefCounted

const TestUtils = preload("res://tests/test_utils.gd")
const UpgradePath := "res://scripts/gameplay/between_wave_upgrade_profile.gd"
const WavePath := "res://scripts/gameplay/wave_progression_profile.gd"

func run() -> void:
    TestUtils.assert_true(ResourceLoader.exists(UpgradePath), "between-wave upgrade profile must exist")
    TestUtils.assert_true(ResourceLoader.exists(WavePath), "wave profile must exist for affordability checks")
    if not ResourceLoader.exists(UpgradePath) or not ResourceLoader.exists(WavePath):
        return

    var Upgrade = load(UpgradePath)
    var Waves = load(WavePath)
    TestUtils.assert_true(Upgrade != null and Upgrade.can_instantiate(), "between-wave upgrade profile must instantiate")
    if Upgrade == null or not Upgrade.can_instantiate():
        return

    for completed_wave in range(1, 5):
        var offers: Array = Upgrade.offer_slots_after_wave(completed_wave)
        TestUtils.assert_eq(offers.size(), 3, "each intermission presents exactly three strategic lanes")

        var categories: Array[StringName] = []
        var reward := int(Waves.wave(completed_wave).reward_coins)
        for offer in offers:
            var data: Dictionary = offer
            var category: StringName = data.get("category", &"")
            categories.append(category)
            TestUtils.assert_true((data.get("upgrade_pool", []) as Array).size() >= 2, "each lane has multiple upgrade candidates")
            TestUtils.assert_true(int(data.get("cost", 999999)) <= reward, "each strategic lane has an affordable option from current wave reward")

        TestUtils.assert_true(categories.has(&"hero"), "intermission includes hero power lane")
        TestUtils.assert_true(categories.has(&"base"), "intermission includes base defense lane")
        TestUtils.assert_true(categories.has(&"utility"), "intermission includes utility/recovery lane")

    var finale: Array = Upgrade.offer_slots_after_wave(5)
    TestUtils.assert_eq(finale.size(), 0, "no upgrade shop is shown after the final boss wave")

    var hero_pool: Array = Upgrade.pool_for(&"hero")
    TestUtils.assert_true(hero_pool.has(&"golden_slipper") and hero_pool.has(&"super_soaker"), "hero lane includes established weapon upgrades")

    var base_pool: Array = Upgrade.pool_for(&"base")
    TestUtils.assert_true(base_pool.has(&"electric_fence") and base_pool.has(&"base_fortification"), "base lane includes established defense upgrades")

    var utility_pool: Array = Upgrade.pool_for(&"utility")
    TestUtils.assert_true(utility_pool.has(&"emergency_repair"), "utility lane includes recovery option")
