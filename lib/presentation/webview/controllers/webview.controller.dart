import 'package:get/get.dart';
import 'package:koto_blue_sharks/utils/Constant.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebviewController extends GetxController {
  late final WebViewController _controller;
  RxDouble webContentHeight = 300.0.obs; // Default height before content is loaded


  // Observable variables
  RxBool isLoading = false.obs;
  RxString currentUrl = 'https://blue-sharks.jp/team/home/'.obs;

  @override
  void onInit() {
    super.onInit();
    setupWebViewController();
  }

  void setupWebViewController() {
    final WebViewController controller = WebViewController();
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            isLoading.value = progress < 100;
          },
          onPageStarted: (String url) {
            currentUrl.value = url;
          },
          onPageFinished: (String url) {
            currentUrl.value = url;
            _calculateWebViewHeight();
          },
        ),
      );

    controller.loadRequest(Uri.parse('${Constants.baseUrlWeb}/team/'));
    _controller = controller;
  }

  WebViewController get webViewController => _controller;

  void loadUrl(String url) {
    _controller.loadRequest(Uri.parse(url));
  }

  void _calculateWebViewHeight() {
    // JavaScript to calculate the document's body height
    _controller.runJavaScript(
      '''
      (function() {
        var height = Math.max(
          document.body.scrollHeight, document.documentElement.scrollHeight,
          document.body.offsetHeight, document.documentElement.offsetHeight,
          document.body.clientHeight, document.documentElement.clientHeight
        );
        Toaster.postMessage(height.toString());
      })();
      ''',
    );
  }
}
