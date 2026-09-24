import ast
import importlib.util
import tempfile
import unittest
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "tools" / "art" / "build_full_project_hero_candidate.py"


def _load_candidate_module():
    spec = importlib.util.spec_from_file_location("hero_candidate_builder_test", SCRIPT)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load {SCRIPT}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _write_frame(path: Path, box, color=(140, 90, 180, 255), marker_x=0):
    image = Image.new("RGBA", (320, 320), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    draw.rectangle(box, fill=color)
    if marker_x:
        draw.rectangle((100 + marker_x, 120, 104 + marker_x, 124), fill=(255, 210, 40, 255))
    image.save(path)


class FullProjectHeroCandidateSafetyTest(unittest.TestCase):
    def setUp(self):
        self.source = SCRIPT.read_text(encoding="utf-8")
        self.tree = ast.parse(self.source)

    def _function(self, name: str) -> ast.FunctionDef:
        for node in self.tree.body:
            if isinstance(node, ast.FunctionDef) and node.name == name:
                return node
        self.fail(f"missing function: {name}")

    def test_candidate_builder_has_explicit_apply_gate(self):
        self._function("_parse_args")
        self.assertIn("--apply", self.source)
        self.assertIn("--candidate-dir", self.source)
        self.assertIn("args.apply", self.source)

    def test_candidate_frames_are_validated_before_publish(self):
        self._function("_validate_candidate_frames")
        self._function("_publish_candidate")
        validate_pos = self.source.find("_validate_candidate_frames(")
        publish_pos = self.source.find("_publish_candidate(")
        self.assertGreaterEqual(validate_pos, 0)
        self.assertGreater(publish_pos, validate_pos)

    def test_default_mode_does_not_write_directly_to_runtime(self):
        main = self._function("main")
        main_source = ast.get_source_segment(self.source, main) or ""
        self.assertIn("candidate_dir", main_source)
        self.assertIn("if args.apply", main_source)
        self.assertNotIn("builder.OUT = builder.ROOT / 'assets/runtime", main_source)

    def test_candidate_builder_does_not_monkeypatch_production_run_extractor(self):
        main = self._function("main")
        assignments = [node for node in ast.walk(main) if isinstance(node, (ast.Assign, ast.AnnAssign))]
        for assignment in assignments:
            target = assignment.target if isinstance(assignment, ast.AnnAssign) else assignment.targets[0]
            if not isinstance(target, ast.Attribute):
                continue
            if isinstance(target.value, ast.Name) and target.value.id == "builder":
                self.assertNotEqual(
                    "build_authored_run_frames",
                    target.attr,
                    "full-project candidate must not monkeypatch the production authored RUN extractor",
                )

    def test_legacy_action_edge_touch_does_not_block_authored_run_candidate(self):
        module = _load_candidate_module()
        with tempfile.TemporaryDirectory() as temp_dir:
            frames_dir = Path(temp_dir)
            run_names = []
            for index in range(8):
                name = f"run_front_{index:02d}.png"
                run_names.append(name)
                _write_frame(frames_dir / name, (20, 20, 299, 299), marker_x=index * 2)

            # Legacy action art can still touch a side edge. That is separate visual debt
            # and must not prevent us from reviewing/replacing the authored RUN sequence.
            _write_frame(frames_dir / "fire_back_00.png", (53, 90, 319, 305))
            (frames_dir / "builder_hero_frames.tres").write_text("[gd_resource type=\"SpriteFrames\"]\n", encoding="utf-8")
            generated = {
                ("run", "front"): run_names,
                ("fire", "back"): ["fire_back_00.png"],
            }

            module._validate_candidate_frames(frames_dir, generated, ["front"], (320, 320), 306)

    def test_authored_run_edge_touch_still_fails_validation(self):
        module = _load_candidate_module()
        with tempfile.TemporaryDirectory() as temp_dir:
            frames_dir = Path(temp_dir)
            run_names = []
            for index in range(8):
                name = f"run_front_{index:02d}.png"
                run_names.append(name)
                box = (0, 20, 299, 299) if index == 0 else (20, 20, 299, 299)
                _write_frame(frames_dir / name, box, marker_x=index * 2)
            (frames_dir / "builder_hero_frames.tres").write_text("[gd_resource type=\"SpriteFrames\"]\n", encoding="utf-8")
            generated = {("run", "front"): run_names}

            with self.assertRaises(RuntimeError):
                module._validate_candidate_frames(frames_dir, generated, ["front"], (320, 320), 306)


if __name__ == "__main__":
    unittest.main()
