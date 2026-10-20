import 'package:get/get_connect/http/src/response/client_response.dart';

/// Reads only allowlisted metadata; never listens to the response body stream.
String loginResponseDiagnosticLine(HttpClientResponse response) {
  try {
    final contentType = _contentType(response.headers.value('content-type'));
    final encoding =
        _contentEncoding(response.headers.value('content-encoding'));
    final status = _number(response.statusCode, 100, 599);
    final length = _number(response.contentLength, 0, 1 << 40);
    final redirects = _number(response.redirects.length, 0, 20);

    return '[login-response] status=$status media=${contentType.media} '
        'charset=${contentType.charset} encoding=$encoding length=$length '
        'is_redirect=${response.isRedirect} redirects=$redirects';
  } catch (_) {
    // Malformed/duplicate headers must not interrupt the normal decoder or leak.
    return '[login-response] metadata=unavailable';
  }
}

String _number(int value, int minimum, int maximum) =>
    value >= minimum && value <= maximum ? '$value' : 'unknown';

bool _safeHeader(String value) =>
    value.length <= 256 && !RegExp(r'[^\x20-\x7e]').hasMatch(value);

({String media, String charset}) _contentType(String? value) {
  if (value == null) return (media: 'missing', charset: 'missing');
  if (!_safeHeader(value)) return (media: 'other', charset: 'other');

  final parts = value.toLowerCase().split(';');
  const mediaTypes = {
    'application/json',
    'application/problem+json',
    'text/html',
    'text/plain',
    'application/octet-stream',
  };
  final candidate = parts.first.trim();
  final media = mediaTypes.contains(candidate) ? candidate : 'other';
  var charset = 'missing';
  var charsetCount = 0;
  for (final parameter in parts.skip(1)) {
    final pair = parameter.split('=');
    if (pair.first.trim() != 'charset') continue;
    charsetCount++;
    if (charsetCount > 1 || pair.length != 2) {
      charset = 'other';
      continue;
    }
    var name = pair[1].trim();
    if (name.startsWith('"') && name.endsWith('"') && name.length >= 2) {
      name = name.substring(1, name.length - 1);
    }
    const charsets = {
      'utf-8': 'utf-8',
      'utf8': 'utf-8',
      'us-ascii': 'us-ascii',
      'ascii': 'us-ascii',
      'iso-8859-1': 'iso-8859-1',
      'latin1': 'iso-8859-1',
      'latin-1': 'iso-8859-1',
      'shift_jis': 'shift_jis',
      'shift-jis': 'shift_jis',
      'sjis': 'shift_jis',
      'windows-31j': 'windows-31j',
      'cp932': 'windows-31j',
      'euc-jp': 'euc-jp',
      'iso-2022-jp': 'iso-2022-jp',
      'utf-16': 'utf-16',
      'utf-16le': 'utf-16le',
      'utf-16be': 'utf-16be',
      'windows-1252': 'windows-1252',
    };
    charset = charsets[name] ?? 'other';
  }
  return (media: media, charset: charset);
}

String _contentEncoding(String? value) {
  if (value == null) return 'missing';
  if (!_safeHeader(value)) return 'other';
  final encodings = value.toLowerCase().split(',').map((part) => part.trim());
  const allowed = {'identity', 'gzip', 'deflate', 'br'};
  if (encodings.length > 3 || !encodings.every(allowed.contains)) {
    return 'other';
  }
  return encodings.join('+');
}
