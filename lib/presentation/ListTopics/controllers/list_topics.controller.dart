import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/api/info/info_provider.dart';
import 'package:koto_blue_sharks/app/data/models/info/post.dart';

class ListTopicsController extends GetxController {
  final InfoProvider apiProvider = InfoProvider();
  final Rx<List<Post>> topicsData = Rx([]);
  PageController pageController = PageController();
  var selectedIndex = 0.obs; // Observable to track the selected tab index

  @override
  void onInit() {
    super.onInit();
    apiProvider.onInit();
    getInfo();
  }

  void getInfo() async {
    print("get info");
    final List<Post> data = await apiProvider.getTopics();

    topicsData.value = data;
  }

  void changeTab(int index) async {
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
