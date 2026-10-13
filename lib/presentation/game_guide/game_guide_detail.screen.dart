import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/models/game_guide/game_guide_post.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class GameGuideDetailScreen extends StatefulWidget {
  const GameGuideDetailScreen({
    super.key,
    required this.post,
  });

  final GameGuidePost post;

  @override
  State<GameGuideDetailScreen> createState() => _GameGuideDetailScreenState();
}

class _GameGuideDetailScreenState extends State<GameGuideDetailScreen>
    with WidgetsBindingObserver {
  static const _externalLinkChannelName = 'GameGuideExternalLink';

  late final WebViewController _webViewController;
  late final Uri _articleUri;
  Timer? _timeoutTimer;
  var _progress = 0;
  var _hasFinishedInitialLoad = false;
  String? _errorMessage;
  bool _linkHandlerReady = false;
  bool _externalLinkPending = false;
  bool _backPending = false;
  bool _isForeground = true;
  int _confirmationEpoch = 0;
  int _pageEpoch = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _articleUri = Uri.parse(widget.post.detailUrl);
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..addJavaScriptChannel(
        _externalLinkChannelName,
        onMessageReceived: (message) {
          unawaited(_confirmAndOpenExternal(message.message));
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (!mounted) return;
            setState(() => _progress = progress);
          },
          onPageStarted: (_) {
            _pageEpoch++;
            _confirmationEpoch++;
            _startTimeout();
            if (!mounted) return;
            setState(() {
              _errorMessage = null;
              _progress = 0;
              _linkHandlerReady = false;
            });
          },
          onPageFinished: (_) async {
            _timeoutTimer?.cancel();
            if (!mounted) return;
            setState(() {
              _hasFinishedInitialLoad = true;
              _progress = 100;
            });
            final pageEpoch = _pageEpoch;
            try {
              await _installLinkHandler();
              if (!mounted || pageEpoch != _pageEpoch) return;
              setState(() => _linkHandlerReady = true);
            } catch (_) {
              if (!mounted || pageEpoch != _pageEpoch) return;
              setState(() => _errorMessage = '記事を読み込めませんでした。');
            }
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == false || !mounted) return;
            _timeoutTimer?.cancel();
            setState(() {
              _errorMessage = '記事を読み込めませんでした。';
            });
          },
          onNavigationRequest: (request) {
            if (!_hasFinishedInitialLoad) {
              return NavigationDecision.navigate;
            }

            if (_isSameDomain(request.url)) {
              return NavigationDecision.navigate;
            }

            unawaited(_confirmAndOpenExternal(request.url));
            return NavigationDecision.prevent;
          },
        ),
      )
      ..enableZoom(false)
      ..loadRequest(_articleUri);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _confirmationEpoch++;
    _pageEpoch++;
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isForeground = state == AppLifecycleState.resumed;
    if (!_isForeground) _confirmationEpoch++;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          await _handleBack();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: BrandColor.hover,
          foregroundColor: Colors.white,
          title: Text(
            'ホームゲームの楽しみ方',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          leading: IconButton(
            onPressed: _handleBack,
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: Stack(
          children: [
            if (_errorMessage == null)
              IgnorePointer(
                ignoring: !_linkHandlerReady,
                child: WebViewWidget(controller: _webViewController),
              )
            else
              _DetailErrorState(
                message: _errorMessage!,
                onRetry: _reload,
                onBack: Get.back,
              ),
            if (_errorMessage == null && _progress < 100)
              LinearProgressIndicator(
                value: _progress == 0 ? null : _progress / 100,
                color: BrandColor.background,
                backgroundColor: BrandColor.surface,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleBack() async {
    if (_backPending || !mounted) return;
    final articleRoute = ModalRoute.of(context);
    if (articleRoute?.isCurrent != true) return;
    _backPending = true;
    try {
      final canGoBack = await _webViewController.canGoBack();
      if (!mounted || articleRoute?.isCurrent != true) return;
      if (canGoBack) {
        await _webViewController.goBack();
      } else {
        Get.back();
      }
    } finally {
      _backPending = false;
    }
  }

  Future<void> _reload() async {
    _pageEpoch++;
    setState(() {
      _errorMessage = null;
      _progress = 0;
      _linkHandlerReady = false;
    });
    _hasFinishedInitialLoad = false;
    await _webViewController.loadRequest(_articleUri);
  }

  void _startTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 30), () {
      if (!mounted || _progress >= 100) return;
      setState(() {
        _errorMessage = '読み込みがタイムアウトしました。';
      });
    });
  }

  bool _isSameDomain(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasAuthority) return false;
    if (uri.scheme != 'http' && uri.scheme != 'https') return false;
    return uri.host.toLowerCase() == _articleUri.host.toLowerCase();
  }

  Future<void> _installLinkHandler() async {
    await _webViewController.runJavaScript('''
      (() => {
        if (window.__gameGuideLinkHandlerInstalled) return;
        window.__gameGuideLinkHandlerInstalled = true;

        document.addEventListener('click', (event) => {
          const target = event.target;
          const anchor = target instanceof Element
              ? target.closest('a[href]')
              : null;
          if (!anchor) return;
          const isBlank = anchor.target.toLowerCase() === '_blank';
          if (!isBlank) {
            const url = new URL(anchor.href, window.location.href);
            if (url.protocol !== 'http:' && url.protocol !== 'https:') return;
            const current = new URL(window.location.href);
            // Keep page-local anchors on their existing WebView path.
            if (url.href.includes('#') && url.origin === current.origin &&
                url.pathname === current.pathname &&
                url.search === current.search) return;
          }

          event.preventDefault();
          event.stopPropagation();
          $_externalLinkChannelName.postMessage(anchor.href);
        }, true);
      })();
    ''');
  }

  Future<void> _confirmAndOpenExternal(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !mounted || !_isForeground || _externalLinkPending) {
      return;
    }
    final articleRoute = ModalRoute.of(context);
    if (articleRoute?.isCurrent != true) return;
    _externalLinkPending = true;
    final epoch = _confirmationEpoch;

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          // Covering this confirmation with another route invalidates it,
          // even if the user later returns to the old dialog.
          if (ModalRoute.isCurrentOf(context) == false) {
            _confirmationEpoch++;
          }
          return AlertDialog(
            title: const Text('外部ページを開きますか？'),
            content: Text(
              _externalLinkMessage(uri),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('キャンセル'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('開く'),
              ),
            ],
          );
        },
      );

      if (confirmed != true ||
          !mounted ||
          !_isForeground ||
          epoch != _confirmationEpoch ||
          articleRoute?.isCurrent != true) {
        return;
      }
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('対応するアプリで開けませんでした。'),
          ),
        );
      }
    } finally {
      _externalLinkPending = false;
    }
  }

  String _externalLinkMessage(Uri uri) {
    switch (uri.scheme) {
      case 'tel':
        return '電話アプリを開きます。';
      case 'mailto':
        return 'メールアプリを開きます。';
      case 'geo':
      case 'maps':
        return '地図アプリを開きます。';
      default:
        return '外部ブラウザまたは対応アプリで開きます。\n\n$uri';
    }
  }
}

class _DetailErrorState extends StatelessWidget {
  const _DetailErrorState({
    required this.message,
    required this.onRetry,
    required this.onBack,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: DangerColor.main,
              size: 52.w,
            ),
            SizedBox(height: 16.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onRetry,
                child: const Text('再読み込み'),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onBack,
                child: const Text('一覧へ戻る'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
