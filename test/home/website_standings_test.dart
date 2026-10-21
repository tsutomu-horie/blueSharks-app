import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/app/data/models/home/website_standings.dart';
import 'package:koto_blue_sharks/app/providers/home/website_video_provider.dart';
import 'package:koto_blue_sharks/app/views/views/other/views/website_standings_section.dart';
import 'package:koto_blue_sharks/presentation/home/controllers/home.controller.dart';

void main() {
  final home = Uri.parse('https://blue-sharks.donati.jp/');
  final top = File('test/home/fixtures/renewal_standings_top_20261016.html')
      .readAsStringSync();
  final full = File('test/home/fixtures/renewal_rankings_20261016.html')
      .readAsStringSync();
  test('TOP season・全列・数値とRANK実リンクを保持する', () {
    final s = WebsiteStandings.parseHomepage(top, home)!;
    expect(s.title, '2026-2027 公式戦順位');
    expect(s.headers, ['順位', '勝点', '勝', '負', '分']);
    expect(s.values, ['-', '0', '0', '0', '0']);
    expect(s.rankingsUrl, home.resolve('/rankings/'));
  });
  test('順位表ページのseason・15列・8チームを実HTMLから取得する', () {
    final t = WebsiteRankingsTable.parse(full)!;
    expect(t.title, contains('2026-27'));
    expect(t.headers, hasLength(15));
    expect(t.rows, hasLength(8));
    expect(t.rows.every((r) => r.length == 15), isTrue);
    expect(t.rows.any((r) => r[1] == '清水建設江東ブルーシャークス'), isTrue);
    expect(t.teamLogoUrls, hasLength(8));
    expect(t.teamLogoUrls.every((logo) => logo?.scheme == 'https'), isTrue);
    expect(t.teamLogoUrls[1].toString(), contains('%E4%B9%9D%E5%B7%9E.png'));
    expect(
        t.rows.every((r) => r.first == '-' && r.skip(2).every((v) => v == '0')),
        isTrue);
  });
  test('外部RANKや欠損・メンテナンス応答を捏造表示しない', () {
    expect(
        WebsiteStandings.parseHomepage(
            top.replaceAll('href="https://blue-sharks.donati.jp/rankings/"',
                'href="https://evil.example/rankings/"'),
            home),
        isNull);
    expect(WebsiteStandings.parseHomepage('<html></html>', home), isNull);
    expect(WebsiteRankingsTable.parse('<html>maintenance</html>'), isNull);
  });
  test('順位URLは既存環境の同一originと実パスだけを取得する', () async {
    final requested = <Uri>[];
    final provider = WebsiteVideoProvider(loadHomepage: (uri) async {
      requested.add(uri);
      return full;
    });
    expect((await provider.fetchRankings(home.resolve('/rankings/'))).rows,
        hasLength(8));
    expect(requested, [home.resolve('/rankings/')]);
    await expectLater(
        provider.fetchRankings(Uri.parse('https://evil.example/rankings/')),
        throwsA(isA<WebsiteVideoRequestException>()));
    expect(requested, hasLength(1));
    provider.httpClient.close();
  });
  test('TOP統合更新で順位取得と成功0件による旧順位消去を反映する', () async {
    var n = 0;
    final c = HomeController(
        websiteVideoProvider: WebsiteVideoProvider(
            loadHomepage: (_) async => ++n == 1 ? top : '<html/>'));
    await c.fetchWebsiteContent();
    expect(c.websiteStandings.value, isNotNull);
    await c.fetchWebsiteContent(force: true);
    expect(c.websiteStandings.value, isNull);
    c.onClose();
  });
  testWidgets('幅320/375/430・文字1/2倍、RANK画面遷移と失敗後再試行', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final data = WebsiteStandings.parseHomepage(top, home)!;
    for (final scale in [1.0, 2.0]) {
      for (final width in [320.0, 375.0, 430.0]) {
        tester.view.physicalSize = Size(width, 812);
        await tester.pumpWidget(MaterialApp(
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!),
            home: Scaffold(
                body: WebsiteStandingsSection(
                    key: ValueKey('$width-$scale'), standings: data))));
        await tester.pumpAndSettle();
        expect(find.text(data.title), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    }
    var calls = 0;
    Uri? requested;
    await tester.pumpWidget(MaterialApp(
        key: const ValueKey('navigation'),
        home: Scaffold(
            body: WebsiteStandingsSection(
                standings: data,
                loadRankings: (uri) async {
                  requested = uri;
                  if (++calls == 1) throw const WebsiteVideoRequestException();
                  return WebsiteRankingsTable.parse(full)!;
                }))));
    await tester.tap(find.byKey(const ValueKey('website-rank-link')));
    await tester.pumpAndSettle();
    expect(requested, data.rankingsUrl);
    expect(find.text('順位表を取得できませんでした。'), findsOneWidget);
    await tester.tap(find.text('再試行'));
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('website-ranking-team-0')), findsOneWidget);
    expect(calls, 2);
    expect(tester.takeException(), isNull);
  });
  test('欠損cellや空cellのあるチームを黙って省略せず全表を拒否する', () {
    final cell = RegExp(r'<td[^>]*>0</td>');
    final missing = full.replaceFirst(cell, '');
    final empty = full.replaceFirst(cell, '<td></td>');
    expect(missing, isNot(full));
    expect(WebsiteRankingsTable.parse(missing), isNull);
    expect(WebsiteRankingsTable.parse(empty), isNull);
  });

  test('GetConnectの実HTML decoder経路で順位表を取得する（HTTP transportはmock）', () async {
    final transport = _RecordingHttpClient(full);
    await HttpOverrides.runZoned(() async {
      final provider = WebsiteVideoProvider();
      final table = await provider.fetchRankings(home.resolve('/rankings/'));
      expect(table.rows, hasLength(8));
      expect(transport.requests.single.followRedirects, isFalse);
      expect(transport.visited, [home.resolve('/rankings/')]);
      provider.httpClient.close();
    }, createHttpClient: (_) => transport);
  });

  test('許可順位URLの302を追わず拒否しhomepage既存のredirect設定は保持する', () async {
    final transport = _RecordingHttpClient(full, redirectRankings: true);
    await HttpOverrides.runZoned(() async {
      final provider = WebsiteVideoProvider();
      await provider.fetchContent();
      expect(transport.requests.first.followRedirects, isTrue);
      await expectLater(provider.fetchRankings(home.resolve('/rankings/')),
          throwsA(isA<WebsiteVideoRequestException>()));
      expect(transport.requests.last.followRedirects, isFalse);
      expect(transport.visited, [home, home.resolve('/rankings/')]);
      provider.httpClient.close();
    }, createHttpClient: (_) => transport);
  });

  test('公開season表記2026-2027と2026-27を同一として照合する', () {
    expect(WebsiteStandings.seasonKey('2026-2027 公式戦順位'), '2026-2027');
    expect(WebsiteStandings.seasonKey('リーグワン 2026-27 ディビジョン2'), '2026-2027');
    expect(WebsiteStandings.seasonKey('2027-28'), isNot('2026-2027'));
    expect(WebsiteStandings.seasonKey('順位表'), isNull);
  });

  testWidgets('TOPと異なるseasonの順位を混在表示しない', (tester) async {
    final data = WebsiteStandings.parseHomepage(top, home)!;
    final nextSeason =
        WebsiteRankingsTable.parse(full.replaceAll('2026-27', '2027-28'))!;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: WebsiteStandingsSection(
                standings: data, loadRankings: (_) async => nextSeason))));
    await tester.tap(find.byKey(const ValueKey('website-rank-link')));
    await tester.pumpAndSettle();
    expect(find.text('順位表を取得できませんでした。'), findsOneWidget);
    expect(find.byKey(const ValueKey('website-ranking-team-0')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('ロゴは行順を保持し相対URLを解決、欠損・非HTTPSは成績を残して代替表示する', () {
    final logos = RegExp(r'<img class="rankings__logo"[^>]*>');
    var i = 0;
    final modified = full.replaceAllMapped(
        logos,
        (match) => switch (i++) {
              0 => '',
              1 => '<img class="rankings__logo" src="/logos/kyushu.png">',
              2 =>
                '<img class="rankings__logo" src="http://example.com/logo.png">',
              _ => match.group(0)!,
            });
    final table = WebsiteRankingsTable.parse(modified, pageUrl: home)!;
    expect(table.rows, hasLength(8));
    expect(table.teamLogoUrls[0], isNull);
    expect(table.teamLogoUrls[1], home.resolve('/logos/kyushu.png'));
    expect(table.teamLogoUrls[2], isNull);
    expect(table.teamLogoUrls[3], isNotNull);
  });

  testWidgets('全チームの実数値・ロゴを表示し、詳細成績・更新・戻るが動作する', (tester) async {
    // Distinct, nonzero values expose swapped win/draw/loss or detail columns.
    final parsed = WebsiteRankingsTable.parse(full)!;
    final table = WebsiteRankingsTable(
        title: parsed.title,
        headers: parsed.headers,
        rows: [
          for (final row in parsed.rows)
            [for (var i = 0; i < row.length; i++) i < 2 ? row[i] : '${100 + i}']
        ],
        teamLogoUrls: parsed.teamLogoUrls);
    var calls = 0;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) {
      return TextButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => WebsiteRankingsScreen(
                  url: home.resolve('/rankings/'),
                  loadTable: (_) async {
                    calls++;
                    return table;
                  }))),
          child: const Text('開く'));
    })));
    await tester.tap(find.text('開く'));
    await tester.pumpAndSettle();
    final first = find.byKey(const ValueKey('website-ranking-team-0'));
    expect(
        find.descendant(of: first, matching: find.text('102')), findsOneWidget);
    expect(
        find.descendant(of: first, matching: find.text('103')), findsOneWidget);
    expect(
        find.descendant(of: first, matching: find.text('104')), findsOneWidget);
    expect(
        find.descendant(of: first, matching: find.text('105')), findsOneWidget);
    expect(
        find.descendant(of: first, matching: find.text('106')), findsOneWidget);
    expect(find.descendant(of: first, matching: find.byType(Image)),
        findsOneWidget);
    expect(find.byIcon(Icons.shield_outlined), findsNWidgets(8));
    expect(
        find.byKey(const ValueKey('website-ranking-team-7')), findsOneWidget);
    await tester.tap(find.text('詳細成績'));
    await tester.pumpAndSettle();
    for (var i = 2; i < 15; i++) {
      expect(find.descendant(of: first, matching: find.text('${100 + i}')),
          findsOneWidget);
    }
    await tester.tap(find.byTooltip('更新'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('開く'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('順位画面は幅320/375/430・文字1/2倍でも基本・詳細とも欠けずに表示する', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final table = WebsiteRankingsTable.parse(full)!;
    for (final scale in [1.0, 2.0]) {
      for (final width in [320.0, 375.0, 430.0]) {
        tester.view.physicalSize = Size(width, 812);
        await tester.pumpWidget(MaterialApp(
            key: ValueKey('$width-$scale'),
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!),
            home: WebsiteRankingsScreen(
                url: home.resolve('/rankings/'),
                loadTable: (_) async => table)));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('詳細成績'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(find.text('レッドハリケーンズ大阪'), 500,
            scrollable: find.byType(Scrollable).first);
        expect(find.text('レッドハリケーンズ大阪').hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    }
  });
}

// Exercise GetConnect's actual request/response decoder without network access.
class _RecordingHttpClient implements HttpClient {
  _RecordingHttpClient(this.html, {this.redirectRankings = false});
  final String html;
  final bool redirectRankings;
  final visited = <Uri>[];
  final requests = <_RecordingHttpRequest>[];
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    visited.add(url);
    final request = _RecordingHttpRequest(this, url);
    requests.add(request);
    return request;
  }

  @override
  void close({bool force = false}) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _RecordingHttpRequest implements HttpClientRequest {
  _RecordingHttpRequest(this.client, this.url);
  final _RecordingHttpClient client;
  final Uri url;
  @override
  bool followRedirects = true;
  @override
  final HttpHeaders headers = _TestHeaders();
  @override
  Future<void> addStream(Stream<List<int>> stream) async {
    await stream.drain<void>();
  }

  @override
  Future<HttpClientResponse> close() async {
    final redirect = client.redirectRankings && url.path == '/rankings/';
    if (redirect && followRedirects) {
      client.visited.add(Uri.parse('https://unapproved.example/rankings/'));
    }
    return _TestHttpResponse(
        client.html, redirect && !followRedirects ? 302 : 200);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _TestHttpResponse extends Stream<List<int>>
    implements HttpClientResponse {
  _TestHttpResponse(String text, this.statusCode)
      : _bytes = Stream.value(utf8.encode(text));
  final Stream<List<int>> _bytes;
  @override
  final int statusCode;
  @override
  String get reasonPhrase => statusCode == 200 ? 'OK' : 'Found';
  @override
  final HttpHeaders headers = _TestHeaders();
  @override
  StreamSubscription<List<int>> listen(void Function(List<int>)? onData,
          {Function? onError, void Function()? onDone, bool? cancelOnError}) =>
      _bytes.listen(onData,
          onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _TestHeaders implements HttpHeaders {
  @override
  ContentType get contentType => ContentType.html;
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  void forEach(void Function(String, List<String>) action) {
    action('content-type', ['text/html; charset=utf-8']);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
