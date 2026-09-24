import ast
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "tools" / "art" / "build_full_project_hero_candidate.py"


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


if __name__ == "__main__":
    unittest.main()
