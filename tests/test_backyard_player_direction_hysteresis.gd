extends RefCounted

const TestUtils = preload("res://tests/test_utils.gd")
const PlayerScript = preload("res://scripts/player/player.gd")

func run() -> void:
    var player = PlayerScript.new()

    TestUtils.assert_eq(player._resolve_direction_suffix(&"run", Vector2.RIGHT), "right", "player should face right on a rightward run")

    var near_right_boundary := Vector2.from_angle(deg_to_rad(25.0))
    TestUtils.assert_eq(
        player._resolve_direction_suffix(&"run", near_right_boundary),
        "right",
        "player should retain right near the right/front-right boundary instead of flickering"
    )

    var committed_front_right := Vector2.from_angle(deg_to_rad(35.0))
    TestUtils.assert_eq(
        player._resolve_direction_suffix(&"run", committed_front_right),
        "front_right",
        "player should switch to front-right after leaving the hysteresis band"
    )

    TestUtils.assert_eq(player._resolve_direction_suffix(&"idle", Vector2.ZERO), "front_right", "idle should preserve the last committed facing direction")
    player.free()
