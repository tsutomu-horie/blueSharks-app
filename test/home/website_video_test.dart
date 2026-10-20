import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:koto_blue_sharks/app/views/views/other/views/video_thumbnail_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/app/data/models/home/website_video.dart';
import 'package:koto_blue_sharks/app/providers/home/website_video_provider.dart';
import 'package:koto_blue_sharks/presentation/home/controllers/home.controller.dart';
import 'package:koto_blue_sharks/utils/constant.dart';

// Reduced fixture matching the public .top-movie markup observed 2026-10-16.
const homepage = '''
<a href="https://www.youtube.com/@KotoBlueSharks">SNS</a>
<section class="top-movie" aria-label="動画">
<a class="video-card video-card--play" href="https://youtu.be/kVpQca35ECY?si=example">
<img src="https://i.ytimg.com/vi/kVpQca35ECY/hqdefault.jpg" alt="【2025－26】チームPV"></a>
<a class="video-card" href="https://youtu.be/jjaMEanqqW0">
<img src="/uploads/second.jpg" alt="試合 &amp; レポート"></a>
</section>
''';

void main() {
  final origin = Uri.parse('https://blue-sharks.donati.jp/');
  test('公開動画欄だけをHP順に取得し相対画像URLと文字参照を解決する', () {
    final videos = WebsiteVideo.parseHomepage(homepage, origin);
    expect(videos.map((v) => v.url.path), ['/kVpQca35ECY', '/jjaMEanqqW0']);
    expect(videos[1].thumbnailUrl.toString(), '${origin}uploads/second.jpg');
    expect(videos[1].title, '試合 & レポート');
    expect(videos[0].url.queryParameters['si'], 'example');
  });
  test('同じ動画のwatch/短縮URL重複を除き最初の掲載位置を保持する', () {
    final videos = WebsiteVideo.parseHomepage('''$homepage
      <section class="top-movie"><a class="video-card"
      href="https://www.youtube.com/watch?v=kVpQca35ECY">
      <img src="/duplicate.jpg" alt="duplicate"></a></section>
    ''', origin);
    expect(videos, hasLength(2));
    expect(videos.first.title, '【2025－26】チームPV');
  });
  test('不完全なcardや不正なURLは推測で補完しない', () {
    for (final href in [
      'javascript:alert(1)',
      'http://youtu.be/kVpQca35ECY',
      'https://youtu.be.evil.example/kVpQca35ECY',
      'https://user:pass@youtu.be/kVpQca35ECY',
      'https://youtu.be:444/kVpQca35ECY',
      'https://youtu.be/invalid',
      'https://youtube.com/@KotoBlueSharks',
    ]) {
      expect(WebsiteVideo.parseHomepage('''<section class="top-movie">
        <a class="video-card" href="$href"><img src="/a.jpg" alt="x"></a>
        </section>''', origin), isEmpty, reason: href);
    }
    expect(WebsiteVideo.parseHomepage('''<section class="top-movie">
      <a class="video-card" href="https://youtu.be/kVpQca35ECY">no image</a>
      <a class="video-card" href="https://youtu.be/jjaMEanqqW0"><img src="javascript:x" alt="x"></a>
      <a class="video-card" href="https://youtu.be/N7kYX0fWhfs"><img src="/a.jpg"></a>
      </section>''', origin), isEmpty);
    expect(WebsiteVideo.parseHomepage('<html>maintenance</html>', origin),
        isEmpty);
  });
  test('取得先は既存WordPress環境のルートを使用する', () async {
    Uri? requested;
    final provider = WebsiteVideoProvider(loadHomepage: (uri) async {
      requested = uri;
      return homepage;
    });
    expect(await provider.fetchVideos(), hasLength(2));
    expect(requested, Uri.parse(Constants.baseUrl).resolve('/'));
    expect(requested!.path, '/');
    expect(requested!.query, isEmpty);
    provider.httpClient.close();
  });
  test('明示refreshだけ再取得し失敗時は成功済み動画を保持する', () async {
    var calls = 0;
    final controller =
        HomeController(websiteVideoProvider: WebsiteVideoProvider(
      loadHomepage: (_) async {
        calls++;
        if (calls == 2) throw const WebsiteVideoRequestException();
        return calls == 3 ? '<html></html>' : homepage;
      },
    ));
    await controller.fetchWebsiteContent();
    expect(controller.websiteVideos, hasLength(2));
    await controller.fetchWebsiteContent();
    expect(calls, 1);
    await controller.fetchWebsiteContent(force: true);
    expect(controller.websiteVideos, hasLength(2));
    await controller.fetchWebsiteContent(force: true);
    expect(controller.websiteVideos, isEmpty);
    controller.onClose();
  });
  test('同時refreshを一本にし破棄後に結果を更新しない', () async {
    var calls = 0;
    final pending = Completer<String>();
    final controller =
        HomeController(websiteVideoProvider: WebsiteVideoProvider(
      loadHomepage: (_) {
        calls++;
        return pending.future;
      },
    ));
    final first = controller.fetchWebsiteContent();
    await controller.fetchWebsiteContent(force: true);
    expect(calls, 1);
    controller.onDelete();
    pending.complete(homepage);
    await first;
    expect(controller.websiteVideos, isEmpty);
  });
  test('初回失敗は既存固定動画用の空状態を保持する', () async {
    final controller = HomeController(
        websiteVideoProvider: WebsiteVideoProvider(
      loadHomepage: (_) async => throw const WebsiteVideoRequestException(),
    ));
    await controller.fetchWebsiteContent();
    expect(controller.websiteVideos, isEmpty);
    controller.onClose();
  });
  testWidgets('320/375/430幅で動画を横送りでき、空なら既存カードを表示する', (tester) async {
    final videos = WebsiteVideo.parseHomepage(homepage, origin);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final width in [320.0, 375.0, 430.0]) {
      tester.view.physicalSize = Size(width, 812);
      await tester.pumpWidget(ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, __) => MaterialApp(
          home: Scaffold(body: VideoThumbnailView(videos: videos)),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(PageView), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(PageView), Offset(-width, 0));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, __) => const MaterialApp(
        home: Scaffold(body: VideoThumbnailView()),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(PageView), findsNothing);
    expect(tester.widget<Image>(find.byType(Image)).image, isA<AssetImage>());
    expect(tester.takeException(), isNull);
  });
  testWidgets('固定動画は従来の開き方を維持し、HP動画は対応URLを外部で開く', (tester) async {
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
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Future<void> show(List<WebsiteVideo> videos) async {
      await tester.pumpWidget(ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, __) => MaterialApp(
          home: Scaffold(body: VideoThumbnailView(videos: videos)),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find
          .descendant(
              of: find.byType(VideoThumbnailView),
              matching: find.byType(GestureDetector))
          .first);
      await tester.pumpAndSettle();
    }

    await show([]);
    var args = calls.last.arguments as Map;
    expect(calls.last.method, 'launch');
    expect(args['url'], Constants.videoUrl);
    expect(args['useSafariVC'], isTrue);
    expect(args['useWebView'], isFalse);
    calls.clear();
    final videos = WebsiteVideo.parseHomepage(homepage, origin);
    await show(videos);
    args = calls.last.arguments as Map;
    expect(args['url'], videos.first.url.toString());
    expect(args['useSafariVC'], isFalse);
    expect(args['useWebView'], isFalse);
    expect(tester.takeException(), isNull);
  });
}
