import ast
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
BUILDER = ROOT / "tools" / "art" / "build_new_reference_hero.py"


class ProductionHeroBuildAuthoredRunTest(unittest.TestCase):
    def setUp(self):
        self.source = BUILDER.read_text(encoding="utf-8")
        self.tree = ast.parse(self.source)

    def _function(self, name: str) -> ast.FunctionDef:
        for node in self.tree.body:
            if isinstance(node, ast.FunctionDef) and node.name == name:
                return node
        self.fail(f"missing function: {name}")

    def test_production_builder_has_no_procedural_run_generator(self):
        function_names = {
            node.name for node in self.tree.body if isinstance(node, ast.FunctionDef)
        }
        self.assertNotIn(
            "procedural_run",
            function_names,
            "production hero build must not silently fall back to bob/squash procedural RUN",
        )

    def test_movement_frames_uses_authored_run_pipeline_at_runtime_anchor(self):
        movement = self._function("movement_frames")
        calls = [node for node in ast.walk(movement) if isinstance(node, ast.Call)]
        authored_calls = []
        for call in calls:
            name = None
            if isinstance(call.func, ast.Name):
                name = call.func.id
            elif isinstance(call.func, ast.Attribute):
                name = call.func.attr
            if name == "build_authored_run_frames":
                authored_calls.append(call)

        self.assertEqual(1, len(authored_calls), "movement_frames must invoke authored RUN extraction exactly once")
        call = authored_calls[0]
        keywords = {kw.arg: kw.value for kw in call.keywords if kw.arg}
        self.assertIn("canvas_size", keywords)
        self.assertIn("ground_y", keywords)
        self.assertTrue(
            isinstance(keywords["ground_y"], ast.Subscript)
            and isinstance(keywords["ground_y"].value, ast.Name)
            and keywords["ground_y"].value.id == "ANCHOR",
            "production RUN extraction must use the shared hero ground anchor",
        )

        procedural_calls = [
            call for call in calls
            if isinstance(call.func, ast.Name) and call.func.id == "procedural_run"
        ]
        self.assertFalse(procedural_calls, "movement_frames must use authored frames, not procedural transforms")


if __name__ == "__main__":
    unittest.main()
