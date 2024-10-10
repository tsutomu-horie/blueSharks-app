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

    return SingleChildScrollView(
      child: Column(
        children: [
          DefaultHeaderTitleView(
              LocaleKeys.team.tr, LocaleKeys.team_en.tr.toUpperCase()),
          SizedBox(
            height: 16.h,
          ),
          Obx(() {
            return SizedBox(
              height: webViewCtrl.webContentHeight.value, // Dynamic height
              child: WebViewWidget(controller: webViewCtrl.webViewController),
            );
          }),
        ],
      ),
    );
  }
}
