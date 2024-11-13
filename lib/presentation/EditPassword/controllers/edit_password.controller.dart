import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/services/AnalyticsService.dart';
import 'package:koto_blue_sharks/infrastructure/navigation/routes.dart';
import 'package:koto_blue_sharks/presentation/reset_password/controllers/reset_password.controller.dart';

class EditPasswordController extends ResetPasswordController {
  var isCurrentPasswordHidden = true.obs;

  final currentPassword = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    AnalyticsService.logPageView(Routes.EDIT_PASSWORD);

  }

}
