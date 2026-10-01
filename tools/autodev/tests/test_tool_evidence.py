import unittest
from tools.autodev.tool_evidence import complete_inventory, worklog_readback, extract_tool_evidence, observed_read_locations


def call(method, evidence):
    return {'type': 'item.completed', 'status': 'completed', 'tool': 'google_drive.' + method,
            'evidence': {'succeeded': True, **evidence}}


class ToolEvidenceTests(unittest.TestCase):
    def test_title_cell_is_not_proof_of_business_specification(self):
        item = {'tool': 'google_drive.get_spreadsheet_range', 'arguments': {'spreadsheet_id': 'sheet', 'sheet_name': '表紙', 'range': 'A1:A1'},
                'result': {'structured_content': {'range': "'表紙'!A1:A1", 'values': [['ICCドリフト']]}}}
        evidence = extract_tool_evidence(item)
        self.assertFalse(evidence['substantive'])
        self.assertEqual(observed_read_locations([call('get_spreadsheet_range', evidence)]), {})

    def test_section_proof_retains_the_actual_tab_and_range(self):
        item = {'tool': 'google_drive.get_spreadsheet_range', 'arguments': {'spreadsheet_id': 'sheet', 'sheet_name': '仕様', 'range': 'A2:C2'},
                'result': {'structured_content': {'range': "'仕様'!A2:C2", 'values': [['ポイント履歴', '会員ID', '必ずマスクする']]}}}
        evidence = extract_tool_evidence(item)
        self.assertTrue(evidence['substantive'])
        reads = observed_read_locations([call('get_spreadsheet_range', evidence)])
        self.assertIn('sheet:仕様!A2:C2', reads['sheet'])
        self.assertNotIn('sheet:別のタブ!A2:C2', reads['sheet'])

    def test_partial_or_missing_child_folder_never_verifies_inventory(self):
        root = call('list_folder', {'target_id': 'root', 'partial': False, 'limit': 1000,
                                 'unfiltered_listing': True,
                                 'files': [{'id': 'child', 'mime_type': 'application/vnd.google-apps.folder'}]})
        self.assertIsNone(complete_inventory([root], 'root'))
        child = call('list_folder', {'target_id': 'child', 'partial': False, 'limit': 1000, 'files': [], 'unfiltered_listing': True})
        self.assertIsNotNone(complete_inventory([root, child], 'root'))
        child['evidence']['partial'] = True
        self.assertIsNone(complete_inventory([root, child], 'root'))

    def test_unrelated_or_wrong_values_cannot_confirm_sheet_delivery(self):
        settings = {'spreadsheet_id': 'sheet', 'worklog_sheet_name': 'log'}
        evidence = {'target_id': 'other', 'sheet_name': 'log', 'range': "'log'!A2:G2", 'values': [['v']*7]}
        self.assertFalse(worklog_readback([call('get_spreadsheet_range', evidence)], settings, 2, ['v']*7))
        evidence['target_id'] = 'sheet'
        self.assertTrue(worklog_readback([call('get_spreadsheet_range', evidence)], settings, 2, ['v']*7))
        self.assertFalse(worklog_readback([call('get_spreadsheet_range', evidence)], settings, 2, ['changed']*7))

    def test_wrong_returned_range_does_not_verify_requested_section(self):
        item = {'tool': 'google_drive.get_spreadsheet_range', 'arguments': {'spreadsheet_id': 'sheet', 'sheet_name': '仕様', 'range': 'A2:C2'},
                'result': {'structured_content': {'range': "'表紙'!A1:C1", 'values': [['ポイント', 'ID', 'mask']]}}}
        self.assertFalse(extract_tool_evidence(item)['substantive'])

    def test_metadata_json_is_not_document_body(self):
        metadata = {'id': 'file', 'name': 'Spec', 'description': 'metadata only ' * 100}
        item = {'tool': 'google_drive.fetch', 'arguments': {'url': 'https://drive.google.com/file/d/file/view'},
                'result': {'content': [{'type': 'text', 'text': __import__('json').dumps(metadata)}]}}
        self.assertFalse(extract_tool_evidence(item)['substantive'])

    def test_filtered_listing_does_not_prove_complete_inventory(self):
        item = {'tool': 'google_drive.list_folder', 'arguments': {'url': 'https://drive.google.com/drive/folders/root', 'special_filter_query_str': "name='one-file'"},
                'result': {'structured_content': {'files': [{'id': 'file', 'title': 'one-file', 'mime_type': 'text/plain'}]}}}
        self.assertIsNone(complete_inventory([call('list_folder', extract_tool_evidence(item))], 'root'))
