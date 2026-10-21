import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/app/data/models/home/website_banner.dart';
import 'package:koto_blue_sharks/app/data/models/home/website_standings.dart';
import 'package:koto_blue_sharks/app/providers/home/website_video_provider.dart';
import 'package:koto_blue_sharks/app/views/views/other/views/website_banners_section.dart';
import 'package:koto_blue_sharks/app/views/views/other/views/website_standings_section.dart';
import 'package:koto_blue_sharks/presentation/home/controllers/home.controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final home = Uri.parse('https://blue-sharks.donati.jp/');
  final source = File('test/home/fixtures/renewal_top_banners_20261019.html')
      .readAsStringSync();
  final rank = WebsiteStandings.parseHomepage(source, home)!;
  String card(
          {String href = '/tickets/',
          String image = '/wp-content/banner.jpg',
          String width = '1920',
          String height = '750'}) =>
      '<div class="swiper-slide"><a class="mainV__link" href="$href"><picture><source srcset="/portrait.jpg"><img class="mainV__image" src="$image" width="$width" height="$height" alt=""></picture></a></div>';
  String top(String cards) => '<div class="mainV mainV--top">$cards</div>';
  Widget app(Widget child, {double scale = 1, Key? key}) => MaterialApp(
      key: key,
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!),
      home: Scaffold(body: SingleChildScrollView(child: child)));
  setUp(() {
    debugNetworkImageHttpClientProvider = null;
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });
  tearDown(() {
    debugNetworkImageHttpClientProvider = null;
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  test('正規TOP3画像・リンクのSSR順と横長PC素材を保持し、縦長SPを切り抜かない', () {
    final data = WebsiteBanner.parseHomepage(source, home);
    expect(data, hasLength(3));
    expect(data.map((b) => b.url.path), [
      '/tickets/',
      '/fanclub/',
      '/schedule-and-result/season/season_2026_2027/'
    ]);
    expect(data.map((b) => b.imageUrl.pathSegments.last),
        ['mainvisual-2_pc.webp', 'mainvisual-5_pc.jpg', 'IMG_2062.jpg']);
    expect(
        data.every((b) =>
            b.width == 1920 && b.height == 750 && b.aspectRatio == 1920 / 750),
        isTrue);
    expect(data.every((b) => b.alt.isEmpty), isTrue);
    expect(() => data.clear(), throwsUnsupportedError);
  });
  test('TOP slider以外の公式アプリ広告等を混入させず相対URLを解決し重複を除く', () {
    final data = WebsiteBanner.parseHomepage(
        '${card()}${top('${card()}${card()}')}<section class="top-app-banner">${card(href: '/official-app/')}</section>',
        home);
    expect(data, hasLength(1));
    expect(data.single.url, home.resolve('/tickets/'));
    expect(data.single.imageUrl, home.resolve('/wp-content/banner.jpg'));
  });
  test('非HTTPS・外部origin・認証付き・異ポートの素材とリンクは採用しない', () {
    for (final value in [
      'javascript:alert(1)',
      'http://blue-sharks.donati.jp/tickets/',
      'https://evil.example/tickets/',
      'https://user:pass@blue-sharks.donati.jp/tickets/',
      'https://blue-sharks.donati.jp:444/tickets/'
    ]) {
      expect(WebsiteBanner.parseHomepage(top(card(href: value)), home), isEmpty,
          reason: value);
      expect(
          WebsiteBanner.parseHomepage(top(card(image: value)), home), isEmpty,
          reason: value);
    }
  });
  test('欠損画像・リンク・寸法・空応答を推測補完せず、alt空は原文どおり許容する', () {
    for (final item in [
      card(image: ''),
      card(href: ''),
      card(width: ''),
      card(height: '0'),
      card(width: '-1'),
      card(height: 'unknown')
    ]) {
      expect(WebsiteBanner.parseHomepage(top(item), home), isEmpty);
    }
    expect(
        WebsiteBanner.parseHomepage('<html>maintenance</html>', home), isEmpty);
    expect(WebsiteBanner.parseHomepage(top(card()), home).single.alt, '');
  });
  test('RANK正規素材585x200と実href・altを順位データとともに保持する', () {
    expect(
        rank.bannerImageUrl,
        home.resolve(
            '/wp-content/themes/blue-sharks-2026/assets/images/common/bnr-rank.webp'));
    expect(rank.bannerAspectRatio, 585 / 200);
    expect(rank.bannerLabel, 'RANK 公式戦の順位表');
    expect(rank.rankingsUrl, home.resolve('/rankings/'));
    expect(rank.headers, ['順位', '勝点', '勝', '負', '分']);
  });
  test('RANK画像が欠損・不正でも順位と元の遷移を失わずテキストへ戻せる', () {
    final actual = rank.bannerImageUrl.toString();
    for (final value in [
      '',
      'http://blue-sharks.donati.jp/rank.webp',
      'https://evil.example/rank.webp',
      'https://user:pass@blue-sharks.donati.jp/rank.webp'
    ]) {
      final data = WebsiteStandings.parseHomepage(
          source.replaceAll('src="$actual"', 'src="$value"'), home)!;
      expect(data.bannerImageUrl, isNull);
      expect(data.rankingsUrl, rank.rankingsUrl);
      expect(data.values, rank.values);
    }
    final missing =
        source.replaceAll('class="top-game__image"', 'class="missing-image"');
    expect(
        WebsiteStandings.parseHomepage(missing, home)!.bannerImageUrl, isNull);
  });
  test('TOPバナーも既存欄と同じ1回のTOP応答から更新する', () async {
    var calls = 0;
    final c = HomeController(
        websiteVideoProvider: WebsiteVideoProvider(loadHomepage: (_) async {
      calls++;
      return source;
    }));
    await c.fetchWebsiteContent();
    await c.fetchWebsiteContent();
    expect(calls, 1);
    expect(c.websiteBanners, hasLength(3));
    expect(c.websiteStandings.value!.bannerImageUrl, rank.bannerImageUrl);
    expect(c.websitePlayers.value, isNotNull);
    await c.fetchWebsiteContent(force: true);
    expect(calls, 2);
    c.onDelete();
  });
  test('TOP取得失敗ではバナーを保持し、成功0件では消す', () async {
    var n = 0;
    final c = HomeController(
        websiteVideoProvider: WebsiteVideoProvider(loadHomepage: (_) async {
      if (++n == 2) throw const WebsiteVideoRequestException();
      return n == 3 ? '<html/>' : source;
    }));
    await c.fetchWebsiteContent();
    final first = c.websiteBanners.first.imageUrl;
    await c.fetchWebsiteContent(force: true);
    expect(c.websiteBanners.first.imageUrl, first);
    await c.fetchWebsiteContent(force: true);
    expect(c.websiteBanners, isEmpty);
    c.onDelete();
  });
  test('破棄後の遅延TOP応答でバナーを反映しない', () async {
    final pending = Completer<String>();
    final c = HomeController(
        websiteVideoProvider:
            WebsiteVideoProvider(loadHomepage: (_) => pending.future));
    final task = c.fetchWebsiteContent();
    c.onDelete();
    pending.complete(source);
    await task;
    expect(c.websiteBanners, isEmpty);
  });
  test('Debug画面更新は旧認証banners・旧試合APIを呼ばず公開TOPを使用する', () async {
    final schedule = File('test/home/fixtures/renewal_schedule_20261019.html')
        .readAsStringSync();
    final requests = <Uri>[];
    final c =
        _BannerHomeController(WebsiteVideoProvider(loadHomepage: (uri) async {
      requests.add(uri);
      return uri.path == '/' ? source : schedule;
    }));
    c.screenInit();
    await Future<void>.delayed(Duration.zero);
    expect(c.legacyBannerCalls, 0);
    expect(c.legacyMatchCalls, 0);
    expect(c.topicCalls, 1);
    expect(c.websiteBanners, hasLength(3));
    expect(requests, [home, home.resolve('/schedule-and-result/')]);
    c.onDelete();
  });
  testWidgets('画像decoder成功時に正規URLを要求し、TOP/RANKを切り抜かず表示する', (tester) async {
    final transport = _ImageClient();
    debugNetworkImageHttpClientProvider = () => transport;
    try {
      final data = WebsiteBanner.parseHomepage(source, home);
      await tester.pumpWidget(app(const SizedBox()));
      final context = tester.element(find.byType(Scaffold));
      final errors = <Object>[];
      await tester.runAsync(() async {
        for (final uri in [
          ...data.map((b) => b.imageUrl),
          rank.bannerImageUrl!
        ]) {
          await precacheImage(NetworkImage(uri.toString()), context,
              onError: (error, _) => errors.add(error));
        }
      });
      expect(errors, isEmpty);
      await tester.pumpWidget(app(Column(children: [
        WebsiteBannersSection(banners: data),
        WebsiteStandingsSection(standings: rank)
      ])));
      await tester.pumpAndSettle();
      expect(transport.visited, contains(data.first.imageUrl));
      expect(transport.visited, contains(rank.bannerImageUrl));
      expect(
          tester
              .widgetList<Image>(find.byType(Image))
              .every((i) => i.fit == BoxFit.contain),
          isTrue);
      expect(
          tester
              .widgetList<RawImage>(find.byType(RawImage))
              .where((i) => i.image != null),
          isNotEmpty);
      expect(find.text('バナー画像を読み込めませんでした。'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(app(const SizedBox()));
    } finally {
      debugNetworkImageHttpClientProvider = null;
    }
  });
  testWidgets('320/375/430幅・文字1/2倍で画像失敗fallbackとRANKが溢れず横送りできる',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final data = WebsiteBanner.parseHomepage(source, home);
    for (final scale in [1.0, 2.0]) {
      for (final width in [320.0, 375.0, 430.0]) {
        tester.view.physicalSize = Size(width, 812);
        await tester.pumpWidget(app(
            Column(children: [
              WebsiteBannersSection(banners: data),
              WebsiteStandingsSection(standings: rank)
            ]),
            scale: scale,
            key: ValueKey('$width-$scale')));
        await tester.pumpAndSettle();
        expect(find.text('バナー画像を読み込めませんでした。'), findsWidgets);
        expect(find.text(rank.bannerLabel), findsOneWidget);
        expect(tester.takeException(), isNull, reason: '$width/$scale');
        await tester.drag(find.byKey(const ValueKey('website-banners-pager')),
            Offset(-width, 0));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    }
  });
  testWidgets('3枚目表示後の短縮・空・再取得でも先頭に戻りcontrollerを安全に破棄する', (tester) async {
    final data = WebsiteBanner.parseHomepage(source, home);
    Widget section(List<WebsiteBanner> list) =>
        app(WebsiteBannersSection(banners: list));
    await tester.pumpWidget(section(data));
    await tester.pumpAndSettle();
    await tester.drag(find.byKey(const ValueKey('website-banners-pager')),
        const Offset(-900, 0));
    await tester.pumpAndSettle();
    await tester.pumpWidget(section([data.first]));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('website-banner-0')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(section([]));
    await tester.pumpAndSettle();
    expect(find.byType(PageView), findsNothing);
    await tester.pumpWidget(section(data));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('website-banner-0')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(app(const SizedBox()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('TOP各画像のタップは掲載順の実リンクを外部で開く', (tester) async {
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
    final data = WebsiteBanner.parseHomepage(source, home);
    await tester.pumpWidget(app(WebsiteBannersSection(banners: data)));
    await tester.pumpAndSettle();
    for (var i = 0; i < data.length; i++) {
      await tester.tap(find.byKey(ValueKey('website-banner-$i')));
      await tester.pumpAndSettle();
      expect((calls.last.arguments as Map)['url'], data[i].url.toString());
      expect((calls.last.arguments as Map)['useSafariVC'], isFalse);
      expect((calls.last.arguments as Map)['useWebView'], isFalse);
      if (i < data.length - 1) {
        await tester.drag(find.byKey(const ValueKey('website-banners-pager')),
            const Offset(-700, 0));
        await tester.pumpAndSettle();
      }
    }
    expect(calls, hasLength(3));
    expect(tester.takeException(), isNull);
  });
  testWidgets('TOP外部起動失敗は表示を保持し再試行できる', (tester) async {
    const channel = MethodChannel('plugins.flutter.io/url_launcher');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => false);
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    await tester.pumpWidget(app(WebsiteBannersSection(
        banners: WebsiteBanner.parseHomepage(source, home))));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('website-banner-0')));
    await tester.pump();
    expect(find.text('TOPバナーのページを開けませんでした。'), findsOneWidget);
    expect(find.byType(PageView), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 5));
  });
  testWidgets('RANK画像失敗時も元の順位表画面へ実hrefで遷移し、再試行経路を保持する', (tester) async {
    final full = File('test/home/fixtures/renewal_rankings_20261016.html')
        .readAsStringSync();
    Uri? requested;
    await tester.pumpWidget(app(WebsiteStandingsSection(
        standings: rank,
        loadRankings: (uri) async {
          requested = uri;
          return WebsiteRankingsTable.parse(full)!;
        })));
    await tester.pumpAndSettle();
    expect(find.text(rank.bannerLabel), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('website-rank-link')));
    await tester.pumpAndSettle();
    expect(requested, rank.rankingsUrl);
    expect(
        find.byKey(const ValueKey('website-ranking-team-0')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _BannerHomeController extends HomeController {
  _BannerHomeController(WebsiteVideoProvider provider)
      : super(websiteVideoProvider: provider);
  int legacyBannerCalls = 0, legacyMatchCalls = 0, topicCalls = 0;
  @override
  void getBanner() {
    legacyBannerCalls++;
  }

  @override
  void fetchMatchResult() {
    legacyMatchCalls++;
  }

  @override
  void getTopics() {
    topicCalls++;
  }
}

// A valid one-pixel PNG only exercises Flutter's HTTP decoder; no generated user asset.
class _ImageClient implements HttpClient {
  final visited = <Uri>[];
  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    visited.add(url);
    return _ImageRequest();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _ImageRequest implements HttpClientRequest {
  @override
  final HttpHeaders headers = _ImageHeaders();
  @override
  Future<HttpClientResponse> close() async => _ImageResponse();
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _ImageResponse extends Stream<List<int>> implements HttpClientResponse {
  final bytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH5gMQFwcdLl4wmwAAAAtJREFUCNdjYAACAAAFAAHiJgWbAAAAAElFTkSuQmCC');
  @override
  int get statusCode => 200;
  @override
  int get contentLength => bytes.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  StreamSubscription<List<int>> listen(void Function(List<int>)? onData,
          {Function? onError, void Function()? onDone, bool? cancelOnError}) =>
      Stream.value(bytes).listen(onData,
          onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _ImageHeaders implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
