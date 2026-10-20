import 'dart:convert';

import 'package:get/get.dart';
import 'package:html/dom.dart';
import 'package:koto_blue_sharks/app/data/models/match/match_result.dart';
import 'package:koto_blue_sharks/app/data/models/member/member.dart';
import 'package:koto_blue_sharks/app/data/models/website/renewal_website_content.dart';
import 'package:koto_blue_sharks/utils/constant.dart';

class RenewalWebsiteProvider extends GetConnect {
  RenewalWebsiteProvider({Future<String> Function(Uri)? load}) : _load = load {
    httpClient.addRequestModifier<dynamic>(
        (request) => request.copyWith(followRedirects: false));
  }

  final Future<String> Function(Uri)? _load;
  Uri get api => Uri.parse(Constants.baseUrl);
  Uri get site => api.resolve('/');
  final _positions = <int, Category>{};
  final _seasons = <int, Category>{};
  Future<Map<int, Element>>? _memberCards;
  final _matchCards = <int, Future<Map<int, Element>>>{};

  Future<String> _read(Uri url) async {
    if (RenewalWebsiteContent.siteUrl(site, url.toString()) == null) {
      throw const FormatException('Unexpected website URL.');
    }
    final loader = _load;
    final String body;
    if (loader != null) {
      body = await loader(url);
    } else {
      httpClient.timeout = const Duration(seconds: 20);
      final response = await get<String>(url.toString(),
          decoder: (value) => value is String ? value : jsonEncode(value));
      if (response.statusCode != 200 || response.body == null) {
        String? code;
        try {
          final error = jsonDecode(response.body ?? '');
          if (error is Map) code = error['code'] as String?;
        } on FormatException {
          // Non-JSON errors still retain their HTTP status.
        }
        throw RenewalWebsiteRequestException(response.statusCode, code);
      }
      body = response.body!;
    }
    if (body.length > 2 * 1024 * 1024) {
      throw const FormatException('Website response too large.');
    }
    return body;
  }

  Future<List<Map<String, dynamic>>> _list(String path,
      {int page = 1, int perPage = 100, Map<String, String>? query}) async {
    try {
      final value = jsonDecode(await _read(api.resolve(path).replace(
          queryParameters: {
            'page': '$page',
            'per_page': '$perPage',
            ...?query
          })));
      if (value is! List) throw const FormatException('Expected content list.');
      return value
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } on RenewalWebsiteRequestException catch (error) {
      // WordPress reports a page beyond the last one as HTTP 400.
      if (page > 1 &&
          error.statusCode == 400 &&
          error.code == 'rest_post_invalid_page') {
        return [];
      }
      rethrow;
    }
  }

  Future<List<Category>> memberCategories({int page = 1}) async {
    if (page == 1) _memberCards = null;
    final categories = (await _list('member_position', page: page))
        .map(Category.fromJson)
        .toList();
    for (final category in categories) {
      _positions[category.id] = category;
    }
    return categories;
  }

  Future<Map<int, Element>> _loadMemberCards() async {
    final pending = _memberCards ??= _read(site.resolve('/members/'))
        .then((body) => RenewalWebsiteContent.memberCards(body, site));
    try {
      return await pending;
    } catch (_) {
      if (identical(pending, _memberCards)) _memberCards = null;
      rethrow;
    }
  }

  Future<List<Member>> members(int categoryId, {int page = 1}) async {
    final posts = await _list('member', page: page, query: {
      'member_position': '$categoryId',
      'order': 'asc',
      'orderby': 'modified'
    });
    if (posts.isEmpty) return [];
    final cards = await _loadMemberCards();
    return posts
        .map((post) => RenewalWebsiteContent.member(post, categoryId,
            _positions[categoryId]?.slug, cards[post['id']], site))
        .toList();
  }

  Future<Member> memberDetail(Member member) async =>
      RenewalWebsiteContent.memberDetail(
          await _read(Uri.parse(member.link)), member, site);

  Future<List<Category>> seasons({int page = 1}) async {
    if (page == 1) _matchCards.clear();
    final categories =
        (await _list('season', page: page)).map(Category.fromJson).toList();
    for (final category in categories) {
      _seasons[category.id] = category;
    }
    return categories;
  }

  Future<Map<int, Element>> _loadMatchCards(int seasonId) async {
    final season = _seasons[seasonId];
    if (season == null) throw const FormatException('Unknown season.');
    final pending = _matchCards[seasonId] ??= _read(Uri.parse(season.link))
        .then((body) => RenewalWebsiteContent.matchCards(body, site));
    try {
      return await pending;
    } catch (_) {
      if (identical(pending, _matchCards[seasonId])) {
        _matchCards.remove(seasonId);
      }
      rethrow;
    }
  }

  Future<List<MatchResultBySeason>> matches(int seasonId,
      {int page = 1}) async {
    final posts = await _list('match',
        page: page, perPage: 10, query: {'season': '$seasonId'});
    if (posts.isEmpty) return [];
    final cards = await _loadMatchCards(seasonId);
    return posts.map((post) {
      final card = cards[post['id']];
      if (card == null) throw const FormatException('Match card not found.');
      return RenewalWebsiteContent.match(post, seasonId, card, site);
    }).toList();
  }

  Future<MatchResultBySeason> matchDetail(MatchResultBySeason match) async =>
      RenewalWebsiteContent.matchDetail(
          await _read(Uri.parse(match.link)), match, site);
}

class RenewalWebsiteRequestException implements Exception {
  const RenewalWebsiteRequestException(this.statusCode, [this.code]);
  final int? statusCode;
  final String? code;
}
