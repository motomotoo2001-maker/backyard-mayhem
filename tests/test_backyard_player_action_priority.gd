extends RefCounted

const TestUtils = preload("res://tests/test_utils.gd")
const PlayerScript = preload("res://scripts/player/player.gd")

func run() -> void:
    var player = PlayerScript.new()
    if not player.has_method("_should_hold_action_animation"):
        TestUtils.failures.append("BackyardPlayer must expose deterministic action-priority hold logic")
        player.free()
        return

    player._action_animation = &"fire_front_right"
    TestUtils.assert_true(player._should_hold_action_animation(&"run"), "fire should finish before returning to run")
    TestUtils.assert_true(not player._should_hold_action_animation(&"dash"), "dash should interrupt fire")
    TestUtils.assert_true(not player._should_hold_action_animation(&"build"), "build should interrupt fire")

    player._action_animation = &"build_front_right"
    TestUtils.assert_true(player._should_hold_action_animation(&"fire"), "build should not be interrupted by lower-priority fire")
    TestUtils.assert_true(not player._should_hold_action_animation(&"dash"), "dash should interrupt build")

    player._action_animation = &"hurt_front_right"
    TestUtils.assert_true(player._should_hold_action_animation(&"dash"), "hurt should not be interrupted by dash")

    player._action_animation = &"death_front_right"
    TestUtils.assert_true(player._should_hold_action_animation(&"hurt"), "death should remain the highest-priority action")

    player.free()
