import ast
import importlib.util
import unittest
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
BUILDER = ROOT / "tools" / "art" / "build_new_reference_hero.py"


def _load_builder_module():
    spec = importlib.util.spec_from_file_location("production_hero_builder_test", BUILDER)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load {BUILDER}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


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

    def test_production_builder_uses_resilient_shared_extractor_instead_of_duplicate_detector(self):
        shared_import = False
        for node in self.tree.body:
            if not isinstance(node, ast.ImportFrom):
                continue
            if node.module != "tools.art.hero_authored_run_resilient":
                continue
            if any(alias.name == "build_authored_run_frames" for alias in node.names):
                shared_import = True
                break

        self.assertTrue(
            shared_import,
            "production builder must import the resilient shared authored RUN extractor",
        )

        function_names = {
            node.name for node in self.tree.body if isinstance(node, ast.FunctionDef)
        }
        self.assertNotIn(
            "_column_character_candidates",
            function_names,
            "production builder must not maintain a second row/character detector",
        )
        self.assertNotIn(
            "build_authored_run_frames",
            function_names,
            "production builder must use the shared extractor instead of redefining it",
        )

    def test_normalize_to_canvas_keeps_off_center_weapon_inside_safe_side_margins(self):
        builder = _load_builder_module()
        # Synthetic action crop: the body is on the left while a long weapon/hose
        # extends far to the right. Anchoring only the body used to clip the weapon
        # against x=320 (the same failure seen in fire_back_00.png).
        crop = Image.new("RGBA", (300, 190), (0, 0, 0, 0))
        draw = ImageDraw.Draw(crop)
        draw.rectangle((0, 8, 94, 181), fill=(140, 90, 180, 255))
        draw.rectangle((80, 76, 299, 104), fill=(230, 120, 40, 255))
        normalized = builder.normalize_to_canvas(
            crop,
            (0, 8, 95, 174),
            target_h=244,
            canvas_size=(320, 320),
            anchor_x=160,
            ground_y=306,
        )
        bbox = normalized.getchannel("A").getbbox()
        self.assertIsNotNone(bbox)
        left, top, right, bottom = bbox
        self.assertGreaterEqual(left, 8, f"normalized action needs >=8px left margin, got {bbox}")
        self.assertLessEqual(right, 312, f"normalized action needs >=8px right margin, got {bbox}")
        self.assertGreaterEqual(top, 8, f"normalized action needs >=8px top margin, got {bbox}")
        self.assertLessEqual(bottom, 312, f"normalized action needs >=8px bottom margin, got {bbox}")


if __name__ == "__main__":
    unittest.main()
