extends RefCounted

const TestUtils = preload("res://tests/test_utils.gd")

func run() -> void:
    var resolver_path := "res://scripts/art/enemy_animation_state_resolver.gd"
    TestUtils.assert_true(ResourceLoader.exists(resolver_path), "enemy animation state resolver must exist")
    if not ResourceLoader.exists(resolver_path):
        return

    var Resolver = load(resolver_path)

    TestUtils.assert_eq(Resolver.resolve_action(false), "idle", "stationary enemy uses idle")
    TestUtils.assert_eq(Resolver.resolve_action(true), "run", "moving enemy uses run")
    TestUtils.assert_eq(Resolver.resolve_action(true, true), "attack", "attack overrides locomotion")
    TestUtils.assert_eq(Resolver.resolve_action(true, true, true), "hurt", "hurt interrupts attack")
    TestUtils.assert_eq(Resolver.resolve_action(true, true, true, true), "death", "death has highest priority")

    TestUtils.assert_eq(
        Resolver.resolve_action(true, false, false, false, "attack", false),
        "attack",
        "unfinished attack is not interrupted by run"
    )
    TestUtils.assert_eq(
        Resolver.resolve_action(false, false, false, false, "attack", false),
        "attack",
        "unfinished attack is not interrupted by idle"
    )
    TestUtils.assert_eq(
        Resolver.resolve_action(true, false, true, false, "attack", false),
        "hurt",
        "hurt may interrupt attack"
    )
    TestUtils.assert_eq(
        Resolver.resolve_action(true, false, false, true, "hurt", false),
        "death",
        "death may interrupt hurt"
    )
    TestUtils.assert_eq(
        Resolver.resolve_action(true, false, false, false, "attack", true),
        "run",
        "finished attack releases back to locomotion"
    )
