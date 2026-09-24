extends RefCounted

const TestUtils = preload("res://tests/test_utils.gd")

func _frame_with_pose(body_x: int, arm_side: int, leg_side: int, vertical_offset: int = 0) -> Image:
    var image := Image.create(96, 96, false, Image.FORMAT_RGBA8)
    image.fill(Color(0, 0, 0, 0))
    var white := Color.WHITE
    # Torso + head.
    image.fill_rect(Rect2i(body_x + 22, 20 + vertical_offset, 24, 38), white)
    image.fill_rect(Rect2i(body_x + 27, 10 + vertical_offset, 14, 14), white)
    # Arms change authored silhouette from frame to frame.
    if arm_side < 0:
        image.fill_rect(Rect2i(body_x + 12, 30 + vertical_offset, 12, 8), white)
        image.fill_rect(Rect2i(body_x + 44, 38 + vertical_offset, 8, 14), white)
    else:
        image.fill_rect(Rect2i(body_x + 44, 30 + vertical_offset, 12, 8), white)
        image.fill_rect(Rect2i(body_x + 16, 38 + vertical_offset, 8, 14), white)
    # Legs alternate stride.
    if leg_side < 0:
        image.fill_rect(Rect2i(body_x + 18, 56 + vertical_offset, 10, 24), white)
        image.fill_rect(Rect2i(body_x + 38, 56 + vertical_offset, 10, 18), white)
    else:
        image.fill_rect(Rect2i(body_x + 18, 56 + vertical_offset, 10, 18), white)
        image.fill_rect(Rect2i(body_x + 38, 56 + vertical_offset, 10, 24), white)
    return image

func run() -> void:
    var validator_path := "res://scripts/art/hero_run_motion_validator.gd"
    TestUtils.assert_true(ResourceLoader.exists(validator_path), "hero run motion validator must exist")
    if not ResourceLoader.exists(validator_path):
        return

    var Validator = load(validator_path)

    var identical: Array[Image] = []
    var base := _frame_with_pose(8, -1, -1)
    for _index in range(8):
        identical.append(base.duplicate())
    var identical_result: Dictionary = Validator.validate_sequence(identical)
    TestUtils.assert_true(not identical_result.get("ok", true), "eight duplicate run frames must fail motion diversity")
    TestUtils.assert_true(identical_result.get("errors", []).has("insufficient_pose_diversity"), "duplicate run frames must report pose diversity error")

    # Whole-body bob/translation is not authored pose change. BBox normalization
    # should remove these offsets before comparing silhouettes.
    var translated_only: Array[Image] = []
    for index in range(8):
        translated_only.append(_frame_with_pose(8 + (index % 2), -1, -1, (index % 3) - 1))
    var translated_result: Dictionary = Validator.validate_sequence(translated_only)
    TestUtils.assert_true(not translated_result.get("ok", true), "translation-only run must fail authored motion diversity")

    var authored: Array[Image] = []
    authored.append(_frame_with_pose(8, -1, -1))
    authored.append(_frame_with_pose(8, -1, 1))
    authored.append(_frame_with_pose(8, 1, 1))
    authored.append(_frame_with_pose(8, 1, -1))
    authored.append(_frame_with_pose(8, -1, -1))
    authored.append(_frame_with_pose(8, -1, 1))
    authored.append(_frame_with_pose(8, 1, 1))
    authored.append(_frame_with_pose(8, 1, -1))
    var authored_result: Dictionary = Validator.validate_sequence(authored)
    TestUtils.assert_true(authored_result.get("ok", false), "articulated authored run sequence must pass")
    TestUtils.assert_true(int(authored_result.get("distinct_pose_count", 0)) >= 4, "authored run must expose at least four distinct normalized silhouettes")
    TestUtils.assert_true(float(authored_result.get("mean_pose_delta", 0.0)) > 0.01, "authored run must have measurable normalized silhouette change")
