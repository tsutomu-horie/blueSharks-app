import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/services/analytics_service.dart';
import 'package:koto_blue_sharks/infrastructure/navigation/routes.dart';
import 'package:koto_blue_sharks/presentation/register/register_email/controllers/register_email.controller.dart';

class RegisterEmailFromHomeController extends RegisterEmailController {
  final textFieldController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    AnalyticsService.logPageView(Routes.REGISTER_EMAIL);

  }
}
