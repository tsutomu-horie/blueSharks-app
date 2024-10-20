import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/views/views/other/views/error_dialog_view.dart';

class Utils {
  static void showError(BuildContext context, String title, String? message) {
    errorDialogView(context, title, message);
    print("error with ${title} , ${message}");
  }
}