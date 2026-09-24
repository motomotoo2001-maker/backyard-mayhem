extends RefCounted

const TestUtils = preload("res://tests/test_utils.gd")
const BackyardScene = preload("res://scenes/levels/backyard.tscn")

func run() -> void:
    var backyard := BackyardScene.instantiate()
    var header := backyard.get_node("BootstrapUI/Header") as Control
    var alert := backyard.get_node("BootstrapUI/BossAlert") as Control

    var header_rect := Rect2(header.position, header.size)
    var alert_rect := Rect2(alert.position, alert.size)

    TestUtils.assert_true(not header_rect.intersects(alert_rect), "Boss Alert must not overlap the main Header card")
    TestUtils.assert_true(alert_rect.position.x >= 680.0, "Boss Alert should live in the upper-right safe area")
    TestUtils.assert_true(alert_rect.position.y >= 16.0 and alert_rect.end.y <= 92.0, "Boss Alert must stay inside the top safe band")
    TestUtils.assert_true(alert_rect.end.x <= 1232.0, "Boss Alert must keep a right-side safe margin")

    backyard.free()
