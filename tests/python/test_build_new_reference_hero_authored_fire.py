import importlib.util
import tempfile
import unittest
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
BUILDER_PATH = ROOT / "tools" / "art" / "build_new_reference_hero.py"

spec = importlib.util.spec_from_file_location("build_new_reference_hero_authored_fire", BUILDER_PATH)
if spec is None or spec.loader is None:
    raise RuntimeError(f"Cannot load hero builder from {BUILDER_PATH}")
builder = importlib.util.module_from_spec(spec)
spec.loader.exec_module(builder)


class BuildNewReferenceHeroAuthoredFireTest(unittest.TestCase):
    def test_action_frames_routes_fire_through_shared_authored_extractor(self):
        self.assertTrue(
            hasattr(builder, "build_authored_fire_frames"),
            "production hero builder must import build_authored_fire_frames",
        )

        idle = Image.new("RGBA", builder.CANVAS, (12, 34, 56, 255))
        movement = {
            (direction, "idle"): [idle.copy() for _ in range(4)]
            for direction in builder.DIRECTIONS
        }

        with tempfile.TemporaryDirectory() as temp_dir:
            temp = Path(temp_dir)
            source_path = temp / "action_sheet.png"
            Image.new("RGBA", (1280, 960), (0, 0, 0, 0)).save(source_path)
            original_action_src = builder.ACTION_SRC
            original_extractor = builder.build_authored_fire_frames
            calls = []

            def fake_extractor(source, output_dir, directions, row_bands, canvas_size, ground_y):
                calls.append((Path(source), tuple(directions), tuple(row_bands), canvas_size, ground_y))
                output = Path(output_dir)
                output.mkdir(parents=True, exist_ok=True)
                built = []
                for direction_index, direction in enumerate(directions):
                    for frame_index in range(3):
                        color = (40 + direction_index * 10, 80 + frame_index * 30, 140, 255)
                        path = output / f"fire_{direction}_{frame_index:02d}.png"
                        Image.new("RGBA", builder.CANVAS, color).save(path)
                        built.append(path)
                return built

            try:
                builder.ACTION_SRC = source_path
                builder.build_authored_fire_frames = fake_extractor
                actions = builder.action_frames(movement)
            finally:
                builder.ACTION_SRC = original_action_src
                builder.build_authored_fire_frames = original_extractor

        self.assertEqual(1, len(calls), "authored FIRE extractor should be called once")
        source, directions, row_bands, canvas_size, ground_y = calls[0]
        self.assertEqual(source_path, source)
        self.assertEqual(tuple(builder.DIRECTIONS), directions)
        self.assertEqual(((72, 220), (220, 375), (375, 530)), row_bands)
        self.assertEqual(builder.CANVAS[0], canvas_size)
        self.assertEqual(builder.ANCHOR[1], ground_y)

        for direction_index, direction in enumerate(builder.DIRECTIONS):
            frames = actions[(direction, "fire")]
            self.assertEqual(4, len(frames))
            for frame_index in range(3):
                expected = (40 + direction_index * 10, 80 + frame_index * 30, 140, 255)
                self.assertEqual(expected, frames[frame_index].getpixel((10, 10)))
            self.assertEqual(idle.tobytes(), frames[3].tobytes())


if __name__ == "__main__":
    unittest.main()
