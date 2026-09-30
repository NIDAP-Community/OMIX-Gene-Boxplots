#!/usr/bin/env python3

import copy
import importlib.util
import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location(
    "adapter_contract", ROOT / "tests" / "check_adapter_contract.py"
)
CONTRACT = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CONTRACT)


class AdapterContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.panel = json.loads((ROOT / ".codeocean" / "app-panel.json").read_text())
        cls.main_text = (ROOT / "code" / "main.R").read_text()
        cls.source_text = (ROOT / "OMIX_MODULE_SOURCE.md").read_text()

    def audit(self, panel=None, main_text=None, source_text=None):
        return CONTRACT.audit(
            panel if panel is not None else self.panel,
            main_text if main_text is not None else self.main_text,
            source_text if source_text is not None else self.source_text,
        )

    def test_repository_contract_passes(self):
        self.assertEqual(self.audit(), [])

    def test_missing_control_is_detected(self):
        panel = copy.deepcopy(self.panel)
        panel["parameters"] = panel["parameters"][:-1]
        self.assertTrue(any("missing App Panel controls" in item for item in self.audit(panel)))

    def test_internal_control_is_detected(self):
        panel = copy.deepcopy(self.panel)
        panel["parameters"].append({
            "id": "deg_gene_column",
            "param_name": "deg_gene_column",
            "type": "text",
            "value_type": "string",
        })
        self.assertTrue(any("deg_gene_column" in item for item in self.audit(panel)))

    def test_scientific_default_drift_is_detected(self):
        panel = copy.deepcopy(self.panel)
        duplicate = next(
            item for item in panel["parameters"]
            if item.get("param_name") == "duplicate_aggregation"
        )
        duplicate["default_value"] = "sum"
        self.assertTrue(any("duplicate_aggregation: App Panel default mismatch" in item for item in self.audit(panel)))

    def test_choice_drift_is_detected(self):
        panel = copy.deepcopy(self.panel)
        adjustment = next(
            item for item in panel["parameters"]
            if item.get("param_name") == "p_adjust_method"
        )
        adjustment["extra_data"] = ["BH"]
        self.assertTrue(any("p_adjust_method: App Panel choices mismatch" in item for item in self.audit(panel)))

    def test_platform_output_binding_is_required(self):
        source_text = self.source_text.replace('"canonical": "output_dir"', '"canonical": "removed"')
        self.assertTrue(any("output_dir hidden binding" in item for item in self.audit(source_text=source_text)))


if __name__ == "__main__":
    unittest.main()
