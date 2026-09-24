import importlib.util
import tempfile
import unittest
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
MODULE_PATH = ROOT / "tools" / "art" / "hero_authored_run_recovery_v2.py"

spec = importlib.util.spec_from_file_location("hero_authored_run_recovery_v2", MODULE_PATH)
if spec is None or spec.loader is None:
    raise RuntimeError(f"Cannot load recovery module from {MODULE_PATH}")
recovery = importlib.util.module_from_spec(spec)
spec.loader.exec_module(recovery)


class HeroAuthoredRunProjectionRecoveryTest(unittest.TestCase):
    DIRECTIONS = [
        "front", "front_right", "right", "back_right",
        "back", "back_left", "left", "front_left",
    ]

    def _build_joined_sheet(self, path: Path):
        width, height = 1680, 1040
        image = Image.new("RGBA", (width, height), (255, 255, 255, 255))
        draw = ImageDraw.Draw(image)
        row_centers = [74, 202, 326, 448, 570, 690, 812, 934]
        col_centers = [414, 570, 731, 889, 1048, 1211, 1368, 1534]

        for row, cy in enumerate(row_centers):
            draw.rounded_rectangle((18, cy - 34, 128, cy + 22), radius=8, fill=(42, 46, 52, 255))
            for col, cx in enumerate(col_centers):
                color = (55 + row * 19, 76 + col * 10, 135 + ((row + col) % 5) * 18, 255)
                top = cy - 49
                bottom = cy + 45
                draw.rounded_rectangle((cx - 38, top, cx + 37, bottom - 12), radius=10, fill=color)
                draw.rectangle((cx - 29, bottom - 14, cx - 5, bottom), fill=color)
                draw.rectangle((cx + 5, bottom - 14, cx + 29, bottom), fill=color)
                draw.rectangle((cx + 40, cy - 18, cx + 52, cy + 8), fill=color)
                draw.rectangle((cx - 30, bottom + 7, cx + 31, bottom + 14), fill=(255, 0, 0, 255))

        for col in (0, 4, 7):
            cx = col_centers[col]
            draw.rectangle((cx - 3, row_centers[2] + 43, cx + 3, row_centers[3] - 48), fill=(80, 90, 150, 255))
        for col in (4, 7):
            cx = col_centers[col]
            draw.rectangle((cx - 3, row_centers[5] + 43, cx + 3, row_centers[6] - 48), fill=(80, 90, 150, 255))
        image.save(path)

    def test_recovers_all_64_frames_from_joined_rows_without_labels(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            source = root / "joined.png"
            output = root / "frames"
            contact = root / "contact.png"
            self._build_joined_sheet(source)
            built = recovery.build_recovered_run_frames(
                source,
                output,
                directions=self.DIRECTIONS,
                canvas_size=320,
                ground_y=306,
                contact_sheet_path=contact,
            )

            self.assertEqual(64, len(built))
            self.assertTrue(contact.is_file())
            expected = {
                f"run_{direction}_{index:02d}.png"
                for direction in self.DIRECTIONS
                for index in range(8)
            }
            self.assertEqual(expected, {path.name for path in built})

            for path in built:
                with Image.open(path) as source_frame:
                    frame = source_frame.convert("RGBA")
                self.assertEqual((320, 320), frame.size)
                bbox = frame.getchannel("A").getbbox()
                self.assertIsNotNone(bbox)
                self.assertEqual(306, bbox[3])
                self.assertGreaterEqual(bbox[0], 6)
                self.assertLessEqual(bbox[2], 314)
                red_hits = 0
                for r, g, b, a in frame.getdata():
                    if a > 16 and r > 220 and g < 50 and b < 50:
                        red_hits += 1
                self.assertEqual(0, red_hits, f"label contamination in {path.name}")


if __name__ == "__main__":
    unittest.main()
