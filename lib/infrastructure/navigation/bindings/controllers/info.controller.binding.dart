import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MenuControllerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MenuController>(
      () => MenuController(),
    );
  }
}
