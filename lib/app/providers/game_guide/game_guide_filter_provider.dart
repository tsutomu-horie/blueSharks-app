import 'dart:convert';

import 'package:get/get.dart';
import 'package:html/parser.dart' as html;
import 'package:koto_blue_sharks/app/data/models/game_guide/game_guide_post.dart';
import 'package:koto_blue_sharks/utils/constant.dart';

class GameGuideFilterData {
  const GameGuideFilterData(this.season, this.location, this.status);
  final String season;
  final String? location;
  final String? status;

  bool matches(GameGuideFilterData other) =>
      season == other.season &&
      location == other.location &&
      status == other.status;
}

/// Join articles through the schedule's published host-event links, never dates.
class GameGuideFilterProvider extends GetConnect {
  GameGuideFilterProvider({Future<String> Function(Uri)? load}) : _load = load {
    httpClient.timeout = const Duration(seconds: 20);
    httpClient.addRequestModifier<dynamic>(
        (request) => request.copyWith(followRedirects: false));
  }

  final Future<String> Function(Uri)? _load;
  Future<Map<String, GameGuideFilterData?>>? _snapshot;
  bool unavailable = false;
  Uri get _api => Uri.parse(Constants.baseUrl);
  Uri get _site => _api.resolve('/');

  void reset() {
    _snapshot = null;
    unavailable = false;
  }

  Uri? _siteUrl(String value) {
    final url = _site.resolve(value);
    return url.scheme == 'https' &&
            url.host == _site.host &&
            url.port == 443 &&
            url.userInfo.isEmpty
        ? url
        : null;
  }

  String? _guideKey(String value) {
    try {
      final url = _siteUrl(value);
      if (url == null || !url.path.startsWith('/game-guide/')) return null;
      // Decode path segments separately, preserving encoded slash boundaries.
      final parts = url.pathSegments.toList();
      if (parts.isNotEmpty && parts.last.isEmpty) parts.removeLast();
      return parts.join('\u0000');
    } on FormatException {
      return null;
    }
  }

  Future<String> _read(Uri url) async {
    if (_siteUrl(url.toString()) == null) {
      throw const FormatException('Unexpected website URL.');
    }
    final String body;
    if (_load != null) {
      body = await _load(url);
    } else {
      final response = await get<String>(url.toString(),
          decoder: (value) => value is String ? value : jsonEncode(value));
      if (response.statusCode != 200 || response.body == null) {
        throw StateError('Schedule request failed.');
      }
      body = response.body!;
    }
    if (body.length > 2 * 1024 * 1024) {
      throw const FormatException('Website response too large.');
    }
    return body;
  }

  Future<List<GameGuidePost>> attach(List<GameGuidePost> posts) async {
    if (!posts.any((post) => _guideKey(post.detailUrl) != null)) return posts;
    final data = await (_snapshot ??= _loadSnapshot());
    return posts.map((post) {
      final match = data[_guideKey(post.detailUrl)];
      return post.withFilters(
          season: match?.season,
          location: match?.location,
          status: match?.status);
    }).toList();
  }

  Future<Map<String, GameGuideFilterData?>> _loadSnapshot() async {
    final result = <String, GameGuideFilterData?>{};
    try {
      final seasons = <Map<String, dynamic>>[];
      final seen = <int>{};
      for (var page = 1;; page++) {
        final items = jsonDecode(await _read(_api.resolve('season').replace(
            queryParameters: {
              'per_page': '100',
              'page': '$page',
              '_fields': 'id,name,link'
            }))) as List;
        for (final item in items) {
          final season = Map<String, dynamic>.from(item as Map);
          if (season['id'] is! int || !seen.add(season['id'] as int)) {
            throw const FormatException('Repeated season page.');
          }
          seasons.add(season);
        }
        if (items.length < 100) break;
      }
      // Bound parallel requests; reuse the same snapshot for subsequent pages.
      for (var i = 0; i < seasons.length; i += 3) {
        await Future.wait(seasons.skip(i).take(3).map((season) async {
          try {
            final url = _siteUrl(season['link'] as String);
            final name = (season['name'] as String).trim();
            if (url == null ||
                name.isEmpty ||
                !RegExp(r'^/schedule-and-result/season/[^/]+/$')
                    .hasMatch(url.path) ||
                url.hasQuery ||
                url.hasFragment) {
              throw const FormatException('Invalid season.');
            }
            final section =
                html.parse(await _read(url)).querySelector('main .season');
            if (section == null) throw const FormatException('Missing season.');
            for (final card in section.querySelectorAll('article.match-card')) {
              final raw =
                  card.querySelector('.match-card__badge--result')?.text.trim();
              final status = const {'WIN', 'LOSE', 'DRAW'}.contains(raw)
                  ? '試合終了'
                  : raw == '試合前'
                      ? '開催予定'
                      : null;
              final venue = card
                  .querySelector('.match-card__venue')
                  ?.text
                  .replaceAll(RegExp(r'\s+'), ' ')
                  .trim();
              final value = GameGuideFilterData(
                  name, venue == null || venue.isEmpty ? null : venue, status);
              for (final link
                  in card.querySelectorAll('.match-card__actions a[href]')) {
                final key = _guideKey(link.attributes['href']!);
                if (key == null) continue;
                if (!result.containsKey(key)) {
                  result[key] = value;
                } else if (result[key] == null ||
                    !result[key]!.matches(value)) {
                  // Conflicting matches are unknown, rather than guessed.
                  result[key] = null;
                }
              }
            }
          } catch (_) {
            unavailable = true;
          }
        }));
      }
    } catch (_) {
      unavailable = true;
    }
    return result;
  }
}
