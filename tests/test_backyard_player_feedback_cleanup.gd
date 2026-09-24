extends RefCounted

const TestUtils = preload("res://tests/test_utils.gd")
const PlayerScript = preload("res://scripts/player/player.gd")

func run() -> void:
    var player = PlayerScript.new()
    if not player.has_method("_feedback_cleanup_for_action"):
        TestUtils.failures.append("BackyardPlayer must define cleanup for interrupted transient feedback")
        player.free()
        return

    var fire_cleanup: Dictionary = player._feedback_cleanup_for_action(&"fire")
    TestUtils.assert_true(bool(fire_cleanup.get("reset_weapon", false)), "interrupting fire must restore weapon recoil")

    var dash_cleanup: Dictionary = player._feedback_cleanup_for_action(&"dash")
    TestUtils.assert_true(bool(dash_cleanup.get("reset_dash_trail", false)), "interrupting dash must restore trail scale")

    var hurt_cleanup: Dictionary = player._feedback_cleanup_for_action(&"hurt")
    TestUtils.assert_true(bool(hurt_cleanup.get("clear_hurt_flash", false)), "interrupting hurt must clear damage flash")

    var run_cleanup: Dictionary = player._feedback_cleanup_for_action(&"run")
    TestUtils.assert_eq(run_cleanup.size(), 0, "locomotion should not require transient feedback cleanup")

    player.free()
