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


if __name__ == "__main__":
    unittest.main()
