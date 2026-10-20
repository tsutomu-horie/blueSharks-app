// Run directly with Dart and the existing package config; no Flutter engine,
// network, credentials, or response body is needed.
import 'dart:io' show stdout;

import 'package:get/get_connect/http/src/response/client_response.dart';

import 'package:koto_blue_sharks/app/providers/auth/login_response_diagnostics.dart';

var _checks = 0;

void _expect(bool condition, String description) {
  _checks++;
  if (!condition) throw StateError(description);
}

class _Headers implements HttpHeaders {
  _Headers(this.values, {this.fail = false});

  final Map<String, String> values;
  final bool fail;
  final readNames = <String>[];

  @override
  String? value(String name) {
    readNames.add(name);
    if (fail) throw StateError('PRIVATE_EXCEPTION_CANARY');
    if (name != 'content-type' && name != 'content-encoding') {
      throw StateError('Unexpected header access');
    }
    return values[name];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected header access');
}

class _Redirect implements RedirectInfo {
  var unexpectedAccesses = 0;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    unexpectedAccesses++;
    throw StateError('PRIVATE_REDIRECT_QUERY_CANARY');
  }
}

class _Response implements HttpClientResponse {
  _Response({
    Map<String, String> headers = const {},
    this.statusCode = 200,
    this.contentLength = 512,
    this.isRedirect = false,
    this.redirects = const [],
    bool failHeaders = false,
  }) : headers = _Headers(headers, fail: failHeaders);

  @override
  final _Headers headers;
  @override
  final int statusCode;
  @override
  final int contentLength;
  @override
  final bool isRedirect;
  @override
  final List<RedirectInfo> redirects;
  var unexpectedAccesses = 0;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    unexpectedAccesses++;
    throw StateError('Response stream or unrelated field accessed');
  }
}

String _line(_Response response) {
  final line = loginResponseDiagnosticLine(response);
  _expect(response.unexpectedAccesses == 0, 'Must not consume the body stream');
  _expect(line.length <= 256, 'Log line must be bounded');
  _expect(
      !RegExp(r'[^\x20-\x7e]').hasMatch(line), 'Log must be one ASCII line');
  _expect(
      !line.contains('PRIVATE_'), 'Canary must not escape into diagnostics');
  _expect(
    response.headers.readNames.every(
      (name) => name == 'content-type' || name == 'content-encoding',
    ),
    'Only allowlisted headers may be read',
  );
  return line;
}

void main() {
  final utf8 = _line(_Response(headers: {
    'content-type': 'Application/JSON; Charset="UTF-8"',
    'content-encoding': 'gzip',
    'authorization': 'PRIVATE_AUTH_CANARY',
    'set-cookie': 'PRIVATE_COOKIE_CANARY',
  }));
  _expect(
    utf8 ==
        '[login-response] status=200 media=application/json charset=utf-8 '
            'encoding=gzip length=512 is_redirect=false redirects=0',
    'Expected JSON/UTF-8 metadata',
  );

  final redirect = _Redirect();
  final html = _line(_Response(
    headers: {'content-type': 'text/html; charset=Shift_JIS'},
    statusCode: 401,
    contentLength: -1,
    redirects: [redirect],
  ));
  _expect(html.contains('status=401 media=text/html charset=shift_jis'),
      'Non-UTF-8 HTML must remain visible as metadata');
  _expect(html.contains('length=unknown'), 'Unknown length must be explicit');
  _expect(html.endsWith('redirects=1'), 'Only redirect count may be logged');
  _expect(redirect.unexpectedAccesses == 0, 'Must not read redirect URLs');

  final missing = _line(_Response());
  _expect(missing.contains('media=missing charset=missing encoding=missing'),
      'Missing metadata must be explicit');
  final duplicates = _line(_Response(headers: {
    'content-type': 'text/html; charset=utf-8; charset=PRIVATE_CHARSET_CANARY',
  }));
  _expect(duplicates.contains('charset=other'), 'Reject duplicate charsets');
  final combined = _line(_Response(headers: {'content-encoding': 'gzip, br'}));
  _expect(
      combined.contains('encoding=gzip+br'), 'Canonicalize allowed encodings');
  final extra = _line(_Response(headers: {
    'content-type':
        'application/json; charset=utf8; token=PRIVATE_TOKEN_CANARY',
  }));
  _expect(
      extra.contains('charset=utf-8'), 'Ignore unrelated parameters safely');

  final adversarial = [
    'PRIVATE_HEADER_CANARY',
    'application/PRIVATE_MEDIA_CANARY',
    'text/html; charset=PRIVATE_CHARSET_CANARY',
    'application/json\r\nAuthorization: PRIVATE_AUTH_CANARY',
    'application/json; charset=utf-8\u0000PRIVATE_NUL_CANARY',
    'text/html; charset="utf-8" PRIVATE_QUOTE_CANARY',
    'text/html; charset=秘密PRIVATE_UNICODE_CANARY',
    'PRIVATE_LONG_CANARY${'x' * 1024}',
  ];
  for (final value in adversarial) {
    _line(_Response(headers: {
      'content-type': value,
      'content-encoding': value,
    }));
  }
  final invalid = _line(_Response(
    statusCode: 999,
    contentLength: 1 << 60,
    isRedirect: true,
    redirects: List.generate(21, (_) => _Redirect()),
  ));
  _expect(invalid.contains('status=unknown'), 'Bound status codes');
  _expect(invalid.contains('length=unknown'), 'Bound response length');
  _expect(invalid.endsWith('redirects=unknown'), 'Bound redirect count');
  final broken = _line(_Response(failHeaders: true));
  _expect(broken == '[login-response] metadata=unavailable',
      'Diagnostic failure must be safe and must not interrupt decoding');

  stdout.writeln('PASS: $_checks offline metadata/privacy checks');
}
