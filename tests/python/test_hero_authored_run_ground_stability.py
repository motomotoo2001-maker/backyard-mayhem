import importlib.util
import tempfile
import unittest
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
MODULE_PATH = ROOT / "tools" / "art" / "hero_authored_run_resilient.py"


def _load_module():
    spec = importlib.util.spec_from_file_location("hero_authored_run_resilient_test", MODULE_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load {MODULE_PATH}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _write_frame(path: Path, bottom: int, marker_x: int = 0) -> None:
    image = Image.new("RGBA", (320, 320), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    draw.rectangle((86, 44, 234, bottom - 1), fill=(142, 91, 181, 255))
    draw.rectangle((112 + marker_x, 120, 118 + marker_x, 128), fill=(248, 176, 46, 255))
    image.save(path)


class AuthoredRunGroundStabilityTest(unittest.TestCase):
    def test_stable_ground_anchor_passes(self):
        module = _load_module()
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = []
            bottoms = [300, 302, 304, 303, 301, 302, 305, 303]
            for index, bottom in enumerate(bottoms):
                path = root / f"run_front_{index:02d}.png"
                _write_frame(path, bottom, marker_x=index)
                paths.append(path)

            module._validate_ground_stability(
                paths,
                directions=["front"],
                ground_y=306,
                max_drift_px=24,
            )

    def test_large_ground_anchor_jump_is_rejected(self):
        module = _load_module()
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = []
            bottoms = [302, 303, 301, 304, 266, 302, 303, 301]
            for index, bottom in enumerate(bottoms):
                path = root / f"run_front_{index:02d}.png"
                _write_frame(path, bottom, marker_x=index)
                paths.append(path)

            with self.assertRaisesRegex(RuntimeError, "ground-anchor drift"):
                module._validate_ground_stability(
                    paths,
                    directions=["front"],
                    ground_y=306,
                    max_drift_px=24,
                )

    def test_missing_direction_frame_is_rejected(self):
        module = _load_module()
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = []
            for index in range(7):
                path = root / f"run_front_{index:02d}.png"
                _write_frame(path, 302, marker_x=index)
                paths.append(path)

            with self.assertRaisesRegex(RuntimeError, "expected 8 RUN frames"):
                module._validate_ground_stability(
                    paths,
                    directions=["front"],
                    ground_y=306,
                    max_drift_px=24,
                )

    def test_upper_presentation_cleanup_does_not_slice_connected_shoulders(self):
        module = _load_module()
        image = Image.new("RGBA", (320, 320), (0, 0, 0, 0))
        draw = ImageDraw.Draw(image)
        # Tall body with a wide shoulder / leaf-blower silhouette in the upper third.
        # This is one connected character component and must never be treated as a
        # detached RUN label simply because several rows are wide and shallow.
        draw.rounded_rectangle((122, 76, 202, 292), radius=12, fill=(133, 84, 176, 255))
        draw.rectangle((86, 104, 238, 122), fill=(133, 84, 176, 255))
        draw.rectangle((198, 108, 252, 116), fill=(232, 137, 50, 255))

        cleaned = module._strip_upper_presentation_band(image)

        # The connected shoulder bar and blower must survive untouched.
        self.assertGreater(cleaned.getpixel((90, 112))[3], 0)
        self.assertGreater(cleaned.getpixel((235, 112))[3], 0)
        self.assertGreater(cleaned.getpixel((245, 112))[3], 0)
        original_alpha = sum(1 for value in image.getchannel("A").getdata() if value > 16)
        cleaned_alpha = sum(1 for value in cleaned.getchannel("A").getdata() if value > 16)
        self.assertEqual(original_alpha, cleaned_alpha)

    def test_upper_presentation_cleanup_removes_detached_wide_label(self):
        module = _load_module()
        image = Image.new("RGBA", (320, 320), (0, 0, 0, 0))
        draw = ImageDraw.Draw(image)
        draw.rounded_rectangle((122, 92, 202, 292), radius=12, fill=(133, 84, 176, 255))
        # Wide shallow label with a real transparent gap above the body.
        draw.rectangle((100, 58, 224, 72), fill=(240, 230, 215, 255))

        cleaned = module._strip_upper_presentation_band(image)

        self.assertEqual(0, cleaned.getpixel((110, 64))[3])
        self.assertGreater(cleaned.getpixel((160, 110))[3], 0)

    def test_upper_presentation_cleanup_removes_label_with_tiny_bridge(self):
        module = _load_module()
        image = Image.new("RGBA", (320, 320), (0, 0, 0, 0))
        draw = ImageDraw.Draw(image)
        draw.rounded_rectangle((122, 92, 202, 292), radius=12, fill=(133, 84, 176, 255))
        # A wide label is almost detached, but a one-pixel antialias/source-sheet bridge
        # connects it to the character. This mirrors joined-row contamination: preserving
        # it would keep RUN text in the runtime frame even though the connection is too
        # narrow to be believable hero geometry.
        draw.rectangle((96, 58, 228, 72), fill=(240, 230, 215, 255))
        draw.rectangle((159, 73, 160, 91), fill=(240, 230, 215, 255))

        cleaned = module._strip_upper_presentation_band(image)

        self.assertEqual(0, cleaned.getpixel((110, 64))[3])
        self.assertEqual(0, cleaned.getpixel((160, 80))[3])
        self.assertGreater(cleaned.getpixel((160, 110))[3], 0)


if __name__ == "__main__":
    unittest.main()
