extends RefCounted

const TestUtils = preload("res://tests/test_utils.gd")
const PlayerScript = preload("res://scripts/player/player.gd")

class DashStub:
    extends Node
    var active := false
    func is_active() -> bool:
        return active

func run() -> void:
    var player = PlayerScript.new()
    if not player.has_method("_select_animation_state"):
        TestUtils.failures.append("BackyardPlayer must expose _select_animation_state for deterministic visual-state selection")
        player.free()
        return

    var dash := DashStub.new()
    dash.active = true
    player.dash_component = dash
    TestUtils.assert_eq(StringName(player._select_animation_state(Vector2.RIGHT)), &"dash", "active dash should request dash animation state")

    var sprite := AnimatedSprite2D.new()
    var frames := SpriteFrames.new()
    frames.add_animation(&"run_right")
    frames.add_animation(&"dash_right")
    sprite.sprite_frames = frames
    player.animated_sprite = sprite

    TestUtils.assert_eq(player._resolve_animation_name(&"dash", Vector2.RIGHT), &"dash_right", "dash should use directional dash animation when available")

    frames.remove_animation(&"dash_right")
    TestUtils.assert_eq(player._resolve_animation_name(&"dash", Vector2.RIGHT), &"run_right", "dash should fall back to directional run until production dash frames are integrated")

    dash.active = false
    TestUtils.assert_eq(StringName(player._select_animation_state(Vector2.RIGHT)), &"run", "normal movement should return to run after dash")

    player.dash_component = null
    player.animated_sprite = null
    sprite.free()
    dash.free()
    player.free()
