import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/models/game_guide/game_guide_post.dart';
import 'package:koto_blue_sharks/presentation/game_guide/game_guide_detail.screen.dart';
// Test doubles use the platform interfaces already supplied by the plugins.
// ignore: depend_on_referenced_packages
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:url_launcher_platform_interface/link.dart';
// ignore: depend_on_referenced_packages
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

const _article = 'https://blue-sharks.jp/game-guide/1/';
const _link = 'https://blue-sharks.jp/game-guide/2/';

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
  late JavaScriptChannelParams channel;
  final loads = <Uri>[];
  final scripts = <String>[];
  bool hasHistory = false;
  Completer<bool>? historyCompletion;
  int historyChecks = 0;
  int backCount = 0;
  Completer<void>? scriptCompletion;

  void link(String url) =>
      channel.onMessageReceived(JavaScriptMessage(message: url));

  @override
  Future<void> setJavaScriptMode(JavaScriptMode mode) async {}
  @override
  Future<void> setBackgroundColor(Color color) async {}
  @override
  Future<void> enableZoom(bool enabled) async {}
  @override
  Future<void> addJavaScriptChannel(JavaScriptChannelParams params) async {
    channel = params;
  }

  @override
  Future<void> setPlatformNavigationDelegate(
      PlatformNavigationDelegate delegate) async {}
  @override
  Future<void> loadRequest(LoadRequestParams params) async {
    loads.add(params.uri);
  }

  @override
  Future<void> runJavaScript(String script) async {
    scripts.add(script);
    await scriptCompletion?.future;
  }

  @override
  Future<bool> canGoBack() async {
    historyChecks++;
    return historyCompletion == null
        ? hasHistory
        : await historyCompletion!.future;
  }

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
  late ProgressCallback progress;
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
  Future<void> setOnProgress(ProgressCallback callback) async {
    progress = callback;
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
  bool result = true;
  Completer<bool>? completion;
  @override
  Future<bool> supportsMode(PreferredLaunchMode mode) async => true;
  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    urls.add(url);
    modes.add(options.mode);
    return completion == null ? result : await completion!.future;
  }
}

void main() {
  late _WebViewPlatform web;
  late _Launcher launcher;
  late GlobalKey<NavigatorState> navigator;
  setUp(() {
    web = _WebViewPlatform();
    launcher = _Launcher();
    navigator = GlobalKey<NavigatorState>();
    WebViewPlatform.instance = web;
    UrlLauncherPlatform.instance = launcher;
    Get.testMode = true;
  });
  tearDown(() {
    Get.reset();
  });

  Future<void> open(WidgetTester tester, {bool finish = true}) async {
    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, __) => GetMaterialApp(
        navigatorKey: navigator,
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home: const Scaffold(body: Text('Main root')),
      ),
    ));
    navigator.currentState!.push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('記事一覧'))));
    await tester.pumpAndSettle();
    navigator.currentState!.push(MaterialPageRoute<void>(
      builder: (_) => GameGuideDetailScreen(
          post: GameGuidePost(
        id: 1,
        title: '記事',
        publishedAt: DateTime(2026, 10, 9),
        detailUrl: _article,
      )),
    ));
    await tester.pump(const Duration(milliseconds: 500));
    if (finish) {
      web.delegate.finished(_article);
      await tester.pumpAndSettle();
    }
  }

  Future<void> confirm(WidgetTester tester, String label) async {
    await tester.pumpAndSettle();
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets('初期読込/redirectと同一domainのプログラム遷移を維持する', (tester) async {
    await open(tester, finish: false);
    expect(web.controller.loads, [Uri.parse(_article)]);
    expect(
        await web.delegate.request(const NavigationRequest(
            url: 'https://blue-sharks.jp/redirect/', isMainFrame: true)),
        NavigationDecision.navigate);
    expect(
        await web.delegate.request(const NavigationRequest(
            url: 'https://example.com/initial-redirect', isMainFrame: true)),
        NavigationDecision.navigate);
    web.delegate.finished(_article);
    await tester.pumpAndSettle();
    expect(
        await web.delegate
            .request(const NavigationRequest(url: _article, isMainFrame: true)),
        NavigationDecision.navigate);
    expect(launcher.urls, isEmpty);
  });

  testWidgets('handler設置完了までWebView操作を待つ', (tester) async {
    await open(tester, finish: false);
    web.controller.scriptCompletion = Completer<void>();
    web.delegate.finished(_article);
    await tester.pump();
    final pointer = tester.widget<IgnorePointer>(find
        .ancestor(
            of: find.byKey(const ValueKey('fixture-webview')),
            matching: find.byType(IgnorePointer))
        .first);
    expect(pointer.ignoring, isTrue);
    web.controller.scriptCompletion!.complete();
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<IgnorePointer>(find
                .ancestor(
                    of: find.byKey(const ValueKey('fixture-webview')),
                    matching: find.byType(IgnorePointer))
                .first)
            .ignoring,
        isFalse);
  });

  testWidgets('古いページのJS完了で次ページの操作を解禁しない', (tester) async {
    await open(tester, finish: false);
    final oldScript = Completer<void>();
    web.controller.scriptCompletion = oldScript;
    web.delegate.finished(_article);
    await tester.pump();
    web.delegate.started('https://blue-sharks.jp/redirect');
    oldScript.complete();
    await tester.pump();
    expect(
        tester
            .widget<IgnorePointer>(find
                .ancestor(
                    of: find.byKey(const ValueKey('fixture-webview')),
                    matching: find.byType(IgnorePointer))
                .first)
            .ignoring,
        isTrue);
    web.controller.scriptCompletion = null;
    web.delegate.finished('https://blue-sharks.jp/redirect');
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<IgnorePointer>(find
                .ancestor(
                    of: find.byKey(const ValueKey('fixture-webview')),
                    matching: find.byType(IgnorePointer))
                .first)
            .ignoring,
        isFalse);
  });

  testWidgets('確認を別routeが覆った後に戻っても古い承認を起動しない', (tester) async {
    await open(tester);
    web.controller.link(_link);
    await tester.pumpAndSettle();
    navigator.currentState!.push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('別画面'))));
    await tester.pumpAndSettle();
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    await confirm(tester, '開く');
    expect(launcher.urls, isEmpty);
  });

  testWidgets('同一domainリンクは確認承認後に外部へ一回開く', (tester) async {
    await open(tester);
    web.controller.link(_link);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(launcher.urls, isEmpty);
    await confirm(tester, '開く');
    expect(launcher.urls, [_link]);
    expect(launcher.modes, [PreferredLaunchMode.externalApplication]);
    expect(web.controller.loads, [Uri.parse(_article)]);
  });

  testWidgets('連打中のdialogと外部起動を重複させない', (tester) async {
    await open(tester);
    launcher.completion = Completer<bool>();
    web.controller.link(_link);
    web.controller.link('https://blue-sharks.jp/other');
    await confirm(tester, '開く');
    web.controller.link(_link);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(launcher.urls, [_link]);
    launcher.completion!.complete(true);
    await tester.pumpAndSettle();
  });

  for (final dismiss in ['キャンセル', '戻る']) {
    testWidgets('$dismissで外部起動/記事遷移しない', (tester) async {
      await open(tester);
      web.controller.link(_link);
      await tester.pumpAndSettle();
      if (dismiss == '戻る') {
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
      } else {
        await confirm(tester, 'キャンセル');
      }
      expect(launcher.urls, isEmpty);
      expect(web.controller.loads, [Uri.parse(_article)]);
    });
  }

  testWidgets('background/復帰後の古い承認を起動しない', (tester) async {
    await open(tester);
    web.controller.link(_link);
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await confirm(tester, '開く');
    expect(launcher.urls, isEmpty);
    web.controller.link(_link);
    await confirm(tester, '開く');
    expect(launcher.urls, [_link]);
  });

  testWidgets('確認中に記事画面を離脱すると古い承認は無効', (tester) async {
    await open(tester);
    web.controller.link(_link);
    await tester.pumpAndSettle();
    final route =
        ModalRoute.of(tester.element(find.byType(GameGuideDetailScreen)))!;
    navigator.currentState!.removeRoute(route);
    await tester.pumpAndSettle();
    expect(find.byType(GameGuideDetailScreen), findsNothing);
    await confirm(tester, '開く');
    expect(launcher.urls, isEmpty);
  });

  testWidgets('Web履歴ありのAppbar戻り/履歴なしのOS戻り', (tester) async {
    await open(tester);
    web.controller.hasHistory = true;
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(web.controller.backCount, 1);
    expect(find.byType(GameGuideDetailScreen), findsOneWidget);
    web.controller.hasHistory = false;
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('記事一覧'), findsOneWidget);
  });

  testWidgets('遅いWeb履歴確認中の戻る連打は一覧を越えてpopしない', (tester) async {
    await open(tester);
    web.controller.historyCompletion = Completer<bool>();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(web.controller.historyChecks, 1);
    web.controller.historyCompletion!.complete(false);
    await tester.pumpAndSettle();
    expect(find.text('記事一覧'), findsOneWidget);
    expect(find.text('Main root'), findsNothing);
  });

  testWidgets('履歴確認中の画面離脱で別routeをpopしない', (tester) async {
    await open(tester);
    web.controller.historyCompletion = Completer<bool>();
    await tester.tap(find.byIcon(Icons.arrow_back));
    navigator.currentState!.push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('別画面'))));
    await tester.pumpAndSettle();
    web.controller.historyCompletion!.complete(false);
    await tester.pumpAndSettle();
    expect(find.text('別画面'), findsOneWidget);
  });

  testWidgets('外部URL/特殊scheme/未対応handlerの既存経路', (tester) async {
    await open(tester);
    for (final url in [
      'https://example.com/ticket.pdf',
      'tel:0000000000',
      'mailto:fixture@example.invalid',
      'maps://?q=fixture',
      'fixture-unhandled://link'
    ]) {
      expect(
          await web.delegate
              .request(NavigationRequest(url: url, isMainFrame: true)),
          NavigationDecision.prevent);
      await confirm(tester, 'キャンセル');
    }
    expect(launcher.urls, isEmpty);
    launcher.result = false;
    web.controller.link('fixture-unhandled://link');
    await confirm(tester, '開く');
    expect(find.text('対応するアプリで開けませんでした。'), findsOneWidget);
  });

  testWidgets('loading/30秒timeout/retryとmain frame errorを維持する', (tester) async {
    await open(tester, finish: false);
    web.delegate.started(_article);
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    await tester.pump(const Duration(seconds: 30));
    expect(find.text('読み込みがタイムアウトしました。'), findsOneWidget);
    await tester.tap(find.text('再読み込み'));
    await tester.pump();
    expect(web.controller.loads, [Uri.parse(_article), Uri.parse(_article)]);
    expect(
        await web.delegate.request(const NavigationRequest(
            url: 'https://example.com/initial', isMainFrame: true)),
        NavigationDecision.navigate);
    web.delegate.error(const WebResourceError(
        errorCode: -1, description: 'fixture', isForMainFrame: false));
    await tester.pump();
    expect(find.text('記事を読み込めませんでした。'), findsNothing);
    web.delegate.error(const WebResourceError(
        errorCode: -1, description: 'fixture', isForMainFrame: true));
    await tester.pump();
    expect(find.text('記事を読み込めませんでした。'), findsOneWidget);
    await tester.tap(find.text('再読み込み'));
    web.delegate.finished(_article);
    await tester.pumpAndSettle();
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });
}
