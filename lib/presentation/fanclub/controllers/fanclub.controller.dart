import 'package:get/get.dart';
import 'package:koto_blue_sharks/utils/Constant.dart';
import 'package:webview_flutter/webview_flutter.dart';

class FanclubController extends GetxController {
  late final WebViewController _controller;

  RxBool isLoading = false.obs;
  RxString currentUrl = 'https://blue-sharks.jp/team/home/'.obs;

  WebViewController get webViewController => _controller;

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
          onPageFinished: (String url) async {
            currentUrl.value = url;
            // _calculateWebViewHeight();
            await _controller.runJavaScript('''
                  window.scrollTo(0, 280); // Scroll to 500px from the top
                ''');
            _controller.runJavaScript(
              '''
              
                  document.querySelectorAll('header').forEach(element => element.remove());
                   document.querySelectorAll('breadcrumb').forEach(element2 => element2.remove());
                  
                  var element = document.getElementById('header');
                  if (element) {
                    element.remove();
                  }
                  
                  var element2 = document.getElementById('breadcrumb');
                  if (element2) {
                    element2.remove();
                  }      
                  
                  ''',
            );
          },
        ),
      );

    controller.loadRequest(Uri.parse('${Constants.baseUrlWeb}/fanclub/'));
    _controller = controller;
  }

}
