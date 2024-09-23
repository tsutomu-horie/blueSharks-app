import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/views/views/custom_text_view.dart';
import 'package:koto_blue_sharks/app/views/views/default_header_title_view.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';

import 'controllers/list_topics.controller.dart';

class ListTopicsScreen extends GetView<ListTopicsController> {
  const ListTopicsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ListTopicsController controller = Get.put(ListTopicsController());

    final List<String> tabs = [
      'Match Information',
      'Notice',
      'Event Information',
      'Activities',
      'Interview',
    ];

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              Container(
                color: const Color(0xFFFAFAFA),
                child: DefaultHeaderTitleView(LocaleKeys.topics_en.tr, LocaleKeys.topics.tr),
              ),
              Container(color: BorderColor.primary, height: 1.h,),
              SizedBox(height: 12.h,),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: List.generate(tabs.length, (index) {
                    return InkWell(
                      onTap: () => controller.changeTab(index),
                      child: Obx(() {
                        final isSelect = controller.selectedIndex.value == index;

                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.w),
                          child: Container(
                            decoration: BoxDecoration(
                              color:isSelect ? BrandColor.main : BackgroundColor.secondary,
                              borderRadius: BorderRadius.circular(24.r),
                              border: isSelect ? Border.all(color: BrandColor.border, width: 2.w) : null
                            ),
                            padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 16.w),
                            child: CustomTextView(tabs[index], type: TDSFontType.labelLarge, color: isSelect ? Colors.white : TextColor.secondary,),
                          ),
                        );
                      }),
                    );
                  }),
                ),
              ),

            ],
          ),
        ),
      )
    );
  }
}
