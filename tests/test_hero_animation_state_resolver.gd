extends RefCounted

const TestUtils = preload("res://tests/test_utils.gd")

func run() -> void:
    var resolver_path := "res://scripts/art/hero_animation_state_resolver.gd"
    TestUtils.assert_true(ResourceLoader.exists(resolver_path), "hero animation state resolver must exist")
    if not ResourceLoader.exists(resolver_path):
        return

    var Resolver = load(resolver_path)

    TestUtils.assert_eq(Resolver.resolve_action(false), "idle", "stationary hero uses idle")
    TestUtils.assert_eq(Resolver.resolve_action(true), "run", "moving hero uses run")
    TestUtils.assert_eq(Resolver.resolve_action(true, true), "fire", "fire overrides locomotion")
    TestUtils.assert_eq(Resolver.resolve_action(true, true, true), "build", "build outranks fire")
    TestUtils.assert_eq(Resolver.resolve_action(true, true, true, true), "dash", "dash outranks build/fire")
    TestUtils.assert_eq(Resolver.resolve_action(true, true, true, true, true), "hurt", "hurt outranks dash")
    TestUtils.assert_eq(Resolver.resolve_action(true, true, true, true, true, true), "death", "death has highest priority")

    TestUtils.assert_eq(
        Resolver.resolve_action(true, false, false, false, false, false, "fire", false),
        "fire",
        "unfinished fire animation is not interrupted by run"
    )
    TestUtils.assert_eq(
        Resolver.resolve_action(false, false, false, false, false, false, "build", false),
        "build",
        "unfinished build animation is not interrupted by idle"
    )
    TestUtils.assert_eq(
        Resolver.resolve_action(true, false, false, true, false, false, "fire", false),
        "dash",
        "higher-priority dash may interrupt fire"
    )
    TestUtils.assert_eq(
        Resolver.resolve_action(true, false, false, false, true, false, "dash", false),
        "hurt",
        "hurt may interrupt dash when damage is actually accepted"
    )
    TestUtils.assert_eq(
        Resolver.resolve_action(true, false, false, false, false, true, "hurt", false),
        "death",
        "death may interrupt every other animation"
    )
    TestUtils.assert_eq(
        Resolver.resolve_action(true, false, false, false, false, false, "fire", true),
        "run",
        "finished one-shot releases back to locomotion"
    )
