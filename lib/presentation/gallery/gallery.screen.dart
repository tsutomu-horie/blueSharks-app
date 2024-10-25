import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/views/views/default_header_title_view.dart';
import 'package:koto_blue_sharks/app/views/views/year_filter_controller_view.dart';

import 'controllers/gallery.controller.dart';

class GalleryScreen extends GetView<GalleryController> {
  const GalleryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final GalleryController controller = Get.put(GalleryController());

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          DefaultHeaderTitleView("**ギャラリー", "Gallery".toUpperCase()),
          Padding(padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white, // Background color
                borderRadius: BorderRadius.circular(30), // Rounded container
                border: Border.all(color: Colors.grey.shade300), // Outer border
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  buildToggleOption("GAME", 0),
                  SizedBox(width: 8.w,),
                  Container(width: 1.w, height: 16.h, color: Colors.grey,),
                  SizedBox(width: 8.w,),
                  buildToggleOption("EVENT", 1),
                  SizedBox(width: 8.w,),
                  Container(width: 1.w, height: 16.h, color: Colors.grey,),
                  SizedBox(width: 8.w,),
                  buildToggleOption("OTHER", 2),
                ],
              ),
            ),
          ),
          YearFilter(
            years: List.generate(DateTime.now().year - 2019 + 1, (index) => DateTime.now().year - index), // Generate year list dynamically
            initialSelectedYear: 2024,
            selectedColor: Colors.blue,
            unselectedColor: Colors.grey.shade200,
            selectedTextColor: Colors.white,
            unselectedTextColor: Colors.black,
            onYearSelected: (selectedYear) {
              // Handle year selection
              print("Selected Year: $selectedYear");
            },
          ),
        ],
      )
    );
  }

  Widget buildToggleOption(String text, int index) {
    return GestureDetector(
      onTap: () => controller.onSwitch(index),
      child: Obx(() {
        bool isSelected = controller.selectedIndex.value == index;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.shade900 : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
          ),
        );
      }),
    );
  }
}
