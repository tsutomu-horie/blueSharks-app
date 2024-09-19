import 'package:flutter/material.dart';
import 'package:get/get.dart';

class InfoController extends GetxController {
  var selectedIndex = 0.obs; // Observable to track the selected tab index
  PageController pageController = PageController();

  // Method to change tab
  void changeTab(int index) async {
    // selectedIndex.value = index;
    pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    await Future.delayed(const Duration(milliseconds: 300)); // Add delay of 200ms
    selectedIndex.value = index; // Update selected tab index after the delay
  }

  // Method to handle swipe between pages
  void onPageChanged(int index) {
    selectedIndex.value = index;
  }

}
