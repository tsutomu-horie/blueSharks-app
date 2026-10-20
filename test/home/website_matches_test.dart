import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/app/data/models/home/website_match.dart';
import 'package:koto_blue_sharks/app/providers/home/website_video_provider.dart';
import 'package:koto_blue_sharks/app/views/views/other/views/website_matches_section.dart';
import 'package:koto_blue_sharks/presentation/home/controllers/home.controller.dart';

void main() {
  final home = Uri.parse('https://blue-sharks.donati.jp/');
  final url = home.resolve('/schedule-and-result/');
  final top = File('test/home/fixtures/renewal_top_game_20261019.html')
      .readAsStringSync();
  final source = File('test/home/fixtures/renewal_schedule_20261019.html')
      .readAsStringSync();
  final now = DateTime.utc(2026, 10, 19);
  final empty =
      '<main><section class="season"><select name="season"><option selected>2026 – 2027 シーズン</option></select></section></main>';
  Widget app(WebsiteSchedule? data, {double scale = 1, Key? key}) =>
      MaterialApp(
          key: key,
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!),
          home: Scaffold(
              body: SingleChildScrollView(
                  child: WebsiteMatchesSection(schedule: data, now: now))));

  test('実TOPのVIEW ALLからだけ同一originの試合日程URLを取得する', () {
    expect(WebsiteSchedule.parseHomepageUrl(top, home), url);
    for (final value in [
      'https://evil.example/schedule-and-result/',
      'http://blue-sharks.donati.jp/schedule-and-result/',
      'https://user:pass@blue-sharks.donati.jp/schedule-and-result/',
      'https://blue-sharks.donati.jp:444/schedule-and-result/',
      '/wp-admin/',
      '/schedule-and-result/?redirect=evil',
      '/schedule-and-result/#x',
      'javascript:alert(1)'
    ]) {
      final changed = top.replaceFirst(
          'class="button u-ff--dazzle-unicase top-game__button" href="$url"',
          'class="button top-game__button" href="$value"');
      expect(changed, isNot(top));
      expect(WebsiteSchedule.parseHomepageUrl(changed, home), isNull,
          reason: value);
    }
    expect(WebsiteSchedule.parseHomepageUrl('<html/>', home), isNull);
  });
  test('実日程26件と選択season、将来22件の原文・未定・未記載HOSTを保持する', () {
    final data = WebsiteSchedule.parse(source, url)!;
    expect(data.season, '2026 – 2027 シーズン');
    expect(data.matches, hasLength(26));
    final next = data.upcoming(now);
    expect(next, hasLength(22));
    expect(next.first.date, DateTime.utc(2026, 10, 24));
    expect(next.first.dateLabel, '2026/10/24');
    expect(next.first.day, 'sat');
    expect(next.first.league, 'オープン戦');
    expect(next.first.timeLabel, '12:00 K.O');
    expect(next.first.hostLabel, isNull);
    expect(next.first.opponentName, '東芝ブレイブルーパス東京');
    expect(next.first.opponentLogo,
        home.resolve('/wp-content/uploads/2026/08/bl.png'));
    expect(next.first.venue, '東芝府中グラウンド');
    expect(next.first.venueUrl.toString(),
        'https://maps.app.goo.gl/jUqpeF98ycnHdw3h8');
    expect(next[3].timeLabel, 'K.O 未定');
    expect(
        next.firstWhere((m) => m.date == DateTime.utc(2026, 12, 12)).hostLabel,
        'HOST GAME');
    expect(
        next.firstWhere((m) => m.date == DateTime.utc(2026, 12, 19)).hostLabel,
        'VISITOR GAME');
    expect(data.matches[1].venue, '非公開');
    expect(data.matches[1].venueUrl, isNull);
    expect(() => data.matches.clear(), throwsUnsupportedError);
  });
  test('4アクションの掲載順と実href・無効spanを保持し共通リンクを補わない', () {
    final next = WebsiteSchedule.parse(source, url)!.upcoming(now);
    expect(next.first.actions.map((a) => a.label),
        ['チケット情報', 'ホストイベント情報', 'マッチレポート', '試合情報']);
    expect(next.first.actions.take(3).every((a) => a.url == null), isTrue);
    expect(next.first.actions.last.url,
        home.resolve('/schedule-and-result/2026/08/25265/'));
    final december =
        next.firstWhere((m) => m.date == DateTime.utc(2026, 12, 12));
    expect(december.actions.first.url, home.resolve('/tickets/'));
  });
  test('日本時間の境界で日付を選び、日付だけからK.Oや試合結果は推測しない', () {
    final data = WebsiteSchedule.parse(source, url)!;
    expect(data.upcoming(DateTime.utc(2026, 10, 24, 14, 59)).first.date,
        DateTime.utc(2026, 10, 24));
    expect(data.upcoming(DateTime.utc(2026, 10, 24, 15)).first.date,
        DateTime.utc(2026, 10, 31));
    expect(data.upcoming(DateTime.utc(2028)), isEmpty);
    final changed = WebsiteSchedule.parse(
        source.replaceFirst(
            '<time datetime="2026-09-12">', '<time datetime="2026-10-23">'),
        url)!;
    expect(
        changed.upcoming(now).any((m) => m.date == DateTime.utc(2026, 10, 23)),
        isFalse);
  });
  test('異常日付・欠損チーム・欠損アクションでは部分表を成功扱いしない', () {
    for (final changed in [
      source.replaceFirst('datetime="2026-09-12"', 'datetime="2026-02-30"'),
      source.replaceFirst('清水建設江東<br>ブルーシャークス', '不明なチーム'),
      source.replaceFirst(
          'class="match-card__action"', 'class="missing-action"'),
      source.replaceFirst(
          'src="https://blue-sharks.donati.jp/wp-content/uploads/2026/08/wn.png"',
          'src=""')
    ]) {
      expect(changed, isNot(source));
      expect(WebsiteSchedule.parse(changed, url), isNull);
    }
    expect(
        WebsiteSchedule.parse(
            source.replaceAll("selected='selected'", ''), url),
        isNull);
    expect(WebsiteSchedule.parse('<html>maintenance</html>', url), isNull);
  });
  test('リンクの非HTTPS・外部origin・認証付き・明示無効は起動不可として保持する', () {
    const actual =
        'href="https://blue-sharks.donati.jp/schedule-and-result/2026/08/25265/"';
    for (final value in [
      'javascript:alert(1)',
      'https://evil.example/page',
      'http://blue-sharks.donati.jp/page',
      'https://user:pass@blue-sharks.donati.jp/page'
    ]) {
      final data = WebsiteSchedule.parse(
          source.replaceAll(actual, 'href="$value"'), url)!;
      expect(data.upcoming(now).first.actions.last.url, isNull);
    }
    for (final marker in ['aria-disabled="true"', 'disabled']) {
      final data = WebsiteSchedule.parse(
          source.replaceAll(actual, '$actual $marker'), url)!;
      expect(data.upcoming(now).first.actions.last.url, isNull);
    }
    final disabled = source.replaceAll(
        'class="button button--md" href="https://blue-sharks.donati.jp/schedule-and-result/2026/08/25265/"',
        'class="button button--md button--disabled" href="https://blue-sharks.donati.jp/schedule-and-result/2026/08/25265/"');
    expect(
        WebsiteSchedule.parse(disabled, url)!
            .upcoming(now)
            .first
            .actions
            .last
            .url,
        isNull);
  });
  test('妥当な日程の成功0件は空として扱い、別セクションは拾わない', () {
    expect(WebsiteSchedule.parse(empty, url)!.matches, isEmpty);
    expect(
        WebsiteSchedule.parse(
            source.replaceFirst(
                'class="lower-section season"', 'class="other"'),
            url),
        isNull);
  });
  test('取得URLを事前検証し、日程の失敗と不正200本文を拒否する', () async {
    final requested = <Uri>[];
    final provider = WebsiteVideoProvider(loadHomepage: (u) async {
      requested.add(u);
      return '<html>maintenance</html>';
    });
    await expectLater(
        provider.fetchSchedule(
            Uri.parse('https://evil.example/schedule-and-result/')),
        throwsA(isA<WebsiteVideoRequestException>()));
    expect(requested, isEmpty);
    await expectLater(provider.fetchSchedule(url),
        throwsA(isA<WebsiteVideoRequestException>()));
    expect(requested, [url]);
    provider.httpClient.close();
  });
  test('実GetConnect decoderとmock transportで成功取得し日程だけredirectを無効にする', () async {
    final transport = _ScheduleHttpClient({home: top, url: source});
    await HttpOverrides.runZoned(() async {
      final provider = WebsiteVideoProvider();
      final content = await provider.fetchContent();
      expect(content.scheduleUrl, url);
      expect((await provider.fetchSchedule(url)).matches, hasLength(26));
      expect(transport.requests.map((r) => r.followRedirects), [true, false]);
      expect(transport.visited, [home, url]);
      provider.httpClient.close();
    }, createHttpClient: (_) => transport);
  });
  test('許可日程URLの302を追跡せず拒否する', () async {
    final transport = _ScheduleHttpClient({url: source}, redirect: true);
    await HttpOverrides.runZoned(() async {
      final provider = WebsiteVideoProvider();
      await expectLater(provider.fetchSchedule(url),
          throwsA(isA<WebsiteVideoRequestException>()));
      expect(transport.visited, [url]);
      expect(transport.requests.single.followRedirects, isFalse);
      provider.httpClient.close();
    }, createHttpClient: (_) => transport);
  });
  test('既存4unitは1回のTOP応答を共有し、日程だけ追加GETする', () async {
    final requests = <Uri>[];
    final players = File('test/home/fixtures/renewal_top_players_20261016.html')
        .readAsStringSync();
    final goods = File('test/home/fixtures/renewal_goods_20261016.html')
        .readAsStringSync();
    final c = HomeController(
        websiteClock: () => now,
        websiteVideoProvider: WebsiteVideoProvider(loadHomepage: (u) async {
          requests.add(u);
          return u == url
              ? source
              : '$top$players$goods<section class="top-movie"><a class="video-card" href="https://youtu.be/kVpQca35ECY"><img src="https://i.ytimg.com/vi/kVpQca35ECY/hqdefault.jpg" alt="PV"></a></section>';
        }));
    await c.fetchWebsiteNextMatches();
    await c.fetchWebsiteNextMatches();
    expect(requests, [home, url]);
    expect(c.websiteVideos, hasLength(1));
    expect(c.websiteGoods, hasLength(14));
    expect(c.websiteStandings.value, isNotNull);
    expect(c.websitePlayers.value!.players, hasLength(10));
    expect(c.websiteSchedule.value!.upcoming(c.websiteClock()), hasLength(22));
    await c.fetchWebsiteNextMatches(force: true);
    expect(requests, [home, url, home, url]);
    c.onDelete();
  });
  test('日程だけ失敗しても前回日程を保持しTOP成功を巻き戻さず、成功空では消す', () async {
    var phase = 0;
    final players = File('test/home/fixtures/renewal_top_players_20261016.html')
        .readAsStringSync();
    final requests = <Uri>[];
    final c = HomeController(
        websiteVideoProvider: WebsiteVideoProvider(loadHomepage: (u) async {
      requests.add(u);
      if (u == home) {
        return phase == 3
            ? '<html/>'
            : '$top${phase == 1 ? players.replaceAll('志村 太基', '更新された氏名') : players}';
      }
      if (phase == 1) {
        throw const WebsiteVideoRequestException();
      }
      return phase == 2 ? empty : source;
    }));
    await c.fetchWebsiteNextMatches();
    final first = c.websiteSchedule.value;
    phase = 1;
    await c.fetchWebsiteNextMatches(force: true);
    expect(c.websiteSchedule.value, same(first));
    expect(c.websitePlayers.value!.players.first.name, '更新された氏名');
    phase = 2;
    await c.fetchWebsiteNextMatches(force: true);
    expect(c.websiteSchedule.value!.matches, isEmpty);
    phase = 3;
    await c.fetchWebsiteNextMatches(force: true);
    expect(c.websiteSchedule.value, isNull);
    expect(requests.where((u) => u == url), hasLength(3));
    c.onDelete();
  });
  test('初回の日程失敗は捏造せず空、TOPの成功順位は表示可能に保つ', () async {
    final c = HomeController(
        websiteVideoProvider: WebsiteVideoProvider(loadHomepage: (u) async {
      if (u == url) throw const WebsiteVideoRequestException();
      return top;
    }));
    await c.fetchWebsiteNextMatches();
    expect(c.websiteSchedule.value, isNull);
    expect(c.websiteStandings.value, isNotNull);
    c.onDelete();
  });
  test('日程待ちの同時更新を一本にし、破棄後の遅延結果を反映しない', () async {
    final pending = Completer<String>();
    final requests = <Uri>[];
    final c = HomeController(
        websiteVideoProvider: WebsiteVideoProvider(loadHomepage: (u) {
      requests.add(u);
      return u == home ? Future.value(top) : pending.future;
    }));
    final first = c.fetchWebsiteNextMatches();
    await Future<void>.delayed(Duration.zero);
    expect(requests, [home, url]);
    await c.fetchWebsiteNextMatches(force: true);
    expect(requests, [home, url]);
    c.onDelete();
    pending.complete(source);
    await first;
    expect(c.websiteSchedule.value, isNull);
  });
  test('先行TOP取得と競合せず、完了後は同じTOP結果を日程取得に利用する', () async {
    final pending = Completer<String>();
    final requests = <Uri>[];
    final c = HomeController(
        websiteVideoProvider: WebsiteVideoProvider(loadHomepage: (u) {
      requests.add(u);
      return u == home ? pending.future : Future.value(source);
    }));
    final content = c.fetchWebsiteContent();
    await c.fetchWebsiteNextMatches();
    expect(requests, [home]);
    pending.complete(top);
    await content;
    await c.fetchWebsiteNextMatches();
    expect(requests, [home, url]);
    expect(c.websiteSchedule.value!.matches, hasLength(26));
    c.onDelete();
  });
  testWidgets('320/375/430幅で4試合が同時に収まり、5件目以降へ横送りできる', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final data = WebsiteSchedule.parse(source, url)!;
    for (final width in [320.0, 375.0, 430.0]) {
      tester.view.physicalSize = Size(width, 1400);
      await tester.pumpWidget(app(data, key: ValueKey(width)));
      await tester.pumpAndSettle();
      for (var index = 0; index < 4; index++) {
        final card =
            tester.getRect(find.byKey(ValueKey('website-match-card-$index')));
        expect(card.left, greaterThanOrEqualTo(0));
        expect(card.right, lessThanOrEqualTo(width));
      }
      final fifth = find.byKey(const ValueKey('website-match-card-4'));
      expect(tester.getRect(fifth).right, greaterThan(width));
      final list = find.byKey(const ValueKey('website-matches-list'));
      await tester.dragFrom(
          tester.getTopLeft(list) + Offset(width / 2, 12), Offset(-width, 0));
      await tester.pumpAndSettle();
      expect(tester.getRect(fifth).left, lessThan(width));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('320/375/430幅・文字1/2倍で長い原文と4ボタンが溢れず横送りできる', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final data = WebsiteSchedule.parse(
        source.replaceAll('東芝ブレイブルーパス東京', '長い公開対戦相手名称の表示領域と折り返しを確認するチーム'),
        url)!;
    for (final scale in [1.0, 2.0]) {
      for (final width in [320.0, 375.0, 430.0]) {
        tester.view.physicalSize = Size(width, 812);
        await tester.pumpWidget(
            app(data, scale: scale, key: ValueKey('$width-$scale')));
        await tester.pumpAndSettle();
        expect(find.text('2026 – 2027 シーズン'), findsOneWidget);
        expect(find.text('K.O 未定'), findsWidgets);
        expect(tester.takeException(), isNull, reason: '$width/$scale');
        final list = find.byKey(const ValueKey('website-matches-list'));
        await tester.dragFrom(
            tester.getTopLeft(list) + Offset(width / 2, 12), Offset(-width, 0));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    }
  });
  testWidgets('未取得は捏造表示せず、成功の将来0件はVIEW ALLと空状態を表示する', (tester) async {
    await tester.pumpWidget(app(null));
    await tester.pumpAndSettle();
    expect(find.text('VIEW ALL'), findsNothing);
    await tester.pumpWidget(app(WebsiteSchedule.parse(empty, url)));
    await tester.pumpAndSettle();
    expect(find.text('表示できる今後の試合はありません。'), findsOneWidget);
    expect(find.text('VIEW ALL'), findsOneWidget);
    expect(find.byKey(const ValueKey('website-matches-list')), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('無効ボタンは起動せず、試合情報・会場・VIEW ALLは対応実URLへ外部起動する', (tester) async {
    const channel = MethodChannel('plugins.flutter.io/url_launcher');
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return true;
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    final data = WebsiteSchedule.parse(source, url)!;
    await tester.pumpWidget(app(data));
    await tester.pumpAndSettle();
    final disabled = find.byKey(const ValueKey('website-match-action-0-0'));
    await tester.ensureVisible(disabled);
    expect(tester.widget<OutlinedButton>(disabled).onPressed, isNull);
    await tester.tap(disabled);
    await tester.pumpAndSettle();
    expect(calls, isEmpty);
    final info = find.byKey(const ValueKey('website-match-action-0-3'));
    await tester.ensureVisible(info);
    await tester.tap(info);
    await tester.pumpAndSettle();
    expect((calls.last.arguments as Map)['url'],
        data.upcoming(now).first.actions.last.url.toString());
    expect((calls.last.arguments as Map)['useSafariVC'], isFalse);
    expect((calls.last.arguments as Map)['useWebView'], isFalse);
    final venue = find.byKey(const ValueKey('website-match-venue-0'));
    await tester.ensureVisible(venue);
    await tester.tap(venue);
    await tester.pumpAndSettle();
    expect((calls.last.arguments as Map)['url'],
        data.upcoming(now).first.venueUrl.toString());
    final all = find.byKey(const ValueKey('website-matches-view-all'));
    await tester.ensureVisible(all);
    await tester.tap(all);
    await tester.pumpAndSettle();
    expect((calls.last.arguments as Map)['url'], url.toString());
    expect(calls, hasLength(3));
    expect(tester.takeException(), isNull);
  });
  testWidgets('外部起動例外はカードと無効状態を保ち失敗メッセージを表示する', (tester) async {
    const channel = MethodChannel('plugins.flutter.io/url_launcher');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async {
      throw PlatformException(code: 'unavailable');
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    await tester.pumpWidget(app(WebsiteSchedule.parse(source, url)));
    await tester.pumpAndSettle();
    final info = find.byKey(const ValueKey('website-match-action-0-3'));
    await tester.ensureVisible(info);
    await tester.tap(info);
    await tester.pump();
    expect(find.text('試合関連ページを開けませんでした。'), findsOneWidget);
    expect(find.byKey(const ValueKey('website-matches-list')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 5));
  });
}

// Real GetConnect request/decoder with a deterministic, network-free HTTP transport.
class _ScheduleHttpClient implements HttpClient {
  _ScheduleHttpClient(this.responses, {this.redirect = false});
  final Map<Uri, String> responses;
  final bool redirect;
  final visited = <Uri>[];
  final requests = <_ScheduleHttpRequest>[];
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    visited.add(url);
    final request = _ScheduleHttpRequest(this, url);
    requests.add(request);
    return request;
  }

  @override
  void close({bool force = false}) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _ScheduleHttpRequest implements HttpClientRequest {
  _ScheduleHttpRequest(this.client, this.url);
  final _ScheduleHttpClient client;
  final Uri url;
  @override
  bool followRedirects = true;
  @override
  final HttpHeaders headers = _ScheduleHeaders();
  @override
  Future<void> addStream(Stream<List<int>> stream) async {
    await stream.drain<void>();
  }

  @override
  Future<HttpClientResponse> close() async {
    if (client.redirect && followRedirects) {
      client.visited
          .add(Uri.parse('https://unapproved.example/schedule-and-result/'));
    }
    return _ScheduleHttpResponse(client.responses[url] ?? '',
        client.redirect && !followRedirects ? 302 : 200);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _ScheduleHttpResponse extends Stream<List<int>>
    implements HttpClientResponse {
  _ScheduleHttpResponse(String source, this.statusCode)
      : _bytes = Stream.value(utf8.encode(source));
  final Stream<List<int>> _bytes;
  @override
  final int statusCode;
  @override
  String get reasonPhrase => statusCode == 200 ? 'OK' : 'Found';
  @override
  final HttpHeaders headers = _ScheduleHeaders();
  @override
  StreamSubscription<List<int>> listen(void Function(List<int>)? onData,
          {Function? onError, void Function()? onDone, bool? cancelOnError}) =>
      _bytes.listen(onData,
          onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _ScheduleHeaders implements HttpHeaders {
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
