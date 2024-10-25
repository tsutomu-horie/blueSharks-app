import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FanClubConfirmationController extends GetxController {
  final isSelectNotificaiton = true.obs;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController idController = TextEditingController();
  final TextEditingController playerNameController = TextEditingController();

  void updateProfile() async {
    //todo:: update profile

    Get.back();
  }
}
