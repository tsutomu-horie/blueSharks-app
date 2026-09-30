from __future__ import annotations

from pathlib import Path
import unittest

from tools.autodev.config import load_config, validate_config


EXAMPLE_CONFIG = Path(__file__).resolve().parents[1] / "config.example.toml"


class ModelConfigTests(unittest.TestCase):
    def test_active_sol_roles_keep_the_gpt_6_1_cli_model_id(self):
        config = load_config(EXAMPLE_CONFIG)

        for key in ("developer_model", "reviewer_model", "supervisor_model"):
            self.assertEqual(config["codex"][key], "gpt-6.1-sol")

    def test_legacy_sol_model_id_is_rejected_for_active_roles(self):
        for key in ("developer_model", "reviewer_model", "supervisor_model"):
            with self.subTest(key=key):
                config = load_config(EXAMPLE_CONFIG)
                config["codex"][key] = "gpt-6-sol"

                with self.assertRaises(ValueError):
                    validate_config(config)


if __name__ == "__main__":
    unittest.main()
