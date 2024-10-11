import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/views/views/custom_text_view.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'controllers/fanclub.controller.dart';

class FanclubScreen extends GetView<FanclubController> {
  const FanclubScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final FanclubController controller = Get.put(FanclubController());

    return Scaffold(
      appBar: AppBar(
        title: CustomTextView(
          LocaleKeys.fan_club.tr,
          type: TDSFontType.titleMedium,
          color: TextColor.inverse,
        ),
        centerTitle: true,
        backgroundColor: BrandColor.main,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: IconColor.inverse,
          ),
          // Change this to your desired icon
          onPressed: () {
            Get.back();
          },
        ),
      ),
      body: WebViewWidget(controller: controller.webViewController,)
    );
  }
}
