import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/views/views/custom_text_view.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/presentation/NotificationDetail/notification_detail.screen.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';

import 'controllers/notification_list.controller.dart';

class NotificationListScreen extends GetView<NotificationListController> {
  const NotificationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final NotificationListController controller =
        Get.put(NotificationListController());

    return Scaffold(
      appBar: AppBar(
        title: CustomTextView(
          LocaleKeys.news_title.tr,
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
      body: Obx(() {
        if (controller.notificationList.isNotEmpty) {
          return ListView.builder(
              itemCount: controller.notificationList.length,
              itemBuilder: (BuildContext context, int index) =>
                  Container(
                    color: controller.notificationList[index].read_at != null ? Colors.white : BrandColor.surface,
                    child: InkWell(
                      onTap: () async {
                        await Get.to(() => NotificationDetailScreen(controller.notificationList[index]))?.then((_) {
                          // Refresh the unread notification count after returning
                          controller.getNotification();
                        });
                        // Get.to(() =>
                        //     NotificationDetailScreen(
                        //         controller.notificationList[index]));
                      },
                      child: Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16.w, vertical: 16.w),
                            child: Row(
                              children: [
                                SvgPicture.asset(
                                  "assets/vectors/ic_notification_status.svg",
                                  width: 36.w, height: 36.h,),
                                SizedBox(width: 12.w,),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CustomTextView(
                                        maxLine: 2,
                                        controller.notificationList[index].data
                                            .title, style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: TextColor.primary),),
                                      SizedBox(height: 4.h,),
                                      CustomTextView(controller.formatDate(
                                          controller.notificationList[index]
                                              .created_at))
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                         Container(color: Colors.black12, height: 1.h,)
                        ],
                      ),
                    ),
                  ));
        } else {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon or Image
                SvgPicture.asset(
                  "assets/vectors/ic_empty_news.svg",  // Your empty state icon
                  width: 48.w,
                  height: 48.h,
                ),
                SizedBox(height: 16.h),

                // Main text
                CustomTextView(
                  "ここにはニュースはありません",  // "No news here"
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: TextColor.primary,
                  ),
                  align: TextAlign.center,
                ),
                SizedBox(height: 8.h),

                // Description text
                Row(
                  children: [
                    SizedBox(width: 60.w,),
                    Flexible(
                      child: CustomTextView(
                        "管理者がアプリでニュースを放送した後、ニュースのリストがここに表示されます。",
                        // "After the administrator broadcasts news in the app,\nthe news list will be displayed here."
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: TextColor.secondary,
                        ),
                        align: TextAlign.center,
                        type: TDSFontType.bodyTextMedium,
                      ),
                    ),
                    SizedBox(width: 60.w,),
                  ],
                ),
              ],
            ),
          );
        }
      }),
    );
  }
}
