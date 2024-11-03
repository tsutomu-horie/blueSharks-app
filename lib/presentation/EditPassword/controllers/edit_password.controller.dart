import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/presentation/reset_password/controllers/reset_password.controller.dart';

class EditPasswordController extends ResetPasswordController {
  var isCurrentPasswordHidden = true.obs;

  final currentPassword = TextEditingController();

}
