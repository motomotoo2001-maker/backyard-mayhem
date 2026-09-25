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
                red_positions = []
                for y in range(frame.height):
                    for x in range(frame.width):
                        r, g, b, a = frame.getpixel((x, y))
                        if a > 16 and r > 220 and g < 50 and b < 50:
                            red_positions.append((x, y))
                if red_positions:
                    xs = [x for x, _y in red_positions]
                    ys = [y for _x, y in red_positions]
                    red_bbox = (min(xs), min(ys), max(xs) + 1, max(ys) + 1)
                else:
                    red_bbox = None
                self.assertEqual(
                    0,
                    len(red_positions),
                    f"label contamination in {path.name}: red_bbox={red_bbox}, alpha_bbox={bbox}",
                )

    def test_normalize_ground_removes_large_vertical_detached_island(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "run_front_00.png"
            image = Image.new("RGBA", (320, 320), (0, 0, 0, 0))
            draw = ImageDraw.Draw(image)
            # Main body, already close to the desired floor line.
            draw.rounded_rectangle((118, 92, 206, 279), radius=12, fill=(125, 82, 178, 255))
            draw.rectangle((126, 265, 148, 285), fill=(125, 82, 178, 255))
            draw.rectangle((174, 265, 198, 285), fill=(125, 82, 178, 255))
            # Large neighbour fragment: x-overlaps the body but is vertically detached by >40 px.
            draw.rectangle((132, 20, 191, 48), fill=(235, 80, 80, 255))
            image.save(path)

            recovery._normalize_ground(path, 320, 306)

            with Image.open(path) as source:
                cleaned = source.convert("RGBA")
            bbox = cleaned.getchannel("A").point(lambda p: 255 if p > 16 else 0).getbbox()
            self.assertIsNotNone(bbox)
            self.assertEqual(307, bbox[3])
            self.assertEqual(
                0,
                cleaned.crop((0, 0, 320, 100)).getchannel("A").getextrema()[1],
                "detached upper island must be removed before recovered RUN is published",
            )


if __name__ == "__main__":
    unittest.main()
