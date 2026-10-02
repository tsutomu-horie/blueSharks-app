"""Durable requests for the manager in the Codex desktop conversation.

This module never launches an AI process. The CLI only stores requests/decisions.
"""
from __future__ import annotations
import hashlib
import json
from pathlib import Path
import time

from .git_manager import GitManager
from .intake import _scope_list
from .state import dump, now


class ManagementPending(RuntimeError):
    def __init__(self, request_id, reason='waiting for Codex management decision'):
        self.request_id = request_id
        super().__init__(f'management request {request_id}: {reason}')


class ManagementBridge:
    def __init__(self, store, config):
        self.store, self.config = store, config
        self.git = GitManager(config)

    def _ticket(self, ticket_id):
        row = dict(self.store.get_ticket(ticket_id))
        for field in ('allowed_scope', 'forbidden_scope', 'current_state', 'dependencies', 'test_targets'):
            row[field] = json.loads(row[field + '_json'])
        row['acceptance_criteria'] = json.loads(row['acceptance_json'])
        row['tests'] = json.loads(row['test_ids_json'])
        row['max_repair_cycles'] = row['max_repairs']
        return row

    def _fingerprint(self, ticket, event, context):
        key = {name: ticket.get(name) for name in ('id','title','type','project','priority','risk','goal','request','acceptance_criteria','tests','test_targets','dependencies','allowed_scope','forbidden_scope','base_commit','specification_source','specification_checked_at')}
        key['write_permission'] = bool(ticket.get('write_permission'))
        key['max_repair_cycles'] = int(ticket.get('max_repair_cycles', ticket.get('max_repairs', 2)))
        key['specification_evidence'] = ticket.get('current_state', {}).get('specification_evidence')
        key['merge_revision'] = ticket.get('current_state', {}).get('merge_revision', 0)
        key.update(event=event, context=context)
        if ticket.get('worktree') and ticket.get('base_commit'):
            worktree = Path(ticket['worktree'])
            self.git.validate_worktree_identity(ticket['project'], ticket['id'], worktree)
            key['diff_digest'] = self.git.diff_digest(worktree, ticket['base_commit'])
            key['head_sha'] = self.git.git(worktree, ['rev-parse', 'HEAD'])
        return hashlib.sha256(json.dumps(key, sort_keys=True, ensure_ascii=False).encode()).hexdigest()

    def request(self, ticket, event, context, prompt, *, wait=True):
        fingerprint = self._fingerprint(ticket, event, context)
        payload = {'ticket_id': ticket['id'], 'event': event, 'context': context, 'prompt': prompt,
                   'fingerprint': fingerprint, 'worktree': ticket.get('worktree'), 'base_commit': ticket.get('base_commit')}
        with self.store.transaction() as db:
            db.execute('INSERT OR IGNORE INTO management_requests(ticket_id,event_type,request_key,payload_json,created_at) VALUES(?,?,?,?,?)',
                       (ticket['id'], event, fingerprint, dump(payload), now()))
            row = db.execute('SELECT * FROM management_requests WHERE request_key=?', (fingerprint,)).fetchone()
            if row['status'] == 'PENDING' and event in {'SCOPE_CHANGE_REQUESTED','SUPERVISOR_GATE','REPAIR_LIMIT_REACHED'}:
                current_ticket = db.execute('SELECT current_state_json FROM tickets WHERE id=?', (ticket['id'],)).fetchone()
                state = json.loads(current_ticket['current_state_json'])
                state['management_wait'] = {'request_id': row['id']}
                db.execute('UPDATE tickets SET current_state_json=?,updated_at=? WHERE id=?', (dump(state), now(), ticket['id']))
                ticket['current_state'] = state
        deadline = time.monotonic() + int(self.config.get('management', {}).get('timeout_seconds', 3600))
        while True:
            with self.store.connection() as db:
                current = db.execute('SELECT * FROM management_requests WHERE id=?', (row['id'],)).fetchone()
            if self.store.cancelled(ticket['id']):
                raise ManagementPending(row['id'], 'Ticket cancelled')
            if current['status'] == 'DECIDED':
                decision = json.loads(current['decision_json'])
                live = self._ticket(ticket['id'])
                if (event == 'MERGE_APPROVAL' and decision['decision'] == 'REJECT'
                    and live['current_state'].get('merge_repair', {}).get('request_id') == row['id']):
                    return decision
                if self._fingerprint(self._ticket(ticket['id']), event, context) != fingerprint:
                    with self.store.transaction() as db:
                        db.execute("UPDATE management_requests SET status='STALE' WHERE id=?", (row['id'],))
                    raise ManagementPending(row['id'], 'Ticket or diff changed after the decision')
                return json.loads(current['decision_json'])
            if not wait or self.store.pause_requested() or self.store.cancelled(ticket['id']) or time.monotonic() >= deadline:
                raise ManagementPending(row['id'])
            time.sleep(2)  # SQLite polling only; no model or CLI Supervisor is called.

    def pending(self):
        with self.store.connection() as db:
            return [dict(row) for row in db.execute("SELECT m.id,m.ticket_id,m.event_type,m.status,m.created_at,t.title FROM management_requests m JOIN tickets t ON t.id=m.ticket_id WHERE (m.status IN ('PENDING','STALE') OR (m.status='DECIDED' AND t.status='NEEDS_DECISION' AND json_extract(t.current_state_json,'$.management_wait.request_id')=m.id)) AND t.status NOT IN ('DONE','CANCELLED') ORDER BY m.id")]

    def show(self, request_id):
        with self.store.connection() as db:
            row = db.execute('SELECT * FROM management_requests WHERE id=?', (request_id,)).fetchone()
        if row is None:
            raise KeyError(request_id)
        result = dict(row)
        result['payload'] = json.loads(result.pop('payload_json'))
        decision = result.pop('decision_json')
        result['decision'] = json.loads(decision) if decision else None
        return result

    def decide(self, request_id, decision, actor='Codex management thread'):
        required = {'decision', 'rationale', 'next_status', 'scope_additions'}
        if set(decision) != required or decision['decision'] not in {'APPROVE','REJECT','NEEDS_HUMAN'}:
            raise ValueError('Submit a final management decision; Astra escalation is handled in Codex before submission')
        if decision['next_status'] not in {'READY','BACKLOG','NEEDS_SPECIFICATION','BLOCKED','REPLAN'} or not str(decision['rationale']).strip():
            raise ValueError('A valid next status and concrete rationale are required')
        additions = _scope_list(decision['scope_additions'], 'scope_additions', allow_empty=True)
        request = self.show(request_id)
        if request['status'] == 'DECIDED':
            if request['decision'] != decision:
                raise ValueError('An existing decision cannot be overwritten')
            ticket = self._ticket(request['ticket_id'])
            if ticket['status'] == 'NEEDS_DECISION' and (ticket['current_state'].get('management_wait') or {}).get('request_id') == request_id:
                if self._fingerprint(ticket, request['event_type'], request['payload']['context']) != request['payload']['fingerprint']:
                    raise ValueError('Management request is stale; cannot resume')
                with self.store.transaction() as db:
                    self._resume_waiting(db, request, ticket, decision)
            return
        ticket = self._ticket(request['ticket_id'])
        if ticket['status'] in {'DONE','CANCELLED'}:
            raise ValueError('The Ticket is no longer active')
        for pattern in additions:
            if pattern in {'*','**','.'} or any(self.git.patterns_overlap(pattern, forbidden) for forbidden in ticket['forbidden_scope']):
                raise ValueError('Management cannot approve forbidden or repository-wide scope')
        if request['event_type'] == 'MERGE_APPROVAL' and additions:
            raise ValueError('A merge approval cannot change the reviewed scope')
        payload = request['payload']
        if self._fingerprint(ticket, request['event_type'], payload['context']) != payload['fingerprint']:
            raise ValueError('Management request is stale; review the current Ticket/diff before deciding')
        with self.store.transaction() as db:
            existing = db.execute('SELECT status,decision_json FROM management_requests WHERE id=?', (request_id,)).fetchone()
            if existing['status'] == 'DECIDED':
                if json.loads(existing['decision_json']) != decision:
                    raise ValueError('An existing decision cannot be overwritten')
                return
            db.execute("UPDATE management_requests SET status='DECIDED',decision_json=?,actor=?,resolved_at=? WHERE id=?", (dump(decision), actor, now(), request_id))
            if decision['decision'] == 'NEEDS_HUMAN':
                db.execute("UPDATE control_flags SET pause_requested=1,reason=?,updated_at=? WHERE id=1", ('Codex manager requires human judgment: ' + decision['rationale'][:300], now()))
            self.store._event(db, ticket['id'], 'CODEX_MANAGEMENT_DECIDED', ticket['status'], ticket['status'], {'request_id': request_id, 'actor': actor, **decision})
            self._resume_waiting(db, request, ticket, decision)

    def _resume_waiting(self, db, request, ticket, decision):
        state = ticket['current_state']
        if request['event_type'] == 'MERGE_APPROVAL' and decision['decision'] == 'REJECT':
            if ticket['status'] != 'READY_TO_MERGE' or not ticket.get('pr_url') or not state.get('reviewed_head_sha'):
                raise ValueError('Merge repair requires an active reviewed PR')
            if state.get('merge_repair', {}).get('request_id') == request['id']:
                return
            state['merge_repair'] = {'request_id': request['id'], 'head': state.pop('reviewed_head_sha'),
                                   'reason': decision['rationale'], 'cycles': 0}
            state['merge_revision'] = int(state.get('merge_revision', 0)) + 1
            state.pop('next_merge_check_at', None)
            db.execute("UPDATE tickets SET current_state_json=?,updated_at=? WHERE id=?", (dump(state), now(), ticket['id']))
            self.store._event(db, ticket['id'], 'MERGE_APPROVAL_REVOKED_FOR_REPAIR', ticket['status'], ticket['status'], {'request_id': request['id'], 'reason': decision['rationale']})
            return
        if ticket['status'] != 'NEEDS_DECISION' or (state.get('management_wait') or {}).get('request_id') != request['id'] or decision['decision'] != 'APPROVE' or request['event_type'] not in {'SCOPE_CHANGE_REQUESTED','SUPERVISOR_GATE'}:
            return
        scopes = sorted(set(ticket['allowed_scope'] + decision['scope_additions']))
        if request['event_type'] == 'SUPERVISOR_GATE':
            gates = [{'category': entry['category'], 'files': sorted(entry['files']), 'digest': entry['digest']} for entry in request['payload']['context'].get('gates', [])]
            state['approved_gate_evidence'] = state.get('approved_gate_evidence', []) + gates
        state['management_decision'] = decision
        state.pop('management_wait', None)
        db.execute("UPDATE tickets SET status='READY',allowed_scope_json=?,current_state_json=?,updated_at=? WHERE id=?", (dump(scopes), dump(state), now(), ticket['id']))
        self.store._event(db, ticket['id'], 'CODEX_MANAGEMENT_RESUMED', 'NEEDS_DECISION', 'READY', {'request_id': request['id']})
