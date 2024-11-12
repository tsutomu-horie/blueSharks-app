import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/views/views/custom_text_view.dart';

class YearFilterController extends GetxController {
  // Observable to keep track of the selected year
  final selectedYear = 0.obs;

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
  })
  {
    // yearController.selectedYear.value = initialSelectedYear;
  }

  @override
  Widget build(BuildContext context) {

    return SizedBox(
      height: 32.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: years.length,
        itemBuilder: (context, index) {
          final year = years[index];
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.h),
            child: GestureDetector(
              onTap: () {
                print("selec $year");
                yearController.selectYear(year);
                if (onYearSelected != null) {
                  onYearSelected!(year);
                }
              },
              child: Obx(() =>
                  Container( // Wrap Container with Obx
                    padding: EdgeInsets.symmetric(
                        horizontal: 16.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: yearController.selectedYear.value == year &&
                          yearController.selectedYear.value != 0
                          ? selectedColor
                          : unselectedColor,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: CustomTextView(
                      "$year年",
                      type: TDSFontType.labelLarge,
                      color: yearController.selectedYear.value == year &&
                          yearController.selectedYear.value != 0
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
