"""Retain bounded connector evidence without keeping document or credential bodies."""
from __future__ import annotations
import base64
import binascii
import hashlib
import json
import re


def drive_id(value):
    match = re.search(r"/(?:folders|d)/([^/?#]+)", str(value or ""))
    return match.group(1) if match else str(value or "")


def _structured(result):
    if not isinstance(result, dict):
        return {}
    data = result.get('structuredContent') or result.get('structured_content')
    if isinstance(data, dict):
        return data
    for block in result.get('content', []):
        if isinstance(block, dict) and block.get('type') == 'text':
            try:
                data = json.loads(block.get('text', ''))
            except (ValueError, TypeError):
                continue
            if isinstance(data, dict):
                return data
    return result if any(key in result for key in ('files', 'results', 'values', 'spreadsheetId')) else {}


def extract_tool_evidence(item, settings=None):
    if not str(item.get('tool', '')).startswith('google_drive.'):
        return None
    arguments = item.get('arguments') or {}
    if isinstance(arguments, str):
        try:
            arguments = json.loads(arguments)
        except ValueError:
            return None
    if not isinstance(arguments, dict):
        return None
    result = item.get('result') or {}
    data = _structured(result)
    parent = re.search(r"'([A-Za-z0-9_-]+)'\s+in\s+parents", str(arguments.get('special_filter_query_str', '')))
    target = (arguments.get('spreadsheet_id') or arguments.get('spreadsheet_url') or arguments.get('document_id')
              or arguments.get('document_url') or arguments.get('presentation_id') or arguments.get('presentation_url')
              or arguments.get('file_id') or arguments.get('url'))
    evidence = {
        'target_id': drive_id(target),
        'parent_id': parent.group(1) if parent else None,
        'sheet_name': arguments.get('sheet_name'), 'requested_range': arguments.get('range'),
        'limit': arguments.get('top_k', arguments.get('topn', 100)),
        'succeeded': bool(result) and not result.get('isError', result.get('is_error', False)) and not item.get('error'),
        'result_keys': list(result),
        'content_hash': hashlib.sha256(json.dumps(result, sort_keys=True, ensure_ascii=False).encode()).hexdigest(),
        'partial': bool(data.get('partial') or data.get('truncated') or data.get('is_truncated') or data.get('next_page_token') or data.get('nextPageToken')),
    }
    evidence['unfiltered_listing'] = item['tool'] == 'google_drive.list_folder' and set(arguments).issubset({'url', 'top_k'})
    files = data.get('files') or data.get('results') or []
    evidence['files'] = [{
        'id': entry.get('id'), 'title': entry.get('title') or entry.get('name'),
        'mime_type': entry.get('mime_type') or entry.get('mimeType'),
        'modified_at': entry.get('modified_time') or entry.get('updated_at') or entry.get('modifiedTime'),
    } for entry in files if isinstance(entry, dict)]
    method = item['tool'].split('.', 1)[1]
    if method == 'get_spreadsheet_range':
        values = data.get('values', [])
        rows = [row for row in values if any(value not in ('', None) for value in row)]
        chars = sum(len(str(value)) for row in rows for value in row if value not in ('', None))
        start = re.search(r'[A-Za-z]+(\d+)', str(arguments.get('range', '')))
        cells = sum(value not in ('', None) for row in rows for value in row)
        evidence['read_location'] = 'sheet:' + str(arguments.get('sheet_name', '')) + '!' + str(arguments.get('range', ''))
        expected_range = str(arguments.get('range', '')).upper()
        if ':' not in expected_range:
            expected_range += ':' + expected_range
        actual = re.fullmatch(r"(?:'((?:[^']|'')+)'|([^!]+))!([A-Za-z]+\d+(?::[A-Za-z]+\d+)?)", str(data.get('range', '')))
        location_matches = False
        if actual:
            tab = (actual.group(1) or actual.group(2)).replace("''", "'")
            actual_range = actual.group(3).upper()
            if ':' not in actual_range:
                actual_range += ':' + actual_range
            location_matches = tab == arguments.get('sheet_name') and actual_range == expected_range
        evidence['substantive'] = location_matches and (len(rows) >= 2 or chars >= 200 or bool(start and int(start.group(1)) > 1 and cells >= 3))
        evidence['body_hash'] = hashlib.sha256(json.dumps(values, ensure_ascii=False).encode()).hexdigest()
    elif method == 'fetch':
        body = data.get('text') or data.get('content') or ''
        if not isinstance(body, str):
            body = ''
        if not body and not data:
            blocks = []
            for block in result.get('content', []):
                if block.get('type') != 'text':
                    continue
                text = block.get('text', '')
                try:
                    json.loads(text)
                except (ValueError, TypeError):
                    blocks.append(text)
            body = '\n'.join(blocks)
        # Some connector versions return small text files through the legacy
        # byte field instead of readable content. Opt in explicitly, decode
        # only bounded UTF-8 text, and retain only its hash (never the bytes).
        if not body and settings and settings.get('text_base64_compatibility'):
            encoded = data.get('b64_string')
            mime = data.get('mime_type', '')
            filename = str(data.get('file_name', '')).lower()
            credential_file = any(value in filename for value in
                ('.env', 'firebase_options', 'google-services', 'googleservice-info',
                 'credential', 'private_key', 'private-key', 'privatekey',
                 'account_register', '.pem', '.key', '.p12', '.pfx', 'secret', 'token'))
            if (isinstance(encoded, str) and len(encoded) <= 1400000
                and mime in {'text/plain', 'text/markdown', 'text/x-markdown', 'text/html'}
                and data.get('id') == evidence['target_id'] and not credential_file):
                try:
                    body = base64.b64decode(encoded, validate=True).decode('utf-8')
                    if (re.search(r'[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]', body)
                        or re.search(r'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----', body)):
                        body = ''
                except (ValueError, UnicodeDecodeError, binascii.Error):
                    body = ''
        evidence['read_location'] = 'file:full'
        evidence['substantive'] = len(body) >= 200
        evidence['body_hash'] = hashlib.sha256(str(body).encode()).hexdigest()
    if 'spreadsheetId' in data:
        evidence['spreadsheet_id'] = data['spreadsheetId']
        evidence['spreadsheet_title'] = data.get('properties', {}).get('title')
        evidence['sheets'] = [entry.get('properties', {}) for entry in data.get('sheets', [])]
    # Only the explicitly authorized worklog gets cell content in the audit log.
    if settings and evidence['target_id'] == settings.get('spreadsheet_id') and arguments.get('sheet_name') == settings.get('worklog_sheet_name') and item['tool'] == 'google_drive.get_spreadsheet_range':
        rectangle = re.search(r"!A(\d+):G(\d+)$", str(data.get('range', '')))
        if rectangle and int(rectangle.group(2)) - int(rectangle.group(1)) < 20:
            evidence['range'] = data.get('range')
            evidence['values'] = data.get('values', [])
    return evidence


def completed_evidence(events, method):
    return [event['evidence'] for event in events if event.get('type') == 'item.completed'
            and event.get('status') == 'completed' and event.get('tool') == 'google_drive.' + method
            and event.get('evidence', {}).get('succeeded')]


def complete_inventory(events, root_id):
    listings = {item['target_id']: item for item in completed_evidence(events, 'list_folder')}
    pending, visited, files = [root_id], set(), {}
    while pending:
        folder = pending.pop()
        if folder in visited:
            continue
        listing = listings.get(folder)
        if not listing or not listing.get('unfiltered_listing') or listing['partial'] or len(listing['files']) >= int(listing['limit']):
            return None
        visited.add(folder)
        for entry in listing['files']:
            if not entry.get('id'):
                return None
            files[entry['id']] = entry
            if entry['mime_type'] == 'application/vnd.google-apps.folder':
                pending.append(entry['id'])
    return files


def observed_content_ids(events):
    return set(observed_read_locations(events))


def read_location_contains(observed: str, claimed: str) -> bool:
    """Whether a substantive read rectangle actually contains a claimed section.

    The connector can return a broad, bounded range while the investigator
    cites a smaller section inside it. Provenance keeps both ranges explicit;
    this never accepts a claim extending outside the actual read.
    """
    if observed == claimed:
        return True
    if observed == 'file:full' or claimed == 'file:full':
        return False
    def parse(location):
        if not location.startswith('sheet:') or '!' not in location:
            return None
        sheet, cells = location[6:].rsplit('!', 1)
        match = re.fullmatch(r'([A-Z]+)(\d+)(?::([A-Z]+)(\d+))?', cells.upper())
        if not match:
            return None
        def column_number(value):
            number = 0
            for char in value:
                number = number * 26 + ord(char) - ord('A') + 1
            return number
        start_col, start_row = column_number(match.group(1)), int(match.group(2))
        end_col = column_number(match.group(3) or match.group(1))
        end_row = int(match.group(4) or match.group(2))
        return sheet, start_col, start_row, end_col, end_row

    actual, section = parse(observed), parse(claimed)
    return bool(actual and section and actual[0] == section[0]
                and actual[1] <= section[1] <= section[3] <= actual[3]
                and actual[2] <= section[2] <= section[4] <= actual[4])


def observed_read_locations(events):
    result = {}
    for method in ('fetch', 'get_spreadsheet_range'):
        for item in completed_evidence(events, method):
            if item['partial'] or not item.get('substantive'):
                continue
            result.setdefault(item['target_id'], {})[item['read_location']] = item['body_hash']
    return result


def worklog_readback(events, settings, row, values):
    for entry in completed_evidence(events, 'get_spreadsheet_range'):
        if entry['target_id'] != settings['spreadsheet_id'] or entry['sheet_name'] != settings['worklog_sheet_name']:
            continue
        match = re.search(r"!A(\d+):G(\d+)$", str(entry.get('range', '')))
        if not match:
            continue
        start, end = map(int, match.groups())
        offset = row - start
        actual = entry.get('values', [])
        if start <= row <= end and offset < len(actual) and actual[offset] == values:
            return True
    return False
