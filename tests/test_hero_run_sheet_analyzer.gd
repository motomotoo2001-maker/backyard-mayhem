extends RefCounted

const TestUtils = preload("res://tests/test_utils.gd")
const HeroRunSheetAnalyzer = preload("res://scripts/art/hero_run_sheet_analyzer.gd")

func run() -> void:
    var image := Image.create(180, 140, false, Image.FORMAT_RGBA8)
    image.fill(Color.WHITE)

    # Two authored character rows with a short RUN-style label between them.
    _fill_rect(image, Rect2i(10, 8, 28, 34), Color(0.18, 0.12, 0.08, 1.0))
    _fill_rect(image, Rect2i(48, 6, 26, 38), Color(0.26, 0.18, 0.12, 1.0))
    _fill_rect(image, Rect2i(14, 55, 34, 5), Color(0.08, 0.08, 0.08, 1.0))
    _fill_rect(image, Rect2i(12, 78, 30, 40), Color(0.20, 0.14, 0.10, 1.0))
    _fill_rect(image, Rect2i(55, 76, 28, 44), Color(0.30, 0.20, 0.12, 1.0))

    var bands: Array[Rect2i] = HeroRunSheetAnalyzer.find_character_bands(image, 8, 20)
    TestUtils.assert_eq(bands.size(), 2, "short RUN labels must not become character rows")
    TestUtils.assert_true(bands[0].position.y <= 8 and bands[0].end.y >= 42, "first authored row must preserve full character height")
    TestUtils.assert_true(bands[1].position.y <= 78 and bands[1].end.y >= 118, "second authored row must preserve full character height")

    var frame_image := Image.create(180, 80, false, Image.FORMAT_RGBA8)
    frame_image.fill(Color.WHITE)
    # Frame A has a small internal horizontal gap (body vs. extended nozzle).
    _fill_rect(frame_image, Rect2i(8, 12, 20, 48), Color(0.2, 0.1, 0.1, 1.0))
    _fill_rect(frame_image, Rect2i(33, 24, 13, 18), Color(0.2, 0.1, 0.1, 1.0))
    # Frame B is clearly separated.
    _fill_rect(frame_image, Rect2i(82, 10, 26, 52), Color(0.2, 0.1, 0.1, 1.0))
    # A low label inside the row should not become a frame.
    _fill_rect(frame_image, Rect2i(128, 62, 30, 4), Color(0.05, 0.05, 0.05, 1.0))

    var frames: Array[Rect2i] = HeroRunSheetAnalyzer.find_frame_boxes(
        frame_image,
        Rect2i(0, 0, 180, 72),
        0.20,
        12,
        8
    )
    TestUtils.assert_eq(frames.size(), 2, "frame detection must merge small internal gaps and ignore low labels")
    TestUtils.assert_true(frames[0].position.x <= 8 and frames[0].end.x >= 46, "extended weapon must stay attached to its character frame")
    TestUtils.assert_true(frames[1].position.x <= 82 and frames[1].end.x >= 108, "second character frame must remain independent")

func _fill_rect(image: Image, rect: Rect2i, color: Color) -> void:
    for y in range(rect.position.y, rect.end.y):
        for x in range(rect.position.x, rect.end.x):
            image.set_pixel(x, y, color)
