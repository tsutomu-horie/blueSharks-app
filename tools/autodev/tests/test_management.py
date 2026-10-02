import tempfile
import json
import unittest
from pathlib import Path
from unittest.mock import patch, Mock

from tools.autodev.management import ManagementBridge, ManagementPending
from tools.autodev.runtime import CodexRunner
from tools.autodev.state import Store
from tools.autodev.tests.test_runtime import sample_ticket
from tools.autodev.engine import Orchestrator, ticket_from_row


class ManagementTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.store = Store(Path(self.temporary.name) / 'state.sqlite3')
        self.ticket = sample_ticket('MANAGED')
        self.store.create_ticket(self.ticket, 'TRIAGE')
        self.config = {'workspace': {}, 'git': {}, 'projects': {'app': {}}, 'management': {'timeout_seconds': 0}}
        self.bridge = ManagementBridge(self.store, self.config)
        self.approval = {'decision': 'APPROVE', 'rationale': '対象差分とテスト結果を確認済み', 'next_status': 'READY', 'scope_additions': []}

    def tearDown(self):
        self.temporary.cleanup()

    def request(self):
        with self.assertRaises(ManagementPending):
            self.bridge.request(self.ticket, 'TICKET_TRIAGE', {}, 'Review exact Ticket', wait=False)
        return self.bridge.pending()[0]['id']

    def test_pending_request_is_durable_and_not_duplicated(self):
        self.assertEqual(self.request(), self.request())
        self.assertEqual(len(self.bridge.pending()), 1)

    def test_codex_decision_is_consumed_without_cli_inference(self):
        request_id = self.request()
        self.bridge.decide(request_id, self.approval)
        with patch.object(CodexRunner, 'run') as inference:
            decision = self.bridge.request(self.ticket, 'TICKET_TRIAGE', {}, 'Review exact Ticket', wait=False)
        self.assertEqual(decision, self.approval)
        inference.assert_not_called()
        self.assertEqual(self.bridge.pending(), [])

    def test_changed_ticket_rejects_stale_approval(self):
        request_id = self.request()
        self.store.update_ticket('MANAGED', goal='different acceptance goal')
        with self.assertRaisesRegex(ValueError, 'stale'):
            self.bridge.decide(request_id, self.approval)

    def test_cached_decision_is_not_applied_after_ticket_changes(self):
        request_id = self.request()
        self.bridge.decide(request_id, self.approval)
        self.store.update_ticket('MANAGED', goal='changed after approval')
        with self.assertRaisesRegex(ManagementPending, 'changed after'):
            self.bridge.request(self.ticket, 'TICKET_TRIAGE', {}, 'Review exact Ticket', wait=False)
        self.assertEqual(self.bridge.pending()[0]['status'], 'STALE')

    def test_forbidden_scope_and_rewriting_a_decision_are_rejected(self):
        request_id = self.request()
        with self.assertRaises(ValueError):
            self.bridge.decide(request_id, {**self.approval, 'scope_additions': ['server/**']})
        self.bridge.decide(request_id, self.approval)
        with self.assertRaises(ValueError):
            self.bridge.decide(request_id, {**self.approval, 'decision': 'REJECT'})

    def test_runtime_refuses_to_spawn_a_cli_management_agent(self):
        runner = CodexRunner(self.store, {'codex': {'binary': '/not-used'}}, Path(self.temporary.name))
        with self.assertRaisesRegex(ValueError, 'Codex desktop'):
            runner.run(ticket_id='MANAGED', role='supervisor', phase='triage', model='gpt-6.1-sol', reasoning='low', prompt='manage', schema=Path('/not-used'), workdir=Path(self.temporary.name), write=False)

    def test_timed_out_scope_wait_can_resume_with_a_codex_decision(self):
        with self.assertRaises(ManagementPending):
            self.bridge.request(self.ticket, 'SCOPE_CHANGE_REQUESTED', {}, 'Approve narrow scope', wait=False)
        request_id = self.bridge.pending()[0]['id']
        self.store.transition('MANAGED', 'NEEDS_DECISION', 'CODEX_MANAGEMENT_PENDING')
        import json
        self.store.update_ticket('MANAGED', current_state_json=json.dumps({'management_wait': {'request_id': request_id}}))
        approval = {**self.approval, 'scope_additions': ['lib/feature/**']}
        self.bridge.decide(request_id, approval)
        self.assertEqual(self.store.get_ticket('MANAGED')['status'], 'READY')
        self.assertIn('lib/feature/**', json.loads(self.store.get_ticket('MANAGED')['allowed_scope_json']))
        self.bridge.decide(request_id, approval) # The recorded decision is idempotent.

    def test_human_decision_safely_pauses_queue(self):
        request_id = self.request()
        self.bridge.decide(request_id, {**self.approval, 'decision': 'NEEDS_HUMAN', 'next_status': 'BLOCKED'})
        self.assertTrue(self.store.pause_requested())

    def test_human_decision_and_pause_rollback_together(self):
        request_id = self.request()
        with patch.object(self.store, '_event', side_effect=RuntimeError('simulated interruption')):
            with self.assertRaises(RuntimeError):
                self.bridge.decide(request_id, {**self.approval, 'decision': 'NEEDS_HUMAN', 'next_status': 'BLOCKED'})
        self.assertFalse(self.store.pause_requested())
        self.assertEqual(self.bridge.show(request_id)['status'], 'PENDING')

    def test_all_judged_ticket_fields_invalidate_old_approval(self):
        updates = [
            {'acceptance_json': '["changed criterion"]'},
            {'test_ids_json': '["changed_test"]'},
            {'write_permission': 0},
            {'current_state_json': '{"specification_evidence":{"section_hashes":{"section":"changed"}}}'},
        ]
        for index, update in enumerate(updates):
            with self.subTest(update=update):
                ticket = sample_ticket(f'CHANGED-{index}')
                self.store.create_ticket(ticket, 'TRIAGE')
                with self.assertRaises(ManagementPending):
                    self.bridge.request(ticket, 'TICKET_TRIAGE', {}, 'Review', wait=False)
                request_id = self.bridge.pending()[-1]['id']
                self.store.update_ticket(ticket['id'], **update)
                with self.assertRaisesRegex(ValueError, 'stale'):
                    self.bridge.decide(request_id, self.approval)

    def test_database_ticket_can_generate_a_real_management_prompt(self):
        restored = ticket_from_row(self.store.get_ticket('MANAGED'))
        self.assertEqual(restored['acceptance_criteria'], self.ticket['acceptance_criteria'])
        engine = Orchestrator.__new__(Orchestrator)
        engine.config = {'projects': {'app': {'repository': self.temporary.name}}}
        engine.git = self.bridge.git
        prompt = engine._task_prompt(restored, Path(self.temporary.name), 'Manager review')
        with self.assertRaises(ManagementPending):
            self.bridge.request(restored, 'TICKET_TRIAGE', {}, prompt, wait=False)

    def test_triage_requests_for_independent_tickets_are_nonblocking(self):
        config = {**self.config, 'workspace': {'logs_dir': self.temporary.name}, 'projects': {'app': {'repository': self.temporary.name}}}
        engine = Orchestrator(self.store, config)
        engine._process_triage()
        second = sample_ticket('SECOND')
        self.store.create_ticket(second, 'TRIAGE')
        engine._process_triage()
        self.assertEqual({row['ticket_id'] for row in self.bridge.pending()}, {'MANAGED', 'SECOND'})

    def test_controller_crash_keeps_management_wait_and_can_resume(self):
        self.store.transition('MANAGED', 'READY', 'READY')
        self.store.transition('MANAGED', 'RUNNING', 'START')
        config = {**self.config, 'workspace': {'root': self.temporary.name, 'logs_dir': self.temporary.name}, 'projects': {'app': {'repository': self.temporary.name}}}
        engine = Orchestrator(self.store, config)
        restored = ticket_from_row(self.store.get_ticket('MANAGED'))
        with self.assertRaises(ManagementPending):
            engine.management.request(restored, 'SCOPE_CHANGE_REQUESTED', {}, 'Review', wait=False)
        request_id = engine.management.pending()[0]['id']
        engine.recover_orphaned_work()
        self.assertEqual(self.store.get_ticket('MANAGED')['status'], 'NEEDS_DECISION')
        engine.management.decide(request_id, self.approval)
        self.assertEqual(self.store.get_ticket('MANAGED')['status'], 'READY')

    def test_developer_cannot_register_management_approval_or_source_evidence(self):
        engine = Orchestrator.__new__(Orchestrator)
        engine.store = self.store
        engine._update_developer_state(self.ticket, {'approved_gate_evidence': [{'category': 'dependency_change', 'files': ['pubspec.yaml'], 'digest': 'fake'}], 'specification_evidence': {'verified': True}, 'last_action': 'source edit'})
        state = self.store.get_ticket('MANAGED')['current_state_json']
        self.assertNotIn('approved_gate_evidence', state)
        self.assertNotIn('specification_evidence', state)
        self.assertIn('source edit', state)

    def merge_request(self):
        self.store.transition('MANAGED', 'READY', 'READY')
        self.store.transition('MANAGED', 'RUNNING', 'START')
        self.store.transition('MANAGED', 'READY_FOR_REVIEW', 'QC')
        self.store.transition('MANAGED', 'REVIEWING', 'REVIEW')
        self.store.transition('MANAGED', 'READY_TO_MERGE', 'PASS')
        self.store.update_ticket('MANAGED', pr_url='https://example.test/pr/1', current_state_json=json.dumps({'reviewed_head_sha': 'old-sha'}))
        ticket = self.bridge._ticket('MANAGED')
        with self.assertRaises(ManagementPending):
            self.bridge.request(ticket, 'MERGE_APPROVAL', {'reviewed_head_sha': 'old-sha'}, 'Review merge', wait=False)
        return self.bridge.pending()[0]['id']

    def test_merge_rejection_revokes_sha_and_records_repair_reason_idempotently(self):
        request_id = self.merge_request()
        rejection = {**self.approval, 'decision': 'REJECT', 'rationale': '復帰時の二重送信を修正する'}
        self.bridge.decide(request_id, rejection)
        self.bridge.decide(request_id, rejection)
        ticket = self.bridge._ticket('MANAGED')
        self.assertEqual(ticket['status'], 'READY_TO_MERGE')
        self.assertEqual(ticket['pr_url'], 'https://example.test/pr/1')
        self.assertNotIn('reviewed_head_sha', ticket['current_state'])
        self.assertEqual(ticket['current_state']['merge_revision'], 1)
        self.assertEqual(ticket['current_state']['merge_repair']['reason'], rejection['rationale'])
        self.assertFalse(self.store.pause_requested())
        stale_ticket = {**ticket, 'current_state': {'reviewed_head_sha': 'old-sha'}}
        self.assertEqual(self.bridge.request(stale_ticket, 'MERGE_APPROVAL', {'reviewed_head_sha': 'old-sha'}, 'Review merge', wait=False), rejection)
        self.assertEqual(self.bridge.show(request_id)['status'], 'DECIDED')

    def test_merge_human_decision_does_not_authorize_repair(self):
        request_id = self.merge_request()
        self.bridge.decide(request_id, {**self.approval, 'decision': 'NEEDS_HUMAN'})
        self.assertTrue(self.store.pause_requested())
        self.assertNotIn('merge_repair', self.bridge._ticket('MANAGED')['current_state'])

    def test_merge_repair_requires_qc_and_full_pr_review_before_push(self):
        request_id = self.merge_request()
        self.bridge.decide(request_id, {**self.approval, 'decision': 'REJECT'})
        ticket = self.bridge._ticket('MANAGED')
        ticket.update(worktree=self.temporary.name, base_commit='original-base')
        engine = Orchestrator.__new__(Orchestrator)
        engine.store, engine.config, engine.management = self.store, self.config, self.bridge
        engine.git = Mock()
        engine.git.git.return_value = 'old-sha'
        engine.git.diff_digest.side_effect = ['full-digest', 'correction-digest', 'full-digest']
        engine.git.stage_and_commit.return_value = 'new-sha'
        engine.git.push_and_open_pr.return_value = ticket['pr_url']
        engine._is_clean = Mock(return_value=True)
        result = Mock(exit_code=0)
        result.text.return_value = '{}'
        result.output_path = Path('/unused')
        engine._developer = Mock(return_value=result)
        engine._mechanical_qc = Mock(return_value={'passed': True, 'findings': []})
        review = Mock(exit_code=0)
        review.text.return_value = json.dumps({'verdict': 'PASS', 'findings': [], 'summary': '再レビュー成功'})
        review.output_path = Path('/unused')
        engine._review = Mock(return_value=review)
        remote = Mock(returncode=0, stdout=json.dumps({'state': 'OPEN', 'headRefOid': 'old-sha'}))
        with patch('tools.autodev.engine.subprocess.run', return_value=remote):
            engine._repair_rejected_merge(ticket)
        self.assertEqual(engine._developer.call_args.args[2][0]['kind'], 'management_merge_rejected')
        self.assertEqual(engine._mechanical_qc.call_args.args[0]['base_commit'], 'old-sha')
        self.assertEqual(engine._review.call_args.args[0]['base_commit'], 'original-base')
        self.assertEqual(engine.git.stage_and_commit.call_args.kwargs['base_revision'], 'old-sha')
        state = self.bridge._ticket('MANAGED')['current_state']
        self.assertEqual(state['reviewed_head_sha'], 'new-sha')
        self.assertNotIn('merge_repair', state)
        self.assertEqual(self.store.get_ticket('MANAGED')['status'], 'READY_TO_MERGE')
        engine.git.merge_if_green.assert_not_called()

        # A failed independent review must never push or register a reviewed SHA.
        self.store.update_ticket('MANAGED', current_state_json=json.dumps({
            'merge_revision': 1, 'merge_repair': {'request_id': request_id, 'head': 'old-sha', 'reason': '修正', 'cycles': 0}}))
        failed_ticket = self.bridge._ticket('MANAGED')
        failed_ticket.update(worktree=self.temporary.name, base_commit='original-base')
        engine.git.reset_mock()
        engine.git.diff_digest.side_effect = ['full', 'correction', 'full'] * 2
        review.text.return_value = json.dumps({'verdict': 'FAIL', 'findings': [{'severity': 'P1', 'summary': 'デグレ'}], 'summary': '失敗'})
        with patch('tools.autodev.engine.subprocess.run', return_value=remote):
            with self.assertRaisesRegex(RuntimeError, 'repair limit'):
                engine._repair_rejected_merge(failed_ticket)
        engine.git.stage_and_commit.assert_not_called()
        engine.git.push_and_open_pr.assert_not_called()
        self.assertNotIn('reviewed_head_sha', self.bridge._ticket('MANAGED')['current_state'])
