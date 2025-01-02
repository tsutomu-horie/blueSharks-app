import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/api/auth/auth_provider.dart';
import 'package:koto_blue_sharks/app/services/analytics_service.dart';
import 'package:koto_blue_sharks/infrastructure/navigation/routes.dart';
import 'package:koto_blue_sharks/presentation/register/reset_password/controllers/reset_password.controller.dart';
import 'package:koto_blue_sharks/utils/utils.dart';

class EditPasswordController extends ResetPasswordController {
  var isCurrentPasswordHidden = true.obs;
  final AuthProvider apiProvider = AuthProvider();

  final currentPassword = TextEditingController();

  final isLoadingUpdate = false.obs;

  @override
  void onInit() {
    super.onInit();
    AnalyticsService.logPageView(Routes.EDIT_PASSWORD);

    apiProvider.onInit();
  }

  void onUpdatePassword(BuildContext context, Function onSuccess) async {
    isLoadingUpdate.value = true;
    final result = await apiProvider.updatePassword(currentPassword.text, confirmNewPasswordController.text, newPasswordController.text, (title, message){
      print("error update password");
      isLoadingUpdate.value = false;
      Utils.showError(context, "", message);
    });


    onSuccess();
    isLoadingUpdate.value = false;
    print("finisss");

  }

}
