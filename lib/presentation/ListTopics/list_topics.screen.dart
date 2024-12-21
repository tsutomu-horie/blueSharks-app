import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/models/info/post.dart';
import 'package:koto_blue_sharks/app/views/views/custom_text_view.dart';
import 'package:koto_blue_sharks/app/views/views/default_header_title_view.dart';
import 'package:koto_blue_sharks/app/views/views/topic/views/topic_item_view.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';
import 'package:koto_blue_sharks/utils/map_id_to_categories.dart';
import 'package:shimmer/shimmer.dart';

import 'controllers/list_topics.controller.dart';

class ListTopicsScreen  extends StatelessWidget {
  final Rx<int?> selectedTopicId = Rx<int?>(null);

  ListTopicsScreen({super.key, required this.onOpenDetail}); // Observable to store the selected topic ID
  final Function(Post) onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final ListTopicsController controller = Get.put(ListTopicsController());

    controller.selectedIndex.value = 0;
    final List<String> tabs = [
      LocaleKeys.all.tr,
      LocaleKeys.notice_tab.tr,
      LocaleKeys.event_information.tr,
      LocaleKeys.event_tab.tr,
      LocaleKeys.activites.tr,
    ];

    return Scaffold(
      backgroundColor: BackgroundColor.primary,
      body: RefreshIndicator(
        onRefresh: () async {
          controller.refreshPage(); // Your refresh logic
        },
        notificationPredicate: (notification) {
          // Ensure the notification is from the outer scroll view
          return notification.depth == 1;
        },
        child: NestedScrollView(
          controller: controller.matchScrollController,
          // Unified scroll controller
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverAppBar(
                backgroundColor: Colors.white,
                expandedHeight: 162.h,
                // Adjust height based on the header size
                floating: false,
                pinned: true,
                // This keeps the tab bar pinned at the top when scrolling
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: Column(
                    children: [
                      Container(
                        color: const Color(0xFFFAFAFA),
                        child: DefaultHeaderTitleView(LocaleKeys.topics.tr, LocaleKeys.topics_en.tr.toUpperCase()),
                      ),
                      Container(
                        color: BorderColor.primary,
                        height: 1.h,
                      ),
                      SizedBox(height: 12.h),
                    ],
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: Size.fromHeight(0.h),
                  // Adjust the height for the tab bar
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          children: List.generate(tabs.length, (index) {
                            return Obx(() {
                              final isSelect =
                                  controller.selectedIndex.value == index;
                              return InkWell(
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () => controller.changeTab(index),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isSelect
                                          ? BrandColor.main
                                          : BackgroundColor.secondary,
                                      borderRadius: BorderRadius.circular(24.r),
                                      border: isSelect
                                          ? Border.all(
                                              color: BrandColor.border,
                                              width: 2.w)
                                          : null,
                                    ),
                                    padding: EdgeInsets.symmetric(
                                        vertical: 6.h, horizontal: 16.w),
                                    child: CustomTextView(
                                      tabs[index],
                                      type: TDSFontType.labelLarge,
                                      color: isSelect
                                          ? Colors.white
                                          : TextColor.secondary,
                                    ),
                                  ),
                                ),
                              );
                            });
                          }),
                        ),
                        SizedBox(height: 12.h),
                      ],
                    ),
                  ),
                ),
              ),
            ];
          },
          body: CustomScrollView(
            slivers: [
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    return Obx(() {
                      final data = controller.getTabData(controller
                          .selectedIndex.value); // Fetch data for the current tab
        
                      if (data.isEmpty) {
                        return Column(
                          children: [
                            TopicItemViewShimmer(),
                            TopicItemViewShimmer(),
                          ],
                        );
                        // return Column(
                        //   children: [
                        //     shimmer(),
                        //     shimmer(),
                        //     shimmer(),
                        //   ]
                        // );
                      } else {
                        return Column(
                          children: [
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: data.length,
                              itemBuilder: (context, itemIndex) {
                                return FutureBuilder<String>(
                                  future: controller.getNewsImage("${data[itemIndex].id}"),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      // Show shimmer while waiting for the image
                                      return TopicItemViewShimmer();
                                    } else if (snapshot.hasError) {
                                      // Fallback view if there's an error
                                      return TopicItemView(
                                            () {
                                          onOpenDetail(data[itemIndex]);
                                        },
                                        image: null,
                                        date: data[itemIndex].date,
                                        title: data[itemIndex].title.rendered,
                                        categories: mapCategoryIdsToNames(data[itemIndex].categories),
                                      );
                                    } else {
                                      // Display the image when loaded
                                      return TopicItemView(
                                            () {
                                          onOpenDetail(data[itemIndex]);
                                        },
                                        image: snapshot.data,
                                        date: data[itemIndex].date,
                                        title: data[itemIndex].title.rendered,
                                        categories: mapCategoryIdsToNames(data[itemIndex].categories),
                                      );
                                    }
                                  },
                                );
                              },
                            ),

                            SizedBox(height: 24.h,),
                          ],
                        );
                      }
                    });
                  },
                  childCount: 1, // You can manage this based on your data
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget shimmer() {
    return Shimmer.fromColors(
      baseColor: BorderColor.disabled,
      highlightColor: BorderColor.subtle,
      child: Container(
        width: double.infinity,
        height: 200.h,
        decoration: BoxDecoration(
          color: BorderColor.disabled,
          borderRadius: BorderRadius.all(Radius.circular(4.r)),
        ),
      ),
    );
  }
}
