import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/app/data/models/game_guide/game_guide_post.dart';
import 'package:koto_blue_sharks/app/providers/game_guide/game_guide_filter_provider.dart';

String fixture(String f) =>
    File('test/game_guide/fixtures/$f').readAsStringSync();
GameGuidePost post(String path) => GameGuidePost(
    id: 1,
    title: '記事',
    publishedAt: null,
    detailUrl: 'https://blue-sharks.donati.jp/game-guide/$path/');
const season = [
  {
    'id': 50,
    'name': '2025 – 2026 シーズン',
    'link':
        'https://blue-sharks.donati.jp/schedule-and-result/season/season_2025_2026/'
  }
];
String card(String path, String state, {String venue = '夢の島競技場'}) => '''
<article class="match-card"><p class="match-card__venue">$venue</p>
<span class="match-card__badge--result">$state</span>
<div class="match-card__actions"><a href="/game-guide/$path/">ホストイベント情報</a></div></article>''';
GameGuideFilterProvider source(String cards) => GameGuideFilterProvider(
    load: (url) async => url.path.endsWith('/season')
        ? jsonEncode(season)
        : '<main><section class="season">$cards</section></main>');

void main() {
  test('公開14記事を試合側の直接リンクで全件照合し、全シーズン・開催地・終了状態を得る', () async {
    final seasons = (jsonDecode(fixture('seasons.json')) as List).cast<Map>();
    final requests = <Uri>[];
    final provider = GameGuideFilterProvider(load: (url) async {
      requests.add(url);
      if (url.path.endsWith('/season')) return fixture('seasons.json');
      final record =
          seasons.singleWhere((s) => Uri.parse(s['link']).path == url.path);
      return fixture('${record['id']}.html');
    });
    final articles = (jsonDecode(fixture('guides.json')) as List)
        .map((p) => GameGuidePost.fromJson(Map<String, dynamic>.from(p)))
        .toList();
    final first = await provider.attach(articles.take(10).toList());
    final second = await provider.attach(articles.skip(10).toList());
    final all = [...first, ...second];
    expect(all, hasLength(14));
    expect(
        all.every((p) =>
            p.season != null && p.location != null && p.status == '試合終了'),
        isTrue);
    expect(all.map((p) => p.season).toSet(),
        {'2024 – 2025 シーズン', '2025 – 2026 シーズン'});
    expect(provider.unavailable, isFalse);
    expect(requests, hasLength(9));
    // Article title says 2/11, but the linking schedule says 2/8. No date guessing.
    expect(all.singleWhere((p) => p.id == 20769).season, '2024 – 2025 シーズン');
    provider.reset();
    await provider.attach(articles);
    expect(requests, hasLength(18));
    provider.onDelete();
  });
  test('試合前/WIN/LOSE/DRAWのみを開催状態にし、中止・延期・不明・未照合は未設定にする', () async {
    final provider = source(['試合前', 'WIN', 'LOSE', 'DRAW', '中止', '延期', '']
        .indexed
        .map((v) => card('${v.$1}', v.$2))
        .join());
    final result = await provider.attach(List.generate(8, (i) => post('$i')));
    expect(result.map((p) => p.status).toList(),
        ['開催予定', '試合終了', '試合終了', '試合終了', null, null, null, null]);
    expect(result.last.season, isNull);
    provider.onDelete();
  });
  test('日付やタイトルが似ていても紐づかない記事を推測せず、競合リンクも未設定にする', () async {
    final provider = source(card('same', 'WIN') + card('same', '試合前'));
    final result = await provider.attach([post('same'), post('other')]);
    expect(result.every((p) => p.season == null && p.status == null), isTrue);
    provider.onDelete();
  });
  test('エンコード表記と末尾スラッシュ・クエリの違いを照合し、外部URLへ取得に行かない', () async {
    final provider = source(card('%E6%B5%B7', 'WIN'));
    final article = GameGuidePost(
        id: 1,
        title: '海',
        publishedAt: null,
        detailUrl:
            'https://blue-sharks.donati.jp/game-guide/%e6%b5%b7?utm_source=app');
    expect((await provider.attach([article])).single.status, '試合終了');
    provider.onDelete();
    var calls = 0;
    final external = GameGuideFilterProvider(load: (_) async {
      calls++;
      throw StateError('external');
    });
    await external.attach([
      GameGuidePost(
          id: 2,
          title: '外部',
          publishedAt: null,
          detailUrl: 'https://example.test/game-guide/1/')
    ]);
    expect(calls, 0);
    external.onDelete();
  });
  test('試合情報の通信失敗は記事を残して未設定と警告を返し、refreshで再試行できる', () async {
    var fail = true;
    final provider = GameGuideFilterProvider(load: (url) async {
      if (fail) throw StateError('offline');
      return url.path.endsWith('/season')
          ? jsonEncode(season)
          : '<main><section class="season">${card('one', 'WIN')}</section></main>';
    });
    final failed = await provider.attach([post('one')]);
    expect(failed.single.title, '記事');
    expect(failed.single.status, isNull);
    expect(provider.unavailable, isTrue);
    fail = false;
    provider.reset();
    expect((await provider.attach([post('one')])).single.status, '試合終了');
    expect(provider.unavailable, isFalse);
    provider.onDelete();
  });
}
