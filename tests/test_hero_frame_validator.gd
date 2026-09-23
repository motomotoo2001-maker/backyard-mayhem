extends RefCounted

const TestUtils = preload("res://tests/test_utils.gd")

func run() -> void:
    var validator_path := "res://scripts/art/hero_frame_validator.gd"
    TestUtils.assert_true(ResourceLoader.exists(validator_path), "hero frame validator must exist")
    if not ResourceLoader.exists(validator_path):
        return

    var Validator = load(validator_path)

    var good := Image.create(320, 320, false, Image.FORMAT_RGBA8)
    good.fill(Color(0, 0, 0, 0))
    good.fill_rect(Rect2i(24, 24, 272, 278), Color.WHITE)
    var good_result: Dictionary = Validator.validate_image(good)
    TestUtils.assert_true(good_result.get("ok", false), "well-padded hero frame must pass")

    var clipped_top := Image.create(320, 320, false, Image.FORMAT_RGBA8)
    clipped_top.fill(Color(0, 0, 0, 0))
    clipped_top.fill_rect(Rect2i(24, 0, 272, 302), Color.WHITE)
    var top_result: Dictionary = Validator.validate_image(clipped_top)
    TestUtils.assert_true(not top_result.get("ok", true), "frame touching top edge must fail")

    var clipped_bottom := Image.create(320, 320, false, Image.FORMAT_RGBA8)
    clipped_bottom.fill(Color(0, 0, 0, 0))
    clipped_bottom.fill_rect(Rect2i(24, 24, 272, 296), Color.WHITE)
    var bottom_result: Dictionary = Validator.validate_image(clipped_bottom)
    TestUtils.assert_true(not bottom_result.get("ok", true), "frame touching bottom edge must fail")

    var wrong_size := Image.create(256, 256, false, Image.FORMAT_RGBA8)
    wrong_size.fill(Color(0, 0, 0, 0))
    wrong_size.fill_rect(Rect2i(20, 20, 216, 220), Color.WHITE)
    var size_result: Dictionary = Validator.validate_image(wrong_size)
    TestUtils.assert_true(not size_result.get("ok", true), "non-320x320 frame must fail")

    var empty := Image.create(320, 320, false, Image.FORMAT_RGBA8)
    empty.fill(Color(0, 0, 0, 0))
    var empty_result: Dictionary = Validator.validate_image(empty)
    TestUtils.assert_true(not empty_result.get("ok", true), "fully transparent frame must fail")

    # Visual QA regression: label fragments / crop debris may sit safely inside
    # the outer margins, so bounds-only validation cannot detect them.
    var detached_artifact := Image.create(320, 320, false, Image.FORMAT_RGBA8)
    detached_artifact.fill(Color(0, 0, 0, 0))
    detached_artifact.fill_rect(Rect2i(110, 40, 100, 250), Color.WHITE)
    detached_artifact.fill_rect(Rect2i(28, 44, 18, 12), Color.WHITE)
    var artifact_result: Dictionary = Validator.validate_image(detached_artifact)
    TestUtils.assert_true(not artifact_result.get("ok", true), "large detached alpha artifact must fail")
    TestUtils.assert_true(artifact_result.get("errors", []).has("detached_alpha_artifact"), "detached artifact must report a dedicated error")

    # A couple of antialias/noise pixels can appear during export and should not
    # reject an otherwise clean frame.
    var tiny_noise := Image.create(320, 320, false, Image.FORMAT_RGBA8)
    tiny_noise.fill(Color(0, 0, 0, 0))
    tiny_noise.fill_rect(Rect2i(110, 40, 100, 250), Color.WHITE)
    tiny_noise.fill_rect(Rect2i(28, 44, 2, 2), Color.WHITE)
    var tiny_noise_result: Dictionary = Validator.validate_image(tiny_noise)
    TestUtils.assert_true(tiny_noise_result.get("ok", false), "tiny detached alpha noise must be tolerated")

    var anchor_a := Image.create(320, 320, false, Image.FORMAT_RGBA8)
    anchor_a.fill(Color(0, 0, 0, 0))
    anchor_a.fill_rect(Rect2i(30, 30, 260, 274), Color.WHITE)
    var anchor_b := Image.create(320, 320, false, Image.FORMAT_RGBA8)
    anchor_b.fill(Color(0, 0, 0, 0))
    anchor_b.fill_rect(Rect2i(30, 28, 260, 276), Color.WHITE)
    var stable: Dictionary = Validator.validate_sequence([anchor_a, anchor_b], 3)
    TestUtils.assert_true(stable.get("ok", false), "small ground-anchor drift must pass")

    var anchor_bad := Image.create(320, 320, false, Image.FORMAT_RGBA8)
    anchor_bad.fill(Color(0, 0, 0, 0))
    anchor_bad.fill_rect(Rect2i(30, 20, 260, 288), Color.WHITE)
    var unstable: Dictionary = Validator.validate_sequence([anchor_a, anchor_bad], 3)
    TestUtils.assert_true(not unstable.get("ok", true), "large ground-anchor drift must fail")
