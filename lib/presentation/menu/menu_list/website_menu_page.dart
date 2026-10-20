import 'package:flutter/material.dart';
import 'package:koto_blue_sharks/utils/constant.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// The renewed site's member/match posts no longer expose the legacy fields.
/// Use its public pages without depending on the old posts/categories API.
class WebsiteMenuPage extends StatefulWidget {
  const WebsiteMenuPage({
    super.key,
    required this.path,
    required this.title,
  });

  final String path;
  final String title;

  @override
  State<WebsiteMenuPage> createState() => _WebsiteMenuPageState();
}

class _WebsiteMenuPageState extends State<WebsiteMenuPage> {
  late final Uri _initialUrl =
      Uri.parse(Constants.baseUrl).resolve(widget.path);
  late final WebViewController _controller;
  late Uri _currentUrl = _initialUrl;
  bool _loading = true;
  bool _failed = false;
  bool _canGoBack = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController();
    _configure();
  }

  Future<void> _configure() async {
    try {
      await _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await _controller.setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) {
          _currentUrl = Uri.parse(url);
          if (mounted) {
            setState(() {
              _loading = true;
              _failed = false;
            });
          }
        },
        onPageFinished: (_) async {
          var canGoBack = false;
          try {
            canGoBack = await _controller.canGoBack();
          } catch (_) {
            // History may be unavailable after the native view is disposed.
          }
          if (mounted) {
            setState(() {
              _loading = false;
              _canGoBack = canGoBack;
            });
          }
        },
        onWebResourceError: (error) {
          // WKWebView cancels the previous request on reload/navigation.
          if (error.errorCode == -999) return;
          if (error.isForMainFrame == true) _showError();
        },
        onHttpError: (error) {
          // WK does not supply a request URL or a main-frame flag here. Keep
          // its error document visible rather than hide a healthy page because
          // an embedded frame failed; the reload control remains available.
          if (error.request == null) return;
          if (error.request?.uri == _currentUrl) _showError();
        },
        onNavigationRequest: (request) async {
          if (!request.isMainFrame) return NavigationDecision.navigate;
          final url = Uri.tryParse(request.url);
          if (url == null) return NavigationDecision.prevent;
          if (url.scheme == 'https' &&
              url.hasAuthority &&
              url.origin == _initialUrl.origin &&
              url.userInfo.isEmpty) {
            return NavigationDecision.navigate;
          }
          if (const ['https', 'http', 'mailto', 'tel'].contains(url.scheme)) {
            await _openExternal(url);
          }
          return NavigationDecision.prevent;
        },
      ));
      await _loadInitialPage();
    } catch (_) {
      _showError();
    }
  }

  void _showError() {
    if (mounted) {
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  Future<void> _loadInitialPage() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      await _controller.loadRequest(_initialUrl);
    } catch (_) {
      _showError();
    }
  }

  Future<void> _openExternal(Uri url) async {
    try {
      if (await launchUrl(url, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // Leave the page available when the external app cannot be opened.
    }
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('ページを開けませんでした。')));
    }
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        Row(children: [
          IconButton(
            key: const ValueKey('website-menu-back'),
            tooltip: '前のページへ',
            onPressed: _canGoBack ? _controller.goBack : null,
            icon: const Icon(Icons.arrow_back),
          ),
          Expanded(child: Text(widget.title)),
          IconButton(
            key: const ValueKey('website-menu-reload'),
            tooltip: '一覧を再読み込み',
            onPressed: _loadInitialPage,
            icon: const Icon(Icons.refresh),
          ),
        ]),
        if (_loading) const LinearProgressIndicator(),
        Expanded(
          child: _failed
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('ページを取得できませんでした。'),
                    TextButton(
                        onPressed: _loadInitialPage, child: const Text('再試行')),
                    TextButton(
                        onPressed: () => _openExternal(_initialUrl),
                        child: const Text('ブラウザで開く')),
                  ]),
                )
              : WebViewWidget(controller: _controller),
        ),
      ]);
}
