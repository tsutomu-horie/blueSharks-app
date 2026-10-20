import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/app/data/models/home/website_player.dart';
import 'package:koto_blue_sharks/app/providers/home/website_video_provider.dart';
import 'package:koto_blue_sharks/app/views/views/other/views/website_players_section.dart';
import 'package:koto_blue_sharks/presentation/home/controllers/home.controller.dart';

void main() {
  final home = Uri.parse('https://blue-sharks.donati.jp/');
  final fixture = File('test/home/fixtures/renewal_top_players_20261016.html')
      .readAsStringSync();
  String card(
          {String url = '/members/prop/2025/01/17265/',
          String image = '/uploads/player.webp',
          String name = '志村 &amp; 太基',
          String kana = 'シムラ ダイキ'}) =>
      '<a class="player-card" href="$url"><img class="player-card__image" src="$image"><p class="player-card__name">$name</p><p class="player-card__kana">$kana</p></a>';
  String section(String cards, {String all = '/members/'}) =>
      '<section class="top-players">$cards<a class="top-players__button" href="$all">VIEW ALL</a></section>';
  Widget app(WebsitePlayers? data, {double scale = 1, Key? key}) =>
      ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, __) => MaterialApp(
              key: key,
              builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!),
              home: Scaffold(
                  body: SingleChildScrollView(
                      child: WebsitePlayersSection(data: data)))));

  test('実TOP10名の掲載順・氏名・カナ・画像・詳細とVIEW ALLを保持する', () {
    final data = WebsitePlayers.parseHomepage(fixture, home)!;
    expect(data.players.map((p) => p.name), [
      '志村 太基',
      '菅原 崇聖',
      '吉川 豪人',
      '野村 三四郎',
      '齊藤 遼太',
      '李 優河',
      '大和 大祐',
      '奈良 真弥',
      '麻生 尚宏',
      '中森 樹生'
    ]);
    expect(
        data.players
            .map((p) => p.url.pathSegments.where((s) => s.isNotEmpty).last),
        [
          '17265',
          '17277',
          '17231',
          '17312',
          '17324',
          '17318',
          '17284',
          '18883',
          '22627',
          '21698'
        ]);
    expect(data.players.first.kana, 'シムラ ダイキ');
    expect(data.players.last.kana, 'ナカモリ ジュイ');
    expect(data.players.first.imageUrl.toString(),
        '${home}wp-content/uploads/2025/01/DSC02976-scaled.webp');
    expect(data.viewAllUrl, home.resolve('/members/'));
    expect(() => data.players.clear(), throwsUnsupportedError);
  });
  test('対象欄だけ読み相対URLと文字参照を解決し最初の同一選手を保持する', () {
    final data = WebsitePlayers.parseHomepage(
        '${card(url: '/members/prop/2025/01/999/')}${section('${card()}${card(url: '/members/prop/2025/01/17265/?ref=duplicate')}')}',
        home)!;
    expect(data.players, hasLength(1));
    expect(data.players.single.name, '志村 & 太基');
    expect(data.players.single.imageUrl, home.resolve('/uploads/player.webp'));
    expect(
        data.players.single.url, home.resolve('/members/prop/2025/01/17265/'));
  });
  test('外部・認証付き・非HTTPS・異パスの遷移先や不正画像を採用しない', () {
    for (final url in [
      'javascript:alert(1)',
      'http://blue-sharks.donati.jp/members/prop/2025/01/17265/',
      'https://evil.example/members/prop/2025/01/17265/',
      'https://user:pass@blue-sharks.donati.jp/members/prop/2025/01/17265/',
      'https://blue-sharks.donati.jp:444/members/prop/2025/01/17265/',
      '/wp-admin/',
      '/members/',
      '/members/prop/no-id'
    ]) {
      expect(
          WebsitePlayers.parseHomepage(section(card(url: url)), home), isNull,
          reason: url);
    }
    for (final image in [
      '',
      'data:image/png,x',
      'http://example.com/a.png',
      'https://user:pass@example.com/a.png'
    ]) {
      expect(WebsitePlayers.parseHomepage(section(card(image: image)), home),
          isNull,
          reason: image);
    }
    for (final url in [
      'https://evil.example/members/',
      '/members/prop/',
      'javascript:alert(1)'
    ]) {
      expect(
          WebsitePlayers.parseHomepage(section(card(), all: url), home)!
              .viewAllUrl,
          isNull);
    }
  });
  test('氏名・カナ・画像の欠損を推測補完せず、成功空応答はnullになる', () {
    expect(WebsitePlayers.parseHomepage(section(card(name: '')), home), isNull);
    expect(WebsitePlayers.parseHomepage(section(card(kana: '')), home), isNull);
    expect(
        WebsitePlayers.parseHomepage('<html>maintenance</html>', home), isNull);
    expect(WebsitePlayers.parseHomepage('<section class="top-players"/>', home),
        isNull);
    final noButton = WebsitePlayers.parseHomepage(
        '<section class="top-players">${card()}</section>', home)!;
    expect(noButton.viewAllUrl, isNull);
  });
  test('動画・GOODS・順位・選手を1回の応答から更新し通常再描画では再取得しない', () async {
    var calls = 0;
    final goods = File('test/home/fixtures/renewal_goods_20261016.html')
        .readAsStringSync();
    final standings =
        File('test/home/fixtures/renewal_standings_top_20261016.html')
            .readAsStringSync();
    final c = HomeController(
        websiteVideoProvider: WebsiteVideoProvider(loadHomepage: (_) async {
      calls++;
      return '$fixture$goods$standings<section class="top-movie"><a class="video-card" href="https://youtu.be/kVpQca35ECY"><img src="https://i.ytimg.com/vi/kVpQca35ECY/hqdefault.jpg" alt="PV"></a></section>';
    }));
    await c.fetchWebsiteContent();
    await c.fetchWebsiteContent();
    expect(calls, 1);
    expect(c.websitePlayers.value!.players, hasLength(10));
    expect(c.websiteVideos, hasLength(1));
    expect(c.websiteGoods, hasLength(14));
    expect(c.websiteStandings.value, isNotNull);
    await c.fetchWebsiteContent(force: true);
    expect(calls, 2);
    c.onClose();
  });
  test('再取得失敗は前回選手を保持し成功0件では消す', () async {
    var n = 0;
    final c = HomeController(
        websiteVideoProvider: WebsiteVideoProvider(loadHomepage: (_) async {
      if (++n == 2) throw const WebsiteVideoRequestException();
      return n == 3 ? '<html/>' : fixture;
    }));
    await c.fetchWebsiteContent();
    final original = c.websitePlayers.value;
    await c.fetchWebsiteContent(force: true);
    expect(c.websitePlayers.value, same(original));
    await c.fetchWebsiteContent(force: true);
    expect(c.websitePlayers.value, isNull);
    c.onClose();
  });
  test('同時更新は一本にし破棄後の遅延応答で選手を更新しない', () async {
    var calls = 0;
    final pending = Completer<String>();
    final c = HomeController(
        websiteVideoProvider: WebsiteVideoProvider(loadHomepage: (_) {
      calls++;
      return pending.future;
    }));
    final first = c.fetchWebsiteContent();
    await c.fetchWebsiteContent(force: true);
    expect(calls, 1);
    c.onDelete();
    pending.complete(fixture);
    await first;
    expect(c.websitePlayers.value, isNull);
  });
  testWidgets('320/375/430幅・文字1/2倍で横送りでき、欠損画像も表示を保つ', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final data = WebsitePlayers.parseHomepage(fixture, home)!;
    final long = WebsitePlayer(
        name: '非常に長い公開氏名でも表示範囲を保つための確認',
        kana: 'ヒジョウニナガイコウカイカナノヒョウジカクニン',
        imageUrl: data.players.first.imageUrl,
        url: data.players.first.url);
    final content = WebsitePlayers(
        players: [long, ...data.players.skip(1)], viewAllUrl: data.viewAllUrl);
    for (final scale in [1.0, 2.0]) {
      for (final width in [320.0, 375.0, 430.0]) {
        tester.view.physicalSize = Size(width, 812);
        await tester.pumpWidget(
            app(content, scale: scale, key: ValueKey('$scale-$width')));
        await tester.pumpAndSettle();
        expect(find.text('TOP PLAYERS'), findsOneWidget);
        expect(find.text(long.kana), findsOneWidget);
        expect(find.byIcon(Icons.person_outline), findsWidgets);
        expect(tester.takeException(), isNull, reason: '$scale/$width');
        await tester.drag(find.byKey(const ValueKey('website-players-list')),
            Offset(-width, 0));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    }
  });
  testWidgets('空状態は欄もVIEW ALLも追加せず、実リンク欠損ならボタンを追加しない', (tester) async {
    await tester.pumpWidget(app(null));
    await tester.pumpAndSettle();
    expect(find.text('TOP PLAYERS'), findsNothing);
    expect(find.byType(ListView), findsNothing);
    expect(find.text('VIEW ALL'), findsNothing);
    final data = WebsitePlayers.parseHomepage(fixture, home)!;
    await tester.pumpWidget(app(WebsitePlayers(players: data.players)));
    await tester.pumpAndSettle();
    expect(find.text('TOP PLAYERS'), findsOneWidget);
    expect(find.text('VIEW ALL'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('カードとVIEW ALLはそれぞれの公開実URLを外部で開く', (tester) async {
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
    final data = WebsitePlayers.parseHomepage(fixture, home)!;
    await tester.pumpWidget(app(data));
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(ValueKey('player-${data.players.first.url.path}')));
    await tester.pumpAndSettle();
    expect(calls.last.method, 'launch');
    expect((calls.last.arguments as Map)['url'],
        data.players.first.url.toString());
    expect((calls.last.arguments as Map)['useSafariVC'], isFalse);
    expect((calls.last.arguments as Map)['useWebView'], isFalse);
    await tester
        .ensureVisible(find.byKey(const ValueKey('website-players-view-all')));
    await tester.tap(find.byKey(const ValueKey('website-players-view-all')));
    await tester.pumpAndSettle();
    expect((calls.last.arguments as Map)['url'], data.viewAllUrl.toString());
    expect(calls, hasLength(2));
    expect(tester.takeException(), isNull);
  });
  testWidgets('起動失敗は再試行できる表示を保つ', (tester) async {
    const channel = MethodChannel('plugins.flutter.io/url_launcher');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => false);
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    final data = WebsitePlayers.parseHomepage(fixture, home)!;
    await tester.pumpWidget(app(data));
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(ValueKey('player-${data.players.first.url.path}')));
    await tester.pump();
    expect(find.text('選手ページを開けませんでした。'), findsOneWidget);
    expect(find.byKey(const ValueKey('website-players-list')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 5));
  });
}
