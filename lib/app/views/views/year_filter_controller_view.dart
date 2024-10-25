import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/views/views/custom_text_view.dart';

class YearFilterController extends GetxController {
  // Observable to keep track of the selected year
  var selectedYear = 2024.obs;

  // Update the selected year
  void selectYear(int year) {
    selectedYear.value = year;
  }
}

class YearFilter extends StatelessWidget {
  final YearFilterController controller = Get.put(YearFilterController());

  final List<int> years; // List of years to display
  final int initialSelectedYear; // The initially selected year
  final void Function(int)? onYearSelected; // Callback when a year is selected
  final Color selectedColor;
  final Color unselectedColor;
  final Color selectedTextColor;
  final Color unselectedTextColor;

  YearFilter({
    Key? key,
    required this.years,
    required this.initialSelectedYear,
    this.onYearSelected,
    this.selectedColor = Colors.blue,
    this.unselectedColor = Colors.grey,
    this.selectedTextColor = Colors.white,
    this.unselectedTextColor = Colors.black,
  }) : super(key: key) {
    controller.selectedYear.value = initialSelectedYear;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: years.length,
        itemBuilder: (context, index) {
          final year = years[index];
          final bool isSelected = controller.selectedYear.value == year;

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: GestureDetector(
              onTap: () {
                controller.selectYear(year);
                if (onYearSelected != null) {
                  onYearSelected!(year); // Trigger the callback
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: isSelected ? selectedColor : unselectedColor,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: CustomTextView(
                  "$year年",
                  type: TDSFontType.labelLarge,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
