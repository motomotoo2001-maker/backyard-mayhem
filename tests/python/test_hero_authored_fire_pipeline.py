import importlib.util
import tempfile
import unittest
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
MODULE_PATH = ROOT / "tools" / "art" / "hero_authored_fire_pipeline.py"


class HeroAuthoredFirePipelineTest(unittest.TestCase):
    DIRECTIONS = [
        "front",
        "front_right",
        "right",
        "back_right",
        "back",
        "back_left",
        "left",
        "front_left",
    ]
    LABEL_SENTINEL = (255, 0, 0, 255)

    def _load_pipeline(self):
        self.assertTrue(MODULE_PATH.is_file(), "authored FIRE pipeline module must exist")
        spec = importlib.util.spec_from_file_location("hero_authored_fire_pipeline", MODULE_PATH)
        self.assertIsNotNone(spec)
        self.assertIsNotNone(spec.loader if spec is not None else None)
        module = importlib.util.module_from_spec(spec)
        assert spec is not None and spec.loader is not None
        spec.loader.exec_module(module)
        return module

    def _draw_pose(self, draw, cx, top, row, col):
        body_w = 44 + ((row + col) % 5) * 3
        body_h = 74 + ((row * 2 + col) % 7) * 2
        left = cx - body_w // 2
        bottom = top + body_h
        color = (60 + row * 45, 90 + col * 11, 145 + ((row + col) % 4) * 18, 255)
        draw.rounded_rectangle((left, top, left + body_w, bottom - 14), radius=10, fill=color)
        draw.rectangle((left + 5, bottom - 16, cx - 3, bottom), fill=color)
        draw.rectangle((cx + 3, bottom - 16, left + body_w - 5, bottom), fill=color)
        # Detached leaf-blower nozzle / hose component near the body.
        nozzle_x = left + body_w + 8 + row * 2
        draw.rectangle((nozzle_x, top + 26, nozzle_x + 26 + col % 4, top + 33), fill=color)
        # Presentation label beneath the pose: wide + shallow and must be stripped.
        draw.rectangle((cx - 28, bottom + 7, cx + 28, bottom + 12), fill=self.LABEL_SENTINEL)

    def _build_sheet(self, path: Path):
        width, height = 1280, 540
        image = Image.new("RGBA", (width, height), (0, 0, 0, 0))
        draw = ImageDraw.Draw(image)
        bands = [(35, 165), (195, 325), (355, 485)]
        cell_w = width / 8.0
        for row, (y0, _y1) in enumerate(bands):
            for col in range(8):
                cx = round((col + 0.5) * cell_w)
                self._draw_pose(draw, cx, y0 + 8 + row * 2, row, col)
        image.save(path)
        return bands

    def _has_label_sentinel(self, image: Image.Image) -> bool:
        for r, g, b, a in image.getdata():
            if a > 12 and r > g + 100 and r > b + 100:
                return True
        return False

    def test_pipeline_module_exists(self):
        self.assertTrue(MODULE_PATH.is_file(), "authored FIRE pipeline module must exist")

    def test_builds_three_authored_fire_frames_per_direction_with_safe_anchor(self):
        pipeline = self._load_pipeline()
        with tempfile.TemporaryDirectory() as temp_dir:
            temp = Path(temp_dir)
            source = temp / "action_sheet.png"
            output = temp / "runtime"
            bands = self._build_sheet(source)
            built = pipeline.build_authored_fire_frames(
                source,
                output,
                directions=self.DIRECTIONS,
                row_bands=bands,
                canvas_size=320,
                ground_y=306,
            )
            self.assertEqual(24, len(built))
            expected = {
                f"fire_{direction}_{frame:02d}.png"
                for direction in self.DIRECTIONS
                for frame in range(3)
            }
            self.assertEqual(expected, {path.name for path in built})
            for frame_path in built:
                with Image.open(frame_path) as source_frame:
                    frame = source_frame.convert("RGBA")
                self.assertEqual((320, 320), frame.size)
                bbox = frame.getchannel("A").getbbox()
                self.assertIsNotNone(bbox)
                assert bbox is not None
                self.assertGreaterEqual(bbox[0], 8)
                self.assertGreaterEqual(bbox[1], 8)
                self.assertLessEqual(bbox[2], 312)
                self.assertEqual(306, bbox[3])
                self.assertFalse(self._has_label_sentinel(frame), f"label contamination in {frame_path.name}")

    def test_preserves_meaningful_pose_variation_for_every_direction(self):
        pipeline = self._load_pipeline()
        with tempfile.TemporaryDirectory() as temp_dir:
            temp = Path(temp_dir)
            source = temp / "action_sheet.png"
            output = temp / "runtime"
            bands = self._build_sheet(source)
            pipeline.build_authored_fire_frames(
                source,
                output,
                directions=self.DIRECTIONS,
                row_bands=bands,
                canvas_size=320,
                ground_y=306,
            )
            for direction in self.DIRECTIONS:
                payloads = []
                for frame in range(3):
                    with Image.open(output / f"fire_{direction}_{frame:02d}.png") as image:
                        payloads.append(image.convert("RGBA").tobytes())
                self.assertGreaterEqual(len(set(payloads)), 3, f"{direction} FIRE poses collapsed to duplicates")


if __name__ == "__main__":
    unittest.main()
