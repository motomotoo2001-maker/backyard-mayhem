extends RefCounted

const TestUtils = preload("res://tests/test_utils.gd")

func run() -> void:
    var scene_resource = load("res://scenes/levels/backyard.tscn")
    TestUtils.assert_true(scene_resource is PackedScene, "backyard visual scene should load")
    if not scene_resource is PackedScene:
        return

    var scene := (scene_resource as PackedScene).instantiate()
    var required := [
        "BaseVisual",
        "BaseVisual/Core",
        "BaseVisual/Sandbags",
        "BaseVisual/Armor",
        "BaseVisual/PowerCable",
        "BaseVisual/Beacon",
        "BaseVisual/PowerCoils",
        "BaseVisual/TurretSocket1",
        "BaseVisual/TurretSocket2",
        "BaseVisual/TurretSocket3",
        "BootstrapUI/BossAlert",
    ]
    for node_path in required:
        TestUtils.assert_true(scene.has_node(node_path), "backyard preview must contain %s" % node_path)
    scene.free()
