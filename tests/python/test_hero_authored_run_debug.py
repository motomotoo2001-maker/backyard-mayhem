import importlib.util
import tempfile
import unittest
from pathlib import Path

from PIL import Image

from test_hero_authored_run_pipeline import HeroAuthoredRunPipelineTest


ROOT = Path(__file__).resolve().parents[2]
MODULE_PATH = ROOT / "tools" / "art" / "hero_authored_run_pipeline.py"
spec = importlib.util.spec_from_file_location("hero_authored_run_pipeline_debug", MODULE_PATH)
pipeline = importlib.util.module_from_spec(spec)
spec.loader.exec_module(pipeline)


class HeroAuthoredRunDebugTest(unittest.TestCase):
    def test_print_component_groups(self):
        helper = HeroAuthoredRunPipelineTest(
            "test_detects_run_slots_after_idle_in_real_sheet_layout"
        )
        with tempfile.TemporaryDirectory() as temp_dir:
            source = Path(temp_dir) / "hero_sheet.png"
            helper._build_real_layout_sheet(source)
            with Image.open(source) as source_image:
                image = source_image.convert("RGBA")

            raw = pipeline._connected_components(image)
            candidates = [
                component
                for component in raw
                if pipeline._is_character_candidate(component, image.size, 8, 8)
            ]
            groups = pipeline._cluster_rows(candidates, 8)
            for row_index, group in enumerate(groups):
                ordered = sorted(
                    group,
                    key=lambda component: component.center_x,
                )
                print(
                    "DEBUG_ROW",
                    row_index,
                    [
                        {
                            "pixels": c.pixels,
                            "bbox": c.bbox,
                            "cx": round(c.center_x, 1),
                            "cy": round(c.center_y, 1),
                        }
                        for c in ordered
                    ],
                )
                selected = pipeline._select_character_slots(group, 9, row_index)
                print(
                    "DEBUG_SELECTED",
                    row_index,
                    [
                        {
                            "pixels": c.pixels,
                            "bbox": c.bbox,
                            "cx": round(c.center_x, 1),
                            "cy": round(c.center_y, 1),
                        }
                        for c in selected
                    ],
                )


if __name__ == "__main__":
    unittest.main()
