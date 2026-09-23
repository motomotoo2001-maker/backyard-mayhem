extends RefCounted

const TestUtils = preload("res://tests/test_utils.gd")
const PlayerScript = preload("res://scripts/player/player.gd")

func run() -> void:
    var player = PlayerScript.new()
    var sprite := AnimatedSprite2D.new()
    var frames := SpriteFrames.new()
    frames.add_animation(&"hurt_front_right")
    frames.add_animation(&"hurt")
    frames.add_animation(&"death_front_right")
    frames.add_animation(&"death")
    frames.add_animation(&"defeat")
    sprite.sprite_frames = frames
    player.animated_sprite = sprite

    TestUtils.assert_eq(
        player._resolve_animation_name(&"hurt", Vector2.ZERO),
        &"hurt_front_right",
        "hurt should prefer directional authored animation"
    )
    TestUtils.assert_eq(
        player._resolve_animation_name(&"death", Vector2.ZERO),
        &"death_front_right",
        "death should prefer directional authored animation"
    )

    frames.remove_animation(&"hurt_front_right")
    TestUtils.assert_eq(
        player._resolve_animation_name(&"hurt", Vector2.ZERO),
        &"hurt",
        "hurt should fall back to generic hurt"
    )

    frames.remove_animation(&"death_front_right")
    TestUtils.assert_eq(
        player._resolve_animation_name(&"death", Vector2.ZERO),
        &"death",
        "death should fall back to generic death when directional frames are absent"
    )

    frames.remove_animation(&"death")
    TestUtils.assert_eq(
        player._resolve_animation_name(&"death", Vector2.ZERO),
        &"defeat",
        "death should preserve legacy defeat fallback until production death frames are integrated"
    )

    player.animated_sprite = null
    sprite.free()
    player.free()
