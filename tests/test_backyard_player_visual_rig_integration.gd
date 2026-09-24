extends RefCounted

const TestUtils = preload("res://tests/test_utils.gd")

func run() -> void:
    var source := FileAccess.get_file_as_string("res://scripts/player/player.gd")
    TestUtils.assert_true(source.contains("const PlayerVisualRig = preload(\"res://scripts/player/player_visual_rig.gd\")"), "BackyardPlayer must preload PlayerVisualRig")
    TestUtils.assert_true(source.contains("return PlayerVisualRig.response_for_event(event_name, action)"), "BackyardPlayer feedback lookup must delegate to PlayerVisualRig")
    TestUtils.assert_true(source.contains("return PlayerVisualRig.cleanup_for_action(action)"), "BackyardPlayer feedback cleanup must delegate to PlayerVisualRig")
    TestUtils.assert_true(source.contains("response.get(\"hurt_flash_color\""), "BackyardPlayer must consume hurt flash color from PlayerVisualRig response")
    TestUtils.assert_true(not source.contains("const WEAPON_RECOIL_PX"), "BackyardPlayer must not duplicate recoil tuning owned by PlayerVisualRig")
    TestUtils.assert_true(not source.contains("const DASH_TRAIL_PEAK_SCALE"), "BackyardPlayer must not duplicate dash trail tuning owned by PlayerVisualRig")
    TestUtils.assert_true(not source.contains("const HURT_FLASH_COLOR"), "BackyardPlayer must not duplicate hurt flash tuning owned by PlayerVisualRig")
