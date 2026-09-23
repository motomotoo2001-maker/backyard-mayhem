extends RefCounted

const TestUtils = preload("res://tests/test_utils.gd")
const ProfilePath := "res://scripts/art/base_upgrade_visual_profile.gd"

func run() -> void:
    TestUtils.assert_true(ResourceLoader.exists(ProfilePath), "base upgrade visual profile must exist")
    if not ResourceLoader.exists(ProfilePath):
        return

    var Profile = load(ProfilePath)
    TestUtils.assert_true(Profile != null and Profile.can_instantiate(), "base upgrade visual profile must instantiate")
    if Profile == null or not Profile.can_instantiate():
        return

    var tier0: Dictionary = Profile.for_level(0)
    TestUtils.assert_eq(tier0.level, 0, "tier 0 remains tier 0")
    TestUtils.assert_eq(tier0.turret_slots, 0, "tier 0 has no mounted defense")
    TestUtils.assert_true(not tier0.show_sandbags and not tier0.show_armor and not tier0.show_beacon, "tier 0 is visually simple")

    var tier1: Dictionary = Profile.for_level(1)
    TestUtils.assert_eq(tier1.turret_slots, 1, "tier 1 unlocks first turret socket")
    TestUtils.assert_true(tier1.show_sandbags, "tier 1 adds visible fortification")
    TestUtils.assert_true(not tier1.show_armor, "tier 1 does not jump straight to heavy armor")

    var tier2: Dictionary = Profile.for_level(2)
    TestUtils.assert_eq(tier2.turret_slots, 2, "tier 2 exposes two turret sockets")
    TestUtils.assert_true(tier2.show_sandbags and tier2.show_armor, "tier 2 visibly upgrades the silhouette")
    TestUtils.assert_true(tier2.show_power_cables, "tier 2 shows powered defense infrastructure")

    var tier3: Dictionary = Profile.for_level(3)
    TestUtils.assert_eq(tier3.turret_slots, 3, "tier 3 exposes three turret sockets")
    TestUtils.assert_true(tier3.show_beacon and tier3.show_power_coils, "tier 3 reads as the final powered fortress")
    TestUtils.assert_true(float(tier3.silhouette_scale) > float(tier2.silhouette_scale), "final tier silhouette grows visibly")

    var clamped: Dictionary = Profile.for_level(99)
    TestUtils.assert_eq(clamped.level, 3, "visual level clamps to supported maximum")
