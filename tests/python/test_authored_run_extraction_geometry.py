import importlib.util
import tempfile
import unittest
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
PIPELINE_PATH = ROOT / "tools" / "art" / "hero_authored_run_pipeline.py"

spec = importlib.util.spec_from_file_location("hero_authored_run_pipeline", PIPELINE_PATH)
if spec is None or spec.loader is None:
    raise RuntimeError(f"Cannot load pipeline module from {PIPELINE_PATH}")
pipeline = importlib.util.module_from_spec(spec)
spec.loader.exec_module(pipeline)


def _pixel_data(image: Image.Image):
    getter = getattr(image, "get_flattened_data", None)
    return getter() if getter is not None else image.getdata()


class AuthoredRunExtractionGeometryTest(unittest.TestCase):
    def _make_nonuniform_sheet(self, path: Path):
        width, height = 800, 1600
        image = Image.new("RGB", (width, height), "white")
        draw = ImageDraw.Draw(image)
        row_tops = [24, 170, 348, 532, 726, 918, 1122, 1340]
        row_colors = [
            (180, 40, 40),
            (40, 150, 70),
            (45, 90, 190),
            (190, 130, 35),
            (135, 60, 180),
            (35, 155, 165),
            (195, 75, 125),
            (85, 100, 45),
        ]
        col_width = width // 8
        for row, top in enumerate(row_tops):
            color = row_colors[row]
            for col in range(8):
                x0 = col * col_width
                # Main authored character body. Vary the x position slightly per frame.
                body_x = x0 + 31 + (col % 3) * 2
                draw.rectangle((body_x, top + 20, body_x + 39, top + 119), fill=color)
                # Connected head so the body remains one dominant component.
                draw.rectangle((body_x + 6, top, body_x + 32, top + 24), fill=color)
                # Detached weapon/prop close to the body: it should be retained.
                draw.rectangle((body_x + 50, top + 48, body_x + 62, top + 72), fill=color)
                # Presentation label: short and wide, close enough to be tempting but must be rejected.
                draw.rectangle((x0 + 10, top + 130, x0 + 78, top + 137), fill=(20, 20, 20))
        image.save(path)
        return row_colors

    def test_nonuniform_rows_are_extracted_without_equal_height_slicing_or_labels(self):
        directions = list(pipeline.DEFAULT_DIRECTIONS)
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            source = root / "movement_sheet.png"
            output = root / "runtime"
            row_colors = self._make_nonuniform_sheet(source)
            built = pipeline.build_authored_run_frames(
                source,
                output,
                directions=directions,
                canvas_size=160,
                ground_y=150,
            )

            self.assertEqual(64, len(built))
            for row, direction in enumerate(directions):
                for frame_index in range(8):
                    frame_path = output / f"run_{direction}_{frame_index:02d}.png"
                    self.assertTrue(frame_path.is_file(), frame_path.name)
                    with Image.open(frame_path) as frame_file:
                        frame = frame_file.convert("RGBA")

                    self.assertEqual((160, 160), frame.size)
                    alpha = frame.getchannel("A")
                    bbox = alpha.getbbox()
                    self.assertIsNotNone(bbox)
                    # Main character is bottom-anchored; labels below it must not survive extraction.
                    self.assertGreaterEqual(bbox[3], 148)
                    self.assertLessEqual(bbox[3], 151)
                    self.assertLess(bbox[2] - bbox[0], 125, "wide RUN label leaked into runtime frame")

                    opaque_rgb = [(r, g, b) for r, g, b, a in _pixel_data(frame) if a > 220]
                    self.assertTrue(opaque_rgb)
                    mean = tuple(sum(px[i] for px in opaque_rgb) / len(opaque_rgb) for i in range(3))
                    expected = row_colors[row]
                    self.assertLess(sum(abs(mean[i] - expected[i]) for i in range(3)), 55)


if __name__ == "__main__":
    unittest.main()

# CI rebuild marker: assemble the latest verified full project after all current art/grounding fixes.
