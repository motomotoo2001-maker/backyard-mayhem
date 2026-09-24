import importlib.util
import tempfile
import unittest
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
MODULE_PATH = ROOT / "tools" / "art" / "hero_authored_run_pipeline.py"

spec = importlib.util.spec_from_file_location("hero_authored_run_pipeline", MODULE_PATH)
if spec is None or spec.loader is None:
    raise RuntimeError(f"Cannot load pipeline module from {MODULE_PATH}")
pipeline = importlib.util.module_from_spec(spec)
spec.loader.exec_module(pipeline)


class HeroAuthoredRunOnlyLayoutTest(unittest.TestCase):
    def _build_run_only_sheet(self, path: Path):
        width, height = 1280, 1120
        image = Image.new("RGBA", (width, height), (255, 255, 255, 255))
        draw = ImageDraw.Draw(image)
        row_tops = [18, 145, 276, 410, 548, 690, 832, 970]
        left = 165
        usable = width - left - 25
        slot_width = usable / 8.0
        expected_centers = []

        for row, top in enumerate(row_tops):
            row_centers = []
            # Direction label/chrome on the left; this must never become a character slot.
            draw.rounded_rectangle((12, top + 20, 130, top + 70), radius=8, fill=(45, 48, 54, 255))
            for slot in range(8):
                cx = round(left + (slot + 0.5) * slot_width)
                bottom = top + 92 + ((slot % 3) - 1)
                color = (60 + row * 17, 85 + slot * 9, 145 + ((row + slot) % 5) * 15, 255)
                # One connected, tall character body with a small attached weapon nub.
                draw.rounded_rectangle((cx - 24, bottom - 76, cx + 23, bottom - 10), radius=9, fill=color)
                draw.rectangle((cx - 19, bottom - 12, cx - 3, bottom), fill=color)
                draw.rectangle((cx + 3, bottom - 12, cx + 19, bottom), fill=color)
                draw.rectangle((cx + 23, bottom - 56, cx + 31, bottom - 35), fill=color)
                draw.text((cx - 17, bottom + 8), f"RUN{slot + 1}", fill=(25, 25, 25, 255))
                row_centers.append(cx)
            expected_centers.append(row_centers)
        image.save(path)
        return row_tops, expected_centers

    def test_detects_eight_run_slots_when_row_has_no_idle_pose(self):
        with tempfile.TemporaryDirectory() as tmp:
            source = Path(tmp) / "run_only.png"
            row_tops, expected_centers = self._build_run_only_sheet(source)
            with Image.open(source) as source_file:
                image = source_file.convert("RGBA")
            cells = pipeline.detect_authored_run_cells(image, rows=8, columns=8)

        self.assertEqual(64, len(cells))
        for cell in cells:
            center_x = (cell.bbox[0] + cell.bbox[2]) / 2.0
            self.assertLessEqual(abs(center_x - expected_centers[cell.row][cell.column]), 18.0)
            self.assertGreaterEqual(cell.bbox[1], row_tops[cell.row] - 5)
            self.assertLessEqual(cell.bbox[3], row_tops[cell.row] + 100)


if __name__ == "__main__":
    unittest.main()
