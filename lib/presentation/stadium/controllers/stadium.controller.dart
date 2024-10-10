import 'package:flutter/material.dart';
import 'package:get/get.dart';

class StadiumController extends GetxController {
  final ScrollController scrollController = ScrollController();

  // Method to scroll to specific position
  void scrollToPosition(double position) {
    scrollController.animateTo(
      position,
      duration: Duration(seconds: 1),
      curve: Curves.easeInOut,
    );
  }

  // Method to scroll to specific widget with GlobalKey
  void scrollToWidget(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: Duration(seconds: 1),
        curve: Curves.easeInOut,
      );
    }
  }
}
