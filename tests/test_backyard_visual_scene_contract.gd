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
        "BaseVisual/Cracks",
        "BaseVisual/Smoke",
        "BaseVisual/Debris",
        "BaseVisual/ElectricOverlay",
        "BootstrapUI/BossAlert",
        "BootstrapUI/BaseHealthBar",
        "BootstrapUI/BaseHealthBar/Fill",
        "BootstrapUI/BaseHealthBar/Label",
    ]
    for node_path in required:
        TestUtils.assert_true(scene.has_node(node_path), "backyard preview must contain %s" % node_path)

    TestUtils.assert_true(not (scene.get_node("BaseVisual/Cracks") as CanvasItem).visible, "cracks should start hidden")
    TestUtils.assert_true(not (scene.get_node("BaseVisual/Smoke") as CanvasItem).visible, "smoke should start hidden")
    TestUtils.assert_true(not (scene.get_node("BaseVisual/Debris") as CanvasItem).visible, "debris should start hidden")
    TestUtils.assert_true(not (scene.get_node("BaseVisual/ElectricOverlay") as CanvasItem).visible, "electric overlay should start hidden")
    scene.free()
