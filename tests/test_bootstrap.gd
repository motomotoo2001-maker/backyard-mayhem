extends RefCounted

const TestUtils = preload("res://tests/test_utils.gd")

func run() -> void:
    var scene := load("res://scenes/levels/backyard.tscn")
    TestUtils.assert_true(scene != null, "main backyard scene must load")
    TestUtils.assert_true(InputMap.has_action("move_left"), "move_left action exists")
    TestUtils.assert_true(InputMap.has_action("move_right"), "move_right action exists")
    TestUtils.assert_true(InputMap.has_action("move_up"), "move_up action exists")
    TestUtils.assert_true(InputMap.has_action("move_down"), "move_down action exists")
    TestUtils.assert_true(InputMap.has_action("fire"), "fire action exists")
    TestUtils.assert_true(InputMap.has_action("pause"), "pause action exists")
