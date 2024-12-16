import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/views/views/custom_text_view.dart';

class YearFilterController extends GetxController {
  // Observable to keep track of the selected year
  final selectedYear = 0.obs;

  // Add a method to check if "ALL" is selected
  bool get isAllSelected => selectedYear.value == 0;

  void reset() {
    selectedYear.value = 0;
  }

  // Update the selected year
  void selectYear(int year) {
    print("selectYear = $year");
    selectedYear.value = year;
  }
}

class YearFilter extends StatelessWidget {
  final YearFilterController yearController = Get.put(YearFilterController());

  final List<int> years; // List of years to display
  final int initialSelectedYear; // The initially selected year
  final void Function(int)? onYearSelected; // Callback when a year is selected
  final Color selectedColor;
  final Color unselectedColor;
  final Color selectedTextColor;
  final Color unselectedTextColor;

  YearFilter({
    super.key,
    required this.years,
    required this.initialSelectedYear,
    this.onYearSelected,
    this.selectedColor = Colors.blue,
    this.unselectedColor = Colors.grey,
    this.selectedTextColor = Colors.white,
    this.unselectedTextColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        // Add 1 to itemCount for "ALL" option
        itemCount: years.length + 1,
        itemBuilder: (context, index) {
          // Handle "ALL" option at index 0
          if (index == 0) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.h),
              child: GestureDetector(
                onTap: () {
                  yearController.reset(); // Reset to 0 for "ALL"
                  if (onYearSelected != null) {
                    onYearSelected!(0);
                  }
                },
                child: Obx(() => Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 6.h
                  ),
                  decoration: BoxDecoration(
                    color: yearController.isAllSelected
                        ? selectedColor
                        : unselectedColor,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: CustomTextView(
                    "ALL",
                    type: TDSFontType.labelLarge,
                    color: yearController.isAllSelected
                        ? selectedTextColor
                        : unselectedTextColor,
                  ),
                )),
              ),
            );
          }

          // Handle year options
          final year = years[index - 1]; // Adjust index for years array
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.h),
            child: GestureDetector(
              onTap: () {
                print("select $year");
                yearController.selectYear(year);
                if (onYearSelected != null) {
                  onYearSelected!(year);
                }
              },
              child: Obx(() => Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 6.h
                ),
                decoration: BoxDecoration(
                  color: yearController.selectedYear.value == year
                      ? selectedColor
                      : unselectedColor,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: CustomTextView(
                  "$year年",
                  type: TDSFontType.labelLarge,
                  color: yearController.selectedYear.value == year
                      ? selectedTextColor
                      : unselectedTextColor,
                ),
              )),
            ),
          );
        },
      ),
    );
  }
}