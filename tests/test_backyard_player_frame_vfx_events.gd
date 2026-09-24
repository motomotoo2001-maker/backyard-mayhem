extends RefCounted

const TestUtils = preload("res://tests/test_utils.gd")
const PlayerScript = preload("res://scripts/player/player.gd")

func run() -> void:
    var player = PlayerScript.new()

    TestUtils.assert_true(player.has_signal("animation_vfx_event"), "BackyardPlayer must expose frame-synced animation VFX signal")
    if not player.has_method("_frame_vfx_events"):
        TestUtils.failures.append("BackyardPlayer must expose deterministic frame VFX lookup")
        player.free()
        return

    var fire_events: Array[StringName] = player._frame_vfx_events(&"fire_front_right", 1)
    TestUtils.assert_true(fire_events.has(&"muzzle"), "fire contact frame should emit muzzle")
    TestUtils.assert_true(fire_events.has(&"recoil_peak"), "fire contact frame should emit recoil peak")
    TestUtils.assert_true(fire_events.has(&"air_blast"), "fire contact frame should emit air blast")

    var dash_events: Array[StringName] = player._frame_vfx_events(&"dash_left", 0)
    TestUtils.assert_true(dash_events.has(&"trail_start"), "dash frame zero should emit trail start")

    var hurt_events: Array[StringName] = player._frame_vfx_events(&"hurt_back", 0)
    TestUtils.assert_true(hurt_events.has(&"impact"), "hurt frame zero should emit impact")

    var run_events: Array[StringName] = player._frame_vfx_events(&"run_front", 1)
    TestUtils.assert_eq(run_events.size(), 0, "run animation should not emit combat VFX events")

    player.free()
