extends RefCounted

const TestUtils = preload("res://tests/test_utils.gd")
const ResolverPath := "res://scripts/art/defense_visual_state_resolver.gd"

func run() -> void:
    TestUtils.assert_true(ResourceLoader.exists(ResolverPath), "defense visual state resolver must exist")
    if not ResourceLoader.exists(ResolverPath):
        return

    var Resolver = load(ResolverPath)
    TestUtils.assert_true(Resolver != null and Resolver.can_instantiate(), "defense visual state resolver must instantiate")
    if Resolver == null or not Resolver.can_instantiate():
        return

    TestUtils.assert_eq(Resolver.resolve_health_state(100.0, 100.0), "fresh", "full health is fresh")
    TestUtils.assert_eq(Resolver.resolve_health_state(67.0, 100.0), "fresh", "above damaged threshold stays fresh")
    TestUtils.assert_eq(Resolver.resolve_health_state(66.0, 100.0), "damaged", "damaged threshold is inclusive")
    TestUtils.assert_eq(Resolver.resolve_health_state(34.0, 100.0), "damaged", "mid health stays damaged")
    TestUtils.assert_eq(Resolver.resolve_health_state(33.0, 100.0), "critical", "critical threshold is inclusive")
    TestUtils.assert_eq(Resolver.resolve_health_state(1.0, 100.0), "critical", "low positive health is critical")
    TestUtils.assert_eq(Resolver.resolve_health_state(0.0, 100.0), "broken", "zero health is broken")

    var fresh: Dictionary = Resolver.build_visual_flags(100.0, 100.0, false, 0)
    TestUtils.assert_true(not fresh.show_cracks and not fresh.show_smoke and not fresh.show_debris, "fresh defense has no damage overlays")

    var damaged: Dictionary = Resolver.build_visual_flags(50.0, 100.0, false, 1)
    TestUtils.assert_true(damaged.show_cracks, "damaged defense shows cracks")
    TestUtils.assert_true(not damaged.show_smoke, "damaged defense does not smoke yet")
    TestUtils.assert_eq(damaged.upgrade_level, 1, "upgrade level is preserved")

    var critical: Dictionary = Resolver.build_visual_flags(20.0, 100.0, true, 2)
    TestUtils.assert_true(critical.show_cracks and critical.show_smoke, "critical defense shows cracks and smoke")
    TestUtils.assert_true(critical.show_electric, "live electrified defense shows electric overlay")

    var broken: Dictionary = Resolver.build_visual_flags(0.0, 100.0, true, 99)
    TestUtils.assert_true(broken.show_debris, "broken defense shows debris")
    TestUtils.assert_true(not broken.show_electric, "broken defense disables electric overlay")
    TestUtils.assert_eq(broken.upgrade_level, 3, "upgrade level is clamped to supported visual tiers")
