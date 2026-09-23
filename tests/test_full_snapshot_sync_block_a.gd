extends RefCounted

const TestUtils = preload("res://tests/test_utils.gd")

func run() -> void:
    var player_path := "res://scripts/player/player.gd"
    TestUtils.assert_true(ResourceLoader.exists(player_path), "full snapshot sync block A should include real player.gd")
    if ResourceLoader.exists(player_path):
        var script_resource = load(player_path)
        TestUtils.assert_true(script_resource != null and script_resource is Script, "real player.gd should load as Script")
        if script_resource is Script:
            TestUtils.assert_true((script_resource as Script).can_instantiate(), "real player.gd should instantiate on Godot 4.7.2")

    TestUtils.assert_true(FileAccess.file_exists("res://tools/art/build_new_reference_hero.py"), "sync block A should include canonical hero build tool")
