import json
from pathlib import Path
import unittest


class StrictSchemaTests(unittest.TestCase):
    def test_all_output_schema_objects_are_closed_and_require_declared_fields(self):
        def check(node, location):
            if isinstance(node, dict):
                if node.get('type') == 'object':
                    self.assertIs(node.get('additionalProperties'), False, location)
                    self.assertEqual(set(node.get('required', [])), set(node.get('properties', {})), location)
                for key, value in node.items():
                    check(value, location + '/' + key)
            elif isinstance(node, list):
                for index, value in enumerate(node):
                    check(value, location + '/' + str(index))

        for path in (Path(__file__).parents[1] / 'schemas').glob('*.schema.json'):
            with self.subTest(schema=path.name):
                check(json.loads(path.read_text()), path.name)
