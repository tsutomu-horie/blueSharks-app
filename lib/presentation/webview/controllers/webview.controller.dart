import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/services/analytics_service.dart';
import 'package:koto_blue_sharks/utils/Constant.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebviewController extends GetxController {
  late final WebViewController _controller;
  late final WebViewController _controllerHistory;
  late final WebViewController _controllerStadium;
  late final WebViewController _controllerPartner;
  RxDouble webContentHeight = 300.0.obs; // Default height before content is loaded

  WebViewController get webViewController => _controller;
  WebViewController get webViewControllerHistory => _controllerHistory;
  WebViewController get webViewControllerStadium => _controllerStadium;
  WebViewController get webViewControllerPartner => _controllerPartner;

  // Observable variables
  RxBool isLoading = false.obs;
  RxString currentUrl = 'https://blue-sharks.jp/team/home/'.obs;

  @override
  void onInit() {
    super.onInit();
    setupWebViewController();
    setupWebViewControllerHistory();
    setupWebViewControllerStadium();
    setupWebViewControllerPartner();
  }

  void sendAnalytics(String page) {
    AnalyticsService.logPageView("webview_${page}");
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
                  
                  
                  document.body.style.overflow = 'hidden';
                  document.documentElement.style.overflow = 'hidden';
                  // Optionally disable touch actions if required
                  document.body.style.touchAction = 'none';
                  document.documentElement.style.touchAction = 'none';
                  // Disable scrolling for all elements
                  const disableScrolling = () => {
                    const allElements = document.querySelectorAll('*');
                    allElements.forEach(el => {
                      el.style.overflow = 'hidden';
                    });
                  };
                  disableScrolling();
                  
                  ''',
            );
          },
        ),
      );

    controller.loadRequest(Uri.parse('${Constants.baseUrlWeb}/team/'));
    _controller = controller;
  }

  void setupWebViewControllerHistory() {
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
            await _controllerHistory.runJavaScript('''
                  window.scrollTo(0, 280); // Scroll to 500px from the top
                ''');
            _controllerHistory.runJavaScript(
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
                  
                  document.body.style.overflow = 'hidden';
                  document.documentElement.style.overflow = 'hidden';
                  // Optionally disable touch actions if required
                  document.body.style.touchAction = 'none';
                  document.documentElement.style.touchAction = 'none';
                  // Disable scrolling for all elements
                  const disableScrolling = () => {
                    const allElements = document.querySelectorAll('*');
                    allElements.forEach(el => {
                      el.style.overflow = 'hidden';
                    });
                  };
                  disableScrolling();
                  
                  ''',
            );
          },
        ),
      );

    controller.loadRequest(Uri.parse('${Constants.baseUrlWeb}/team/history'));
    _controllerHistory = controller;
  }

  void setupWebViewControllerStadium() {
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
            await _controllerStadium.runJavaScript('''
                  window.scrollTo(0, 280); // Scroll to 500px from the top
                ''');
            _controllerStadium.runJavaScript(
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
                  
                  document.body.style.overflow = 'hidden';
                  document.documentElement.style.overflow = 'hidden';
                  // Optionally disable touch actions if required
                  document.body.style.touchAction = 'none';
                  document.documentElement.style.touchAction = 'none';
                  // Disable scrolling for all elements
                  const disableScrolling = () => {
                    const allElements = document.querySelectorAll('*');
                    allElements.forEach(el => {
                      el.style.overflow = 'hidden';
                    });
                  };
                  disableScrolling();
                  
                  ''',
            );
          },
        ),
      );

    controller.loadRequest(Uri.parse('${Constants.baseUrlWeb}/team/home'));
    _controllerStadium = controller;
  }

  void setupWebViewControllerPartner() {
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
            await _controllerPartner.runJavaScript('''
                  window.scrollTo(0, 280); // Scroll to 500px from the top
                ''');
            _controllerPartner.runJavaScript(
              '''
              
                  document.querySelectorAll('header').forEach(element => element.remove());
                   document.querySelectorAll('breadcrumb').forEach(element2 => element2.remove());
                   document.querySelectorAll('rc-anchor-container').forEach(element3 => element3.remove());
                   document.querySelectorAll('page-top isView').forEach(element4 => element4.remove());
                  
                  var element4 = document.getElementById('page-top isView');
                  if (element4) {
                    element4.remove();
                  }
                  
                  var element = document.getElementById('header');
                  if (element) {
                    element.remove();
                  }
                  
                  var element2 = document.getElementById('breadcrumb');
                  if (element2) {
                    element2.remove();
                  }    
                  
                  var element3 = document.getElementById('anchor');
                  if (element3) {
                    element3.remove();
                  }
                  
                  document.body.style.overflow = 'hidden';
                  document.documentElement.style.overflow = 'hidden';
                  // Optionally disable touch actions if required
                  document.body.style.touchAction = 'none';
                  document.documentElement.style.touchAction = 'none';
                  // Disable scrolling for all elements
                  const disableScrolling = () => {
                    const allElements = document.querySelectorAll('*');
                    allElements.forEach(el => {
                      el.style.overflow = 'hidden';
                    });
                  };
                  disableScrolling();
                  
                  ''',
            );
          },
        ),
      );

    controller.loadRequest(Uri.parse('${Constants.baseUrlWeb}/partner'));
    _controllerPartner = controller;
  }

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
