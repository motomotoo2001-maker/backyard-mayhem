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
    LABEL_SENTINEL = (250, 8, 245, 255)
    GUIDE_SENTINEL = (8, 245, 20, 255)

    def _build_irregular_sheet(self, path: Path) -> list[int]:
        width, height = 960, 1060
        image = Image.new("RGBA", (width, height), (255, 255, 255, 255))
        draw = ImageDraw.Draw(image)

        row_tops = [18, 132, 260, 374, 510, 624, 770, 906]
        cell_width = width // 8

        # Pale column grid models the real reference matte/grid behavior.
        for x in range(cell_width, width, cell_width):
            draw.line((x, 0, x, height), fill=(225, 225, 225, 255), width=1)

        for row, top in enumerate(row_tops):
            for col in range(8):
                cx = col * cell_width + cell_width // 2
                frame_shift = (col % 3) - 1
                char_w = 44 + ((row + col) % 7)
                char_h = 68 + ((row * 3 + col) % 9)
                bottom = top + 82 + frame_shift
                left = cx - char_w // 2
                upper = bottom - char_h
                right = left + char_w

                body_color = (
                    48 + row * 18,
                    72 + col * 14,
                    150 + ((row + col) % 5) * 16,
                    255,
                )
                draw.rounded_rectangle(
                    (left, upper, right, bottom - 10),
                    radius=10,
                    fill=body_color,
                )
                draw.rectangle((left + 4, bottom - 12, cx - 2, bottom), fill=body_color)
                draw.rectangle((cx + 2, bottom - 12, right - 4, bottom), fill=body_color)
                draw.rectangle(
                    (right + 3, upper + 20, right + 8, upper + 35),
                    fill=body_color,
                )

                # A unique sentinel makes source-label leakage testable without
                # confusing legitimate black/gray character pixels or resize fringe.
                draw.text(
                    (cx - 15, bottom + 7),
                    f"RUN{col + 1}",
                    fill=self.LABEL_SENTINEL,
                )

            # This intentionally foreground-colored guide is geometry noise, not matte.
            # The extractor must reject it because it is a long 1px component.
            draw.line(
                (0, top + 104, width, top + 104),
                fill=self.GUIDE_SENTINEL,
                width=1,
            )

        # Detached contamination from the next band, where equal-row slicing would
        # accidentally include it in the previous row.
        draw.rectangle((350, 245, 359, 270), fill=self.LABEL_SENTINEL)
        image.save(path)
        return row_tops

    def _contains_label_sentinel(self, pixels) -> bool:
        return any(
            a > 12 and r > g + 70 and b > g + 70
            for r, g, b, a in pixels
        )

    def _contains_guide_sentinel(self, pixels) -> bool:
        return any(
            a > 12 and g > r + 70 and g > b + 70
            for r, g, b, a in pixels
        )

    def test_detects_eight_irregular_character_bands_and_ignores_labels(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            temp = Path(temp_dir)
            source = temp / "hero_sheet.png"
            row_tops = self._build_irregular_sheet(source)

            with Image.open(source) as source_image:
                image = source_image.convert("RGBA")
            cells = pipeline.detect_authored_run_cells(image, rows=8, columns=8)

            self.assertEqual(64, len(cells))
            self.assertEqual(list(range(8)), sorted({cell.row for cell in cells}))
            self.assertEqual(list(range(8)), sorted({cell.column for cell in cells}))

            for cell in cells:
                expected_top = row_tops[cell.row]
                self.assertGreaterEqual(cell.bbox[1], expected_top - 4)
                self.assertLessEqual(cell.bbox[3], expected_top + 88)
                self.assertGreater(cell.bbox[3] - cell.bbox[1], 55)
                self.assertLess(cell.bbox[2] - cell.bbox[0], 90)

    def test_builds_64_transparent_320_frames_with_shared_ground_anchor(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            temp = Path(temp_dir)
            source = temp / "hero_sheet.png"
            self._build_irregular_sheet(source)
            output = temp / "runtime"
            contact = temp / "run_contact_sheet.png"

            built = pipeline.build_authored_run_frames(
                source,
                output,
                directions=self.DIRECTIONS,
                canvas_size=320,
                ground_y=292,
                contact_sheet_path=contact,
            )

            self.assertEqual(64, len(built))
            self.assertTrue(contact.is_file())
            with Image.open(contact) as contact_image:
                self.assertEqual((8 * 160, 8 * 160), contact_image.size)

            expected_names = {
                f"run_{direction}_{frame:02d}.png"
                for direction in self.DIRECTIONS
                for frame in range(8)
            }
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

                pixels = [px for px in _pixel_data(frame) if px[3] > 0]
                self.assertTrue(pixels)
                self.assertFalse(
                    self._contains_label_sentinel(pixels),
                    f"{frame_path.name} contains RUN-label/neighbor contamination",
                )
                self.assertFalse(
                    self._contains_guide_sentinel(pixels),
                    f"{frame_path.name} contains guide-line contamination",
                )


if __name__ == "__main__":
    unittest.main()
