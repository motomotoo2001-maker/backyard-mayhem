import importlib.util
import sys
import unittest
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
MODULE_PATH = ROOT / "tools" / "art" / "hero_candidate_cleanup.py"


def _load_cleanup():
    name = "hero_candidate_cleanup_test_module"
    spec = importlib.util.spec_from_file_location(name, MODULE_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load {MODULE_PATH}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


def _base_frame() -> Image.Image:
    image = Image.new("RGBA", (320, 320), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    draw.rounded_rectangle((116, 74, 208, 286), radius=12, fill=(128, 86, 178, 255))
    draw.rectangle((126, 268, 148, 286), fill=(128, 86, 178, 255))
    draw.rectangle((174, 268, 198, 286), fill=(128, 86, 178, 255))
    return image


class HeroCandidateCleanupTest(unittest.TestCase):
    def test_nearby_weapon_piece_above_feet_is_preserved(self):
        cleanup = _load_cleanup()
        image = _base_frame()
        draw = ImageDraw.Draw(image)
        # Detached muzzle/hose piece near the body, but clearly above the feet.
        draw.rectangle((210, 170, 224, 184), fill=(230, 140, 55, 255))

        cleaned, stats = cleanup.clean_frame(image, ground_y=306, safe_margin=8)
        self.assertEqual(306, stats["body_bottom"])
        self.assertGreater(cleaned.getpixel((218, 190))[3], 0)

    def test_nearby_fragment_below_main_feet_is_removed(self):
        cleanup = _load_cleanup()
        image = _base_frame()
        draw = ImageDraw.Draw(image)
        # Simulates a neighbouring sprite fragment: spatially close enough to survive
        # the old proximity rule, but extending below the hero's own feet.
        draw.rectangle((150, 291, 188, 296), fill=(245, 80, 80, 255))

        cleaned, stats = cleanup.clean_frame(image, ground_y=306, safe_margin=8)
        bbox = cleaned.getchannel("A").point(lambda p: 255 if p > 18 else 0).getbbox()
        self.assertIsNotNone(bbox)
        self.assertEqual(307, bbox[3])
        self.assertGreater(stats["removed_pixels"], 0)
        # No detached alpha may remain below the shared ground pixel.
        self.assertEqual(0, cleaned.crop((0, 307, 320, 320)).getchannel("A").getextrema()[1])

    def test_nearby_wide_shallow_label_above_head_is_removed(self):
        cleanup = _load_cleanup()
        image = _base_frame()
        draw = ImageDraw.Draw(image)
        # Mirrors the real run_back_00 failure: a presentation label sits only a
        # few pixels above the body, overlaps it horizontally, and is therefore
        # too close for a plain proximity filter to distinguish from a weapon.
        # Its wide + shallow geometry is presentation chrome, not anatomy.
        draw.rectangle((114, 46, 211, 70), fill=(245, 235, 220, 255))

        cleaned, stats = cleanup.clean_frame(image, ground_y=306, safe_margin=8)
        bbox = cleaned.getchannel("A").point(lambda p: 255 if p > 18 else 0).getbbox()
        self.assertIsNotNone(bbox)
        self.assertEqual(307, bbox[3])
        self.assertGreater(stats["removed_pixels"], 0)
        # The detached upper label must be gone even though it is only 3 px above
        # the body and horizontally overlaps it.
        self.assertEqual(0, cleaned.crop((100, 40, 225, 73)).getchannel("A").getextrema()[1])


if __name__ == "__main__":
    unittest.main()
