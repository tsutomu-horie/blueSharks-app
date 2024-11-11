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
          LocaleKeys.notice.tr,
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
        return ListView.builder(
            itemCount: controller.notificationList.length,
            itemBuilder: (BuildContext context, int index) => InkWell(
              onTap: (){
                Get.to(() => NotificationDetailScreen(controller.notificationList[index]));
              },
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.w),
                    child: Row(
                          children: [
                            SvgPicture.asset("assets/vectors/ic_notification_status.svg", width: 36.w, height: 36.h,),
                            SizedBox(width: 12.w,),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomTextView(controller.notificationList[index].data.title, style: TextStyle(fontWeight: FontWeight.w600, color: TextColor.primary),),
                                SizedBox(height: 4.h,),
                                CustomTextView(controller.formatDate(controller.notificationList[index].created_at))
                              ],
                            )
                          ],
                        ),
                  ),
                  const Divider()
                ],
              ),
            ));
      }),
    );
  }
}
