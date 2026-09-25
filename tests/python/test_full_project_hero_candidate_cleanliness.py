import importlib.util
import tempfile
import unittest
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "tools" / "art" / "build_full_project_hero_candidate.py"


def _load_candidate_module():
    spec = importlib.util.spec_from_file_location("hero_candidate_cleanliness_test", SCRIPT)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load {SCRIPT}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _frame(main_box=(116, 64, 205, 306), artifact_box=None):
    image = Image.new("RGBA", (320, 320), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    draw.rectangle(main_box, fill=(110, 150, 210, 255))
    if artifact_box is not None:
        draw.rectangle(artifact_box, fill=(255, 255, 255, 255))
    return image


class FullProjectHeroCandidateCleanlinessTest(unittest.TestCase):
    def test_clean_authored_frame_passes(self):
        module = _load_candidate_module()
        module._validate_authored_frame_cleanliness(_frame(), "run_front_00.png", 306)

    def test_grounded_body_must_reach_shared_anchor(self):
        module = _load_candidate_module()
        floating = _frame(main_box=(116, 44, 205, 286))
        with self.assertRaises(RuntimeError):
            module._validate_authored_frame_cleanliness(floating, "run_front_00.png", 306)

    def test_far_detached_artifact_is_rejected(self):
        module = _load_candidate_module()
        dirty = _frame(artifact_box=(12, 18, 42, 48))
        with self.assertRaises(RuntimeError):
            module._validate_authored_frame_cleanliness(dirty, "run_front_00.png", 306)

    def test_nearby_small_weapon_piece_is_allowed(self):
        module = _load_candidate_module()
        valid = _frame(artifact_box=(208, 156, 220, 168))
        module._validate_authored_frame_cleanliness(valid, "fire_right_01.png", 306)

    def test_candidate_validation_calls_cleanliness_for_authored_run_and_fire(self):
        source = SCRIPT.read_text(encoding="utf-8")
        self.assertIn("_validate_authored_frame_cleanliness(", source)
        marker = "_validate_authored_frame_cleanliness(frame, name, ground_y)"
        self.assertGreaterEqual(source.count(marker), 2)

    def test_candidate_cleanup_runs_before_validation(self):
        source = SCRIPT.read_text(encoding="utf-8")
        cleanup_marker = "cleanup.clean_candidate(candidate_dir, ground_y=builder.ANCHOR[1])"
        validate_marker = "_validate_candidate_frames("
        self.assertIn(cleanup_marker, source)
        cleanup_pos = source.find(cleanup_marker)
        main_pos = source.find("def main()")
        validate_pos = source.find(validate_marker, main_pos)
        self.assertGreater(cleanup_pos, main_pos)
        self.assertGreater(validate_pos, cleanup_pos)


if __name__ == "__main__":
    unittest.main()
