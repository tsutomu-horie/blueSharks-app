import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/views/views/custom_image_view.dart';
import 'package:koto_blue_sharks/app/views/views/custom_text_view.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';
import 'package:koto_blue_sharks/utils/date_formatter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'controllers/notification_detail.controller.dart';
import 'package:koto_blue_sharks/app/data/models/info/notification.dart';


class NotificationDetailScreen extends GetView<NotificationDetailController> {
  const NotificationDetailScreen(this.notificationDetail, {super.key});
  final NotificationItem? notificationDetail;

  @override
  Widget build(BuildContext context) {
    final NotificationDetailController notificationController = Get.put(NotificationDetailController());

    notificationController.readNotification("${notificationDetail?.id}");

    return Scaffold(
      appBar: AppBar(
        title: CustomTextView(
         "Detail News",
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
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(16.w),
        child: OutlinedButton(
            onPressed: () {
              Get.back();
            },
            child: CustomTextView(
              LocaleKeys.select.tr,
              type: TDSFontType.labelLarge,
              color: BrandColor.main,
            ))

      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20.h,),
            CustomTextView(
              notificationController.formatJapaneseDate(notificationDetail!.created_at),
              style: TDSTypography.bodyTextSmall,
              color: TextColor.secondary,
            ),
            SizedBox(height: 8.h,),
            CustomTextView(notificationDetail!.data.title, style: TDSTypography.titleMedium, color: TextColor.primary,),
            SizedBox(height: 24.h,),

            if (notificationDetail!.data.photo != null)
            Column(
              children: [
                AspectRatio(aspectRatio: 2.144, child: CustomImageView(image: notificationDetail!.data.photo!)),
                SizedBox(height: 16.h,),
              ],
            ),
            CustomTextView(notificationDetail!.data.body, style: TDSTypography.bodyTextMedium, color: TextColor.secondary,),
          ],
        ),
      )
    );
  }
}
