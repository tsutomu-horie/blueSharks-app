import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/views/views/default_header_title_view.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';

import 'controllers/webview.controller.dart';
import 'package:webview_flutter/webview_flutter.dart';

enum WebviewType {
  team,
  history,
  partner,
  fanclub
}

class WebviewScreen extends GetView<WebviewController> {
  const WebviewScreen(this.type, {super.key});

  final WebviewType type;

  @override
  Widget build(BuildContext context) {
    final WebviewController webViewCtrl = Get.put(WebviewController());

    webViewCtrl.sendAnalytics("$type");
    if (type == WebviewType.team) {
      return SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 750.h,
              child: WebViewWidget(controller: webViewCtrl.webViewController,),
            ),
            SizedBox(
              height: 2670.h,
              child: WebViewWidget(
                controller: webViewCtrl.webViewControllerHistory,),
            ),
            SizedBox(
              height: 140.h,
              child: WebViewWidget(
                controller: webViewCtrl.webViewControllerStadium,),
            ),
          ],
        ),
      );
    } else {
      return SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 750.h,
              child: WebViewWidget(controller: webViewCtrl.webViewControllerPartner,),
            ),
          ],
        ),
      );
    }
  }
}
