import importlib.util
import tempfile
import unittest
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
MODULE_PATH = ROOT / "tools" / "art" / "hero_authored_run_pipeline.py"
RESILIENT_PATH = ROOT / "tools" / "art" / "hero_authored_run_resilient.py"

spec = importlib.util.spec_from_file_location("hero_authored_run_pipeline", MODULE_PATH)
if spec is None or spec.loader is None:
    raise RuntimeError(f"Cannot load pipeline module from {MODULE_PATH}")
pipeline = importlib.util.module_from_spec(spec)
spec.loader.exec_module(pipeline)

resilient_spec = importlib.util.spec_from_file_location("hero_authored_run_resilient", RESILIENT_PATH)
if resilient_spec is None or resilient_spec.loader is None:
    raise RuntimeError(f"Cannot load resilient pipeline module from {RESILIENT_PATH}")
resilient = importlib.util.module_from_spec(resilient_spec)
resilient_spec.loader.exec_module(resilient)


def _pixel_data(image: Image.Image):
    getter = getattr(image, "get_flattened_data", None)
    return getter() if getter is not None else image.getdata()


class HeroAuthoredRunPipelineTest(unittest.TestCase):
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
    GUIDE_SENTINEL = (0, 255, 0, 255)

    def _draw_character(self, draw, cx, bottom, char_w, char_h, color):
        left = cx - char_w // 2
        upper = bottom - char_h
        right = left + char_w
        draw.rounded_rectangle((left, upper, right, bottom - 10), radius=10, fill=color)
        draw.rectangle((left + 4, bottom - 12, cx - 2, bottom), fill=color)
        draw.rectangle((cx + 2, bottom - 12, right - 4, bottom), fill=color)
        draw.rectangle((right + 3, upper + 20, right + 8, upper + 35), fill=color)
        return (left, upper, right + 8, bottom + 1)

    def _build_real_layout_sheet(self, path: Path):
        width, height = 1280, 1060
        image = Image.new("RGBA", (width, height), (255, 255, 255, 255))
        draw = ImageDraw.Draw(image)
        row_tops = [18, 132, 260, 374, 510, 624, 770, 906]
        direction_label_right = 132
        character_left = 155
        slot_width = (width - character_left - 18) / 9.0
        expected_run_centers = []
        for row, top in enumerate(row_tops):
            draw.rounded_rectangle((12, top + 25, direction_label_right, top + 73), radius=8, fill=(42, 46, 52, 255))
            draw.text((25, top + 40), self.DIRECTIONS[row].upper(), fill=(245, 245, 245, 255))
            row_run_centers = []
            for slot in range(9):
                cx = round(character_left + (slot + 0.5) * slot_width)
                frame_shift = (slot % 3) - 1
                char_w = 44 + ((row + slot) % 7)
                char_h = 68 + ((row * 3 + slot) % 9)
                bottom = top + 82 + frame_shift
                color = (48 + row * 18, 72 + slot * 11, 150 + ((row + slot) % 5) * 16, 255)
                self._draw_character(draw, cx, bottom, char_w, char_h, color)
                label = "IDLE" if slot == 0 else f"RUN{slot}"
                draw.text((cx - 15, bottom + 7), label, fill=self.LABEL_SENTINEL)
                if slot > 0:
                    row_run_centers.append(cx)
            expected_run_centers.append(row_run_centers)
            draw.line((0, top + 104, width, top + 104), fill=self.GUIDE_SENTINEL, width=1)
        draw.rectangle((430, 245, 439, 270), fill=self.LABEL_SENTINEL)
        image.save(path)
        return row_tops, expected_run_centers

    def _build_vertically_joined_sheet(self, path: Path):
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
                draw.rectangle((cx - 30, bottom + 7, cx + 31, bottom + 14), fill=self.LABEL_SENTINEL)
        for col in (0, 4, 7):
            cx = col_centers[col]
            draw.rectangle((cx - 3, row_centers[2] + 43, cx + 3, row_centers[3] - 48), fill=(80, 90, 150, 255))
        for col in (4, 7):
            cx = col_centers[col]
            draw.rectangle((cx - 3, row_centers[5] + 43, cx + 3, row_centers[6] - 48), fill=(80, 90, 150, 255))
        image.save(path)

    def _label_sentinel_hits(self, frame: Image.Image):
        hits = []
        pixels = list(_pixel_data(frame))
        for index, (r, g, b, a) in enumerate(pixels):
            if a > 12 and r > g + 100 and r > b + 100:
                hits.append((index % frame.width, index // frame.width, (r, g, b, a)))
        return hits

    def _guide_sentinel_hits(self, frame: Image.Image):
        hits = []
        pixels = list(_pixel_data(frame))
        for index, (r, g, b, a) in enumerate(pixels):
            if a > 12 and g > r + 100 and g > b + 100:
                hits.append((index % frame.width, index // frame.width, (r, g, b, a)))
        return hits

    def test_detects_run_slots_after_idle_in_real_sheet_layout(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            temp = Path(temp_dir)
            source = temp / "hero_sheet.png"
            row_tops, expected_run_centers = self._build_real_layout_sheet(source)
            with Image.open(source) as source_image:
                image = source_image.convert("RGBA")
            cells = pipeline.detect_authored_run_cells(image, rows=8, columns=8)
            self.assertEqual(64, len(cells))
            self.assertEqual(list(range(8)), sorted({cell.row for cell in cells}))
            self.assertEqual(list(range(8)), sorted({cell.column for cell in cells}))
            for cell in cells:
                expected_top = row_tops[cell.row]
                expected_center = expected_run_centers[cell.row][cell.column]
                actual_center = (cell.bbox[0] + cell.bbox[2]) / 2.0
                self.assertGreaterEqual(cell.bbox[1], expected_top - 4)
                self.assertLessEqual(cell.bbox[3], expected_top + 88)
                self.assertGreater(cell.bbox[3] - cell.bbox[1], 55)
                self.assertLess(cell.bbox[2] - cell.bbox[0], 90)
                self.assertLessEqual(abs(actual_center - expected_center), 16.0)

    def test_builds_64_transparent_320_frames_with_shared_ground_anchor(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            temp = Path(temp_dir)
            source = temp / "hero_sheet.png"
            self._build_real_layout_sheet(source)
            output = temp / "runtime"
            contact = temp / "run_contact_sheet.png"
            built = pipeline.build_authored_run_frames(source, output, directions=self.DIRECTIONS, canvas_size=320, ground_y=292, contact_sheet_path=contact)
            self.assertEqual(64, len(built))
            self.assertTrue(contact.is_file())
            expected_names = {f"run_{direction}_{frame:02d}.png" for direction in self.DIRECTIONS for frame in range(8)}
            self.assertEqual(expected_names, {path.name for path in built})
            for frame_path in built:
                with Image.open(frame_path) as frame_file:
                    frame = frame_file.convert("RGBA")
                self.assertEqual((320, 320), frame.size)
                bbox = frame.getchannel("A").getbbox()
                self.assertIsNotNone(bbox)
                self.assertEqual(292, bbox[3])
                center_x = (bbox[0] + bbox[2]) / 2.0
                self.assertLessEqual(abs(center_x - 160.0), 5.0)
                self.assertFalse(self._label_sentinel_hits(frame))
                self.assertFalse(self._guide_sentinel_hits(frame))

    def test_resilient_production_pipeline_recovers_all_frames_when_adjacent_rows_are_joined(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            temp = Path(temp_dir)
            source = temp / "joined.png"
            output = temp / "runtime"
            self._build_vertically_joined_sheet(source)
            built = resilient.build_authored_run_frames(
                source,
                output,
                directions=self.DIRECTIONS,
                canvas_size=320,
                ground_y=306,
            )
            self.assertEqual(64, len(built))
            expected = {f"run_{direction}_{index:02d}.png" for direction in self.DIRECTIONS for index in range(8)}
            self.assertEqual(expected, {path.name for path in built})
            for path in built:
                with Image.open(path) as source_frame:
                    frame = source_frame.convert("RGBA")
                bbox = frame.getchannel("A").getbbox()
                self.assertIsNotNone(bbox)
                self.assertEqual(306, bbox[3])
                self.assertGreaterEqual(bbox[0], 6)
                self.assertLessEqual(bbox[2], 314)
                self.assertFalse(self._label_sentinel_hits(frame), f"label contamination in {path.name}")


if __name__ == "__main__":
    unittest.main()
