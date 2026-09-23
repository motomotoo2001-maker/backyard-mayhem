extends RefCounted

const TestUtils = preload("res://tests/test_utils.gd")

func run() -> void:
    var resolver_path := "res://scripts/art/hero_direction_resolver.gd"
    TestUtils.assert_true(ResourceLoader.exists(resolver_path), "hero direction resolver must exist")
    if not ResourceLoader.exists(resolver_path):
        return

    var Resolver = load(resolver_path)

    TestUtils.assert_eq(Resolver.resolve(Vector2(0, 1)), "front", "down-screen movement maps to front")
    TestUtils.assert_eq(Resolver.resolve(Vector2(1, 1)), "front_right", "down-right maps to front-right")
    TestUtils.assert_eq(Resolver.resolve(Vector2(1, 0)), "right", "right maps to right")
    TestUtils.assert_eq(Resolver.resolve(Vector2(1, -1)), "back_right", "up-right maps to back-right")
    TestUtils.assert_eq(Resolver.resolve(Vector2(0, -1)), "back", "up-screen movement maps to back")
    TestUtils.assert_eq(Resolver.resolve(Vector2(-1, -1)), "back_left", "up-left maps to back-left")
    TestUtils.assert_eq(Resolver.resolve(Vector2(-1, 0)), "left", "left maps to left")
    TestUtils.assert_eq(Resolver.resolve(Vector2(-1, 1)), "front_left", "down-left maps to front-left")

    TestUtils.assert_eq(Resolver.resolve(Vector2.ZERO, "back_left"), "back_left", "deadzone preserves previous facing")
    TestUtils.assert_eq(Resolver.resolve(Vector2(0.05, 0.03), "right", 0.15), "right", "small aim noise stays inside deadzone")

    var near_front_boundary := Vector2.RIGHT.rotated(deg_to_rad(65.0))
    TestUtils.assert_eq(
        Resolver.resolve(near_front_boundary, "front", 0.15, 6.0),
        "front",
        "hysteresis keeps front near front/front-right boundary"
    )

    var clearly_front_right := Vector2.RIGHT.rotated(deg_to_rad(55.0))
    TestUtils.assert_eq(
        Resolver.resolve(clearly_front_right, "front", 0.15, 6.0),
        "front_right",
        "direction changes after crossing hysteresis margin"
    )
