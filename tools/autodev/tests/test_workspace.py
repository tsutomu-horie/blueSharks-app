import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import Mock, patch

from tools.autodev.state import Store
from tools.autodev.workspace import WorkspaceIntegration
from tools.autodev.tests.test_runtime import sample_ticket


class WorkspaceDeliveryTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.store = Store(Path(self.temporary.name) / 'state.sqlite3')
        self.integration = WorkspaceIntegration(self.store, {
            'google_workspace': {'enabled': True, 'worklog_sheet_id': 42, 'spreadsheet_id': 'test-sheet', 'worklog_sheet_name': '自律開発作業ログ'},
            'workspace': {}, 'codex': {},
        })

    def tearDown(self):
        self.temporary.cleanup()

    def event(self):
        self.store.create_ticket(sample_ticket('BLOCKED-1'), 'READY')
        self.store.transition('BLOCKED-1', 'BLOCKED', 'ENVIRONMENT_BLOCKED', {'reason': 'device unavailable'})
        return self.integration.pending_entries()[0]

    def readback(self, entry):
        return {'spreadsheet_id': 'test-sheet', 'sheet_id': 42, 'sheet_name': '自律開発作業ログ',
                'range': "'自律開発作業ログ'!A8:G8", 'values': [entry['values']]}

    def test_cli_never_starts_a_logging_ai(self):
        self.event()
        with patch.object(self.integration, '_run') as inference:
            self.assertEqual(self.integration.sync_logs(), 0)
            self.assertEqual(len(self.integration.pending_entries()), 1)
        inference.assert_not_called()

    def test_actual_readback_confirms_once_and_wrong_values_never_confirm(self):
        entry = self.event()
        receipt = self.readback(entry)
        receipt['values'] = [['wrong'] * 7]
        with self.assertRaises(ValueError):
            self.integration.confirm_delivery(entry['event_id'], 8, receipt)
        self.assertEqual(len(self.integration.pending_entries()), 1)
        receipt = self.readback(entry)
        self.integration.confirm_delivery(entry['event_id'], 8, receipt)
        self.integration.confirm_delivery(entry['event_id'], 8, receipt)
        self.assertEqual(self.integration.pending_entries(), [])
        with self.assertRaises(ValueError):
            self.integration.confirm_delivery(entry['event_id'], 9, receipt)

    def test_unrelated_sheet_is_not_accepted_as_delivery_evidence(self):
        entry = self.event()
        receipt = {**self.readback(entry), 'spreadsheet_id': 'unrelated'}
        with self.assertRaises(ValueError):
            self.integration.confirm_delivery(entry['event_id'], 8, receipt)

    def test_retained_failure_is_visible_and_can_be_retried(self):
        entry = self.event()
        for _ in range(3):
            self.integration.delivery_error(entry['event_id'], 'Chrome unavailable')
        self.assertEqual(self.integration.pending_entries(), [])
        self.assertEqual(self.integration.delivery_status(), {'pending': 1, 'retry_required': 1})
        self.assertEqual(self.integration.retry_failed_deliveries(), 1)
        self.assertEqual(len(self.integration.pending_entries()), 1)

    def test_imported_initial_status_is_not_a_new_completion(self):
        self.store.create_ticket(sample_ticket('LEGACY'), 'BLOCKED')
        self.store.add_event('LEGACY', 'LEGACY_TICKET_IMPORTED', {'execution_held': True})
        self.assertEqual(self.integration.pending_entries(), [])

    def test_delivery_values_stay_at_the_original_event_snapshot(self):
        entry = self.event()
        self.store.update_ticket('BLOCKED-1', allowed_scope_json=json.dumps(['lib/new_scope/**']), pr_url='https://github.com/example/new-pr')
        self.store.add_event('BLOCKED-1', 'MECHANICAL_QC_PASSED', {'changed_files': ['lib/new_file.dart']})
        same = self.integration.pending_entries()[0]
        self.assertEqual(same['marker'], entry['marker'])
        self.assertEqual(same['values'], entry['values'])

    def test_parent_dependents_are_atomically_moved_to_children(self):
        parent = sample_ticket('PARENT')
        parent['current_state'] = {'migration': 'legacy_markdown_import'}
        self.store.create_ticket(parent, 'BLOCKED')
        child = sample_ticket('CHILD')
        child['current_state'] = {'legacy_parent': 'PARENT'}
        child['dependencies'] = ['PARENT']
        self.store.create_ticket(child, 'READY')
        dependent = sample_ticket('DEPENDENT')
        dependent['dependencies'] = ['PARENT']
        self.store.create_ticket(dependent, 'READY')
        self.store.supersede_legacy('PARENT', ['CHILD'])
        self.assertEqual(self.store.get_ticket('PARENT')['status'], 'CANCELLED')
        self.assertEqual(json.loads(self.store.get_ticket('CHILD')['dependencies_json']), [])
        self.assertEqual(json.loads(self.store.get_ticket('DEPENDENT')['dependencies_json']), ['CHILD'])

    def test_invalid_replacement_does_not_archive_parent(self):
        parent = sample_ticket('PARENT')
        parent['current_state'] = {'migration': 'legacy_markdown_import'}
        self.store.create_ticket(parent, 'BLOCKED')
        with self.assertRaises(ValueError):
            self.store.supersede_legacy('PARENT', ['NOT-A-CHILD'])
        self.assertEqual(self.store.get_ticket('PARENT')['status'], 'BLOCKED')

    def test_parent_prerequisites_are_inherited_before_child_release(self):
        self.store.create_ticket(sample_ticket('PREREQUISITE'), 'BLOCKED')
        parent = sample_ticket('PARENT')
        parent['dependencies'] = ['PREREQUISITE']
        parent['current_state'] = {'migration': 'legacy_markdown_import'}
        self.store.create_ticket(parent, 'BLOCKED')
        child = sample_ticket('CHILD')
        child['current_state'] = {'legacy_parent': 'PARENT', 'legacy_migration_pending': True, 'migration_initial_status': 'READY'}
        self.store.create_ticket(child, 'TRIAGE')
        self.assertIsNone(self.store.claim_next())
        self.store.supersede_legacy('PARENT', ['CHILD'])
        self.assertEqual(self.store.get_ticket('CHILD')['status'], 'READY')
        self.assertEqual(json.loads(self.store.get_ticket('CHILD')['dependencies_json']), ['PREREQUISITE'])
        self.assertIsNone(self.store.claim_next())

    def test_cyclic_prerequisites_keep_all_children_held(self):
        prerequisite = sample_ticket('PREREQUISITE')
        prerequisite['dependencies'] = ['PARENT']
        self.store.create_ticket(prerequisite, 'BLOCKED')
        parent = sample_ticket('PARENT')
        parent['dependencies'] = ['PREREQUISITE']
        parent['current_state'] = {'migration': 'legacy_markdown_import'}
        self.store.create_ticket(parent, 'BLOCKED')
        child = sample_ticket('CHILD')
        child['current_state'] = {'legacy_parent': 'PARENT', 'legacy_migration_pending': True, 'migration_initial_status': 'READY'}
        self.store.create_ticket(child, 'TRIAGE')
        with self.assertRaisesRegex(ValueError, 'cycle'):
            self.store.supersede_legacy('PARENT', ['CHILD'])
        self.assertEqual(self.store.get_ticket('PARENT')['status'], 'BLOCKED')
        self.assertEqual(self.store.get_ticket('CHILD')['status'], 'TRIAGE')


class SpecificationEvidenceTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.store = Store(Path(self.temporary.name) / 'state.sqlite3')
        self.integration = WorkspaceIntegration(self.store, {
            'google_workspace': {
                'enabled': True,
                'spreadsheet_id': 'test-sheet',
                'worklog_sheet_id': 42,
                'worklog_sheet_name': '自律開発作業ログ',
                'specification_folder_id': 'folder-1',
            },
            'workspace': {}, 'codex': {},
        })

    def tearDown(self):
        self.temporary.cleanup()

    def test_source_evidence_is_verified_independently_of_code_and_test_status(self):
        source = {
            'title': 'ICCドリフト',
            'url': 'https://docs.google.com/spreadsheets/d/test-sheet/edit',
            'modified_at': '2026-10-02T00:00:00Z',
            'read_locations': ["sheet:'育成ゲームテスト項目'!A90:AB100"],
            'coverage_note': 'No.90/92/93の状態復元・同期仕様を確認。',
        }
        result = {
            'verified': False,
            'source_evidence_complete': True,
            'source_evidence_gaps': [],
            'inventory_complete': True,
            'sources': [source],
            'summary': '最新仕様の関連範囲を確認。',
            'reason': '実装・テストはこの仕様確認フェーズでは検証していない。',
        }
        self.integration._run = Mock(return_value=(result, []))

        with (
            patch('tools.autodev.workspace.drive_id', return_value='source-1'),
            patch('tools.autodev.workspace.complete_inventory', return_value={
                'source-1': {'title': 'ICCドリフト', 'modified_at': source['modified_at']},
            }),
            patch('tools.autodev.workspace.observed_read_locations', return_value={
                'source-1': {"sheet:育成ゲームテスト項目!A1:AB1037": 'actual-read-hash'},
            }),
            patch('tools.autodev.workspace.read_location_contains', return_value=True),
        ):
            evidence = self.integration.verify_specification('状態復元と二重同期防止')

        self.assertIsNotNone(evidence)
        self.assertTrue(evidence['verified'])
        self.assertTrue(evidence['source_evidence_complete'])
        self.assertEqual(evidence['source_evidence_gaps'], [])
        self.assertEqual(evidence['sources'][0]['section_hashes'][source['read_locations'][0]], 'actual-read-hash')

    def test_unread_applicable_source_keeps_specification_unverified(self):
        self.integration._run = Mock(return_value=(
            {
                'verified': False,
                'source_evidence_complete': False,
                'source_evidence_gaps': ['ICCDB設計書の該当タブが未読'],
                'inventory_complete': True,
                'sources': [{'title': 'ICCドリフト'}],
                'summary': '不足資料あり。',
                'reason': '適用候補の内容が未読。',
            },
            [],
        ))

        self.assertIsNone(self.integration.verify_specification('状態復元と二重同期防止'))

    def test_explicit_source_gap_blocks_even_when_completeness_flag_is_true(self):
        self.integration._run = Mock(return_value=(
            {
                'verified': True,
                'source_evidence_complete': True,
                'source_evidence_gaps': ['ICCDB設計書の該当タブが未読'],
                'inventory_complete': True,
                'sources': [{'title': 'ICCドリフト'}],
                'summary': '仕様を確認。',
                'reason': '',
            },
            [],
        ))

        self.assertIsNone(self.integration.verify_specification('状態復元と二重同期防止'))

    def test_claimed_source_without_observed_content_read_is_rejected(self):
        source = {
            'title': 'ICCドリフト',
            'url': 'https://docs.google.com/spreadsheets/d/test-sheet/edit',
            'modified_at': '2026-10-02T00:00:00Z',
            'read_locations': ["sheet:'育成ゲームテスト項目'!A90:AB100"],
            'coverage_note': '状態復元と通信失敗時の操作抑止を確認。',
        }
        result = {
            'verified': True,
            'source_evidence_complete': True,
            'source_evidence_gaps': [],
            'inventory_complete': True,
            'sources': [source],
            'summary': '仕様を確認。',
            'reason': '',
        }
        self.integration._run = Mock(return_value=(result, []))

        with (
            patch('tools.autodev.workspace.drive_id', return_value='source-1'),
            patch('tools.autodev.workspace.complete_inventory', return_value={
                'source-1': {'title': 'ICCドリフト', 'modified_at': source['modified_at']},
            }),
            patch('tools.autodev.workspace.observed_read_locations', return_value={}),
        ):
            with self.assertRaisesRegex(RuntimeError, 'not matched to its actual inventory and content read'):
                self.integration.verify_specification('状態復元と二重同期防止')

    def test_model_inventory_claim_without_complete_observed_inventory_is_rejected(self):
        self.integration._run = Mock(return_value=(
            {
                'verified': True,
                'source_evidence_complete': True,
                'source_evidence_gaps': [],
                'inventory_complete': True,
                'sources': [{'title': 'ICCドリフト'}],
                'summary': '仕様を確認。',
                'reason': '',
            },
            [],
        ))

        with patch('tools.autodev.workspace.complete_inventory', return_value=None):
            with self.assertRaisesRegex(RuntimeError, 'complete recursive folder inventory'):
                self.integration.verify_specification('状態復元と二重同期防止')
