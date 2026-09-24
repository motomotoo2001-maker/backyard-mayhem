import importlib.util
import tempfile
import unittest
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
MODULE_PATH = ROOT / "tools" / "art" / "build_full_project_hero_candidate.py"
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


def load_module():
    spec = importlib.util.spec_from_file_location("full_project_hero_candidate_fire", MODULE_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Cannot load candidate builder from {MODULE_PATH}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def make_frame(color, bbox=(24, 28, 296, 306)):
    image = Image.new("RGBA", (320, 320), (0, 0, 0, 0))
    layer = Image.new("RGBA", (bbox[2] - bbox[0], bbox[3] - bbox[1]), color)
    image.alpha_composite(layer, (bbox[0], bbox[1]))
    return image


class FullProjectHeroCandidateFireTest(unittest.TestCase):
    def test_candidate_module_exposes_fire_validator_and_contact_sheet_writer(self):
        module = load_module()
        self.assertTrue(hasattr(module, "_validate_authored_fire_frames"))
        self.assertTrue(hasattr(module, "_write_fire_contact_sheet"))

    def test_fire_validator_requires_four_frames_and_three_unique_authored_poses(self):
        module = load_module()
        with tempfile.TemporaryDirectory() as temp_dir:
            frames_dir = Path(temp_dir)
            generated = {}
            for direction_index, direction in enumerate(DIRECTIONS):
                names = []
                for frame_index in range(4):
                    name = f"fire_{direction}_{frame_index:02d}.png"
                    color = (
                        40 + direction_index * 12,
                        60 + frame_index * 35,
                        130 + frame_index * 10,
                        255,
                    )
                    make_frame(color).save(frames_dir / name)
                    names.append(name)
                generated[("fire", direction)] = names

            module._validate_authored_fire_frames(
                frames_dir,
                generated,
                DIRECTIONS,
                (320, 320),
                306,
            )

            # Collapse the first three authored poses in one direction.
            duplicate = make_frame((11, 22, 33, 255))
            for frame_index in range(3):
                duplicate.save(frames_dir / generated[("fire", "front")][frame_index])
            with self.assertRaises(RuntimeError):
                module._validate_authored_fire_frames(
                    frames_dir,
                    generated,
                    DIRECTIONS,
                    (320, 320),
                    306,
                )

    def test_fire_contact_sheet_is_four_columns_by_eight_directions(self):
        module = load_module()
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            frames_dir = root / "frames"
            frames_dir.mkdir()
            generated = {}
            for direction_index, direction in enumerate(DIRECTIONS):
                names = []
                for frame_index in range(4):
                    name = f"fire_{direction}_{frame_index:02d}.png"
                    make_frame((60 + direction_index * 10, 70 + frame_index * 20, 150, 255)).save(frames_dir / name)
                    names.append(name)
                generated[("fire", direction)] = names

            output = root / "authored-fire-contact-sheet.png"
            module._write_fire_contact_sheet(frames_dir, generated, DIRECTIONS, output)
            self.assertTrue(output.is_file())
            with Image.open(output) as sheet:
                self.assertEqual((4 * 120, 8 * 120), sheet.size)


if __name__ == "__main__":
    unittest.main()
