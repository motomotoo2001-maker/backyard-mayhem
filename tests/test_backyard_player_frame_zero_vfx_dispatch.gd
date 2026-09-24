extends RefCounted

const TestUtils = preload("res://tests/test_utils.gd")
const PlayerScript = preload("res://scripts/player/player.gd")

func run() -> void:
    var player = PlayerScript.new()
    if not player.has_method("_dispatch_current_frame_vfx_events"):
        TestUtils.failures.append("BackyardPlayer must explicitly dispatch frame-zero VFX events")
        player.free()
        return

    var sprite := AnimatedSprite2D.new()
    var frames := SpriteFrames.new()
    frames.add_animation(&"dash_left")
    frames.add_frame(&"dash_left", ImageTexture.new())
    frames.add_animation(&"hurt_back")
    frames.add_frame(&"hurt_back", ImageTexture.new())
    sprite.sprite_frames = frames
    player.animated_sprite = sprite

    var emitted: Array[StringName] = []
    player.animation_vfx_event.connect(func(event_name: StringName, _action: StringName, _frame: int) -> void:
        emitted.append(event_name)
    )

    sprite.animation = &"dash_left"
    sprite.frame = 0
    player._dispatch_current_frame_vfx_events()
    TestUtils.assert_true(emitted.has(&"trail_start"), "dash animation start must dispatch frame-zero trail_start")

    var count_after_first := emitted.size()
    player._dispatch_current_frame_vfx_events()
    TestUtils.assert_eq(emitted.size(), count_after_first, "same animation/frame events must not dispatch twice")

    sprite.animation = &"hurt_back"
    sprite.frame = 0
    player._dispatch_current_frame_vfx_events()
    TestUtils.assert_true(emitted.has(&"impact"), "hurt animation start must dispatch frame-zero impact")

    sprite.free()
    player.free()
