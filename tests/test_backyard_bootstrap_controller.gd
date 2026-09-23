extends RefCounted

const TestUtils = preload("res://tests/test_utils.gd")

func run() -> void:
    var script_path := "res://scripts/gameplay/backyard_bootstrap_controller.gd"
    if not ResourceLoader.exists(script_path):
        TestUtils.failures.append("backyard bootstrap controller must exist")
        return

    var script_resource = load(script_path)
    if script_resource == null or not script_resource is Script:
        TestUtils.failures.append("backyard bootstrap controller must load as Script")
        return

    var script: Script = script_resource as Script
    if not script.can_instantiate():
        TestUtils.failures.append("backyard bootstrap controller must instantiate")
        return

    var scene_resource = load("res://scenes/levels/backyard.tscn")
    TestUtils.assert_true(scene_resource is PackedScene, "backyard scene should load as PackedScene")
    if not scene_resource is PackedScene:
        return

    var scene := (scene_resource as PackedScene).instantiate()
    TestUtils.assert_true(scene.get_script() == script, "backyard root should use bootstrap controller")
    TestUtils.assert_true(scene.has_node("BootstrapUI/Header/Title"), "preview should retain title label")
    TestUtils.assert_true(scene.has_node("BootstrapUI/Header/Subtitle"), "preview should retain subtitle label")
    TestUtils.assert_true(scene.has_node("BootstrapUI/Status"), "preview should retain runtime status label")
    TestUtils.assert_true(scene.has_node("BootstrapUI/Footer"), "preview should retain controls footer")
    scene.free()
