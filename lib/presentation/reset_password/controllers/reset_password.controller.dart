import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/api/auth/auth_provider.dart';
import 'package:koto_blue_sharks/app/services/AnalyticsService.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/infrastructure/navigation/routes.dart';
import 'package:koto_blue_sharks/utils/utils.dart';

class ResetPasswordController extends GetxController {
  final newPasswordController = TextEditingController();
  final confirmNewPasswordController = TextEditingController();

  var isOldPasswordHidden = true.obs;
  var isNewPasswordHidden = true.obs;

  final AuthProvider apiProvider = AuthProvider();

  @override
  void onInit() async {
    super.onInit();
    print("on init");
    apiProvider.onInit();

    AnalyticsService.logPageView(Routes.RESET_PASSWORD);

  }

  // void togglePasswordVisibility() {
  //   isPasswordHidden.value = !isPasswordHidden.value;
  // }

  void resetPassword(BuildContext context,String otpId) async {
    apiProvider.onInit();

    try {
      print("before get data");
      final response = await apiProvider.resetPassword(otpId, newPasswordController.text, confirmNewPasswordController.text, (){
        //todo:: change error message
        Utils.showError(context, LocaleKeys.error_login_message.tr, null );
      });

      if (!response.hasError) {
        Get.back();
        Get.back();
        Get.back();
      }
      // final response = await apiProvider.login(
      //   emailTextFieldController.text,
      //   passwordTextFieldController.text,
      //       (){
      //     Utils.showError(context, LocaleKeys.error_login_message.tr, null );
      //   },
      // );

      print("get data");

    } catch (e) {
      print("catch $e");
    } finally {
      // isLoadingLogin.value = false; // End loading
    }
  }
}
