import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/menu/menu_list/website_menu_page.dart';
// ignore: depend_on_referenced_packages
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:url_launcher_platform_interface/link.dart';
// ignore: depend_on_referenced_packages
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

class _WebViewPlatform extends WebViewPlatform {
  late _Controller controller;
  late _Delegate delegate;

  @override
  PlatformWebViewController createPlatformWebViewController(
      PlatformWebViewControllerCreationParams params) {
    return controller = _Controller(params);
  }

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
      PlatformNavigationDelegateCreationParams params) {
    return delegate = _Delegate(params);
  }

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
          PlatformWebViewWidgetCreationParams params) =>
      _WebViewWidget(params);
}

class _Controller extends PlatformWebViewController {
  _Controller(super.params) : super.implementation();
  final loads = <Uri>[];
  bool hasHistory = false;
  int backCount = 0;

  @override
  Future<void> setJavaScriptMode(JavaScriptMode mode) async {}
  @override
  Future<void> setPlatformNavigationDelegate(
      PlatformNavigationDelegate delegate) async {}
  @override
  Future<void> loadRequest(LoadRequestParams params) async {
    loads.add(params.uri);
  }

  @override
  Future<bool> canGoBack() async => hasHistory;
  @override
  Future<void> goBack() async {
    backCount++;
  }
}

class _Delegate extends PlatformNavigationDelegate {
  _Delegate(super.params) : super.implementation();
  late NavigationRequestCallback request;
  late PageEventCallback started;
  late PageEventCallback finished;
  late HttpResponseErrorCallback httpError;
  late void Function(WebResourceError) error;
  @override
  Future<void> setOnNavigationRequest(
      NavigationRequestCallback callback) async {
    request = callback;
  }

  @override
  Future<void> setOnPageStarted(PageEventCallback callback) async {
    started = callback;
  }

  @override
  Future<void> setOnPageFinished(PageEventCallback callback) async {
    finished = callback;
  }

  @override
  Future<void> setOnHttpError(HttpResponseErrorCallback callback) async {
    httpError = callback;
  }

  @override
  Future<void> setOnWebResourceError(
      void Function(WebResourceError) callback) async {
    error = callback;
  }
}

class _WebViewWidget extends PlatformWebViewWidget {
  _WebViewWidget(super.params) : super.implementation();
  @override
  Widget build(BuildContext context) =>
      const SizedBox.expand(key: ValueKey('fixture-webview'));
}

class _Launcher extends UrlLauncherPlatform {
  @override
  LinkDelegate? get linkDelegate => null;
  final urls = <String>[];
  final modes = <PreferredLaunchMode>[];
  @override
  Future<bool> supportsMode(PreferredLaunchMode mode) async => true;
  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    urls.add(url);
    modes.add(options.mode);
    return true;
  }
}

void main() {
  late _WebViewPlatform web;
  late _Launcher launcher;
  setUp(() {
    web = _WebViewPlatform();
    launcher = _Launcher();
    WebViewPlatform.instance = web;
    UrlLauncherPlatform.instance = launcher;
  });

  Future<void> open(WidgetTester tester, String path) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
      body: WebsiteMenuPage(path: path, title: '公式ページ'),
    )));
    await tester.pump();
  }

  testWidgets('移行済み選手と試合を旧postsではなく現サイトの一覧から開く', (tester) async {
    for (final path in ['/members/', '/schedule-and-result/']) {
      await tester.pumpWidget(const SizedBox.shrink());
      await open(tester, path);
      expect(web.controller.loads.single,
          Uri.parse('https://blue-sharks.donati.jp$path'));
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      web.delegate.finished(web.controller.loads.single.toString());
      await tester.pump();
      expect(find.byType(LinearProgressIndicator), findsNothing);
    }
  });

  testWidgets('同一サイトの詳細はアプリ内、チケット等の外部リンクは外部アプリへ渡す', (tester) async {
    await open(tester, '/members/');
    expect(
        await web.delegate.request(NavigationRequest(
          url: 'https://blue-sharks.donati.jp/members/prop/2025/01/17265/',
          isMainFrame: true,
        )),
        NavigationDecision.navigate);
    expect(launcher.urls, isEmpty);
    const external = 'https://bluesharks.base.shop/items/123';
    expect(
        await web.delegate
            .request(NavigationRequest(url: external, isMainFrame: true)),
        NavigationDecision.prevent);
    expect(launcher.urls, [external]);
    expect(launcher.modes.single, PreferredLaunchMode.externalApplication);
    expect(
        await web.delegate.request(
            NavigationRequest(url: 'javascript:alert(1)', isMainFrame: true)),
        NavigationDecision.prevent);
    expect(launcher.urls, [external]);
  });

  testWidgets('画像等の失敗では本文を隠さず、主文書の失敗後は再試行して復帰する', (tester) async {
    await open(tester, '/schedule-and-result/');
    web.delegate.error(WebResourceError(
        errorCode: -1, description: 'image', isForMainFrame: false));
    await tester.pump();
    expect(find.text('再試行'), findsNothing);
    web.delegate.error(WebResourceError(
        errorCode: -1, description: 'offline', isForMainFrame: true));
    await tester.pump();
    expect(find.text('ページを取得できませんでした。'), findsOneWidget);
    await tester.tap(find.text('再試行'));
    await tester.pump();
    expect(web.controller.loads, hasLength(2));
    expect(web.controller.loads.last.path, '/schedule-and-result/');
    web.delegate.finished(web.controller.loads.last.toString());
    await tester.pump();
    expect(find.text('再試行'), findsNothing);
    expect(find.byKey(const ValueKey('fixture-webview')), findsOneWidget);
  });

  testWidgets('一覧から詳細へ移動した後にページ内の戻る操作が使える', (tester) async {
    await open(tester, '/members/');
    expect(
        tester
            .widget<IconButton>(find.byWidgetPredicate(
                (widget) => widget is IconButton && widget.tooltip == '前のページへ'))
            .onPressed,
        isNull);
    web.controller.hasHistory = true;
    web.delegate
        .finished('https://blue-sharks.donati.jp/members/prop/2025/01/17265/');
    await tester.pump();
    await tester.tap(find.byTooltip('前のページへ'));
    await tester.pump();
    expect(web.controller.backCount, 1);
  });
  testWidgets('再読込によるWKキャンセルを無視し正常表示を継続する', (tester) async {
    await open(tester, '/members/');
    web.delegate.started('https://blue-sharks.donati.jp/members/');
    web.delegate.error(WebResourceError(
        errorCode: -999, description: 'cancelled', isForMainFrame: true));
    web.delegate.finished('https://blue-sharks.donati.jp/members/');
    await tester.pump();
    expect(find.text('再試行'), findsNothing);
    expect(find.byKey(const ValueKey('fixture-webview')), findsOneWidget);
  });

  testWidgets('画像のHTTPエラーは無視し、本文の404/500を再試行可能にする', (tester) async {
    await open(tester, '/members/');
    web.delegate.httpError(HttpResponseError(
        request: WebResourceRequest(
            uri: Uri.parse('https://blue-sharks.donati.jp/image.jpg'))));
    await tester.pump();
    expect(find.text('再試行'), findsNothing);
    web.delegate.httpError(HttpResponseError(
        request: WebResourceRequest(
            uri: Uri.parse('https://blue-sharks.donati.jp/members/'))));
    web.delegate.finished('https://blue-sharks.donati.jp/members/');
    await tester.pump();
    expect(find.text('再試行'), findsOneWidget);
  });
  testWidgets('URLがないWKのHTTPエラーは本文を隠さず再読込を利用できる', (tester) async {
    await open(tester, '/members/');
    web.delegate.httpError(const HttpResponseError(
        response: WebResourceResponse(uri: null, statusCode: 500)));
    web.delegate.finished('https://blue-sharks.donati.jp/members/');
    await tester.pump();
    expect(find.byKey(const ValueKey('fixture-webview')), findsOneWidget);
    expect(find.text('再試行'), findsNothing);
    await tester.tap(find.byTooltip('一覧を再読み込み'));
    await tester.pump();
    expect(web.controller.loads, hasLength(2));
  });
}
