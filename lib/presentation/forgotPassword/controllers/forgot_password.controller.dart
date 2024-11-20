import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/api/otp/otp_provider.dart';
import 'package:koto_blue_sharks/app/services/AnalyticsService.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/infrastructure/navigation/routes.dart';
import 'package:koto_blue_sharks/presentation/register/register_otp/register_otp.screen.dart';
import 'package:koto_blue_sharks/presentation/reset_password/reset_password.screen.dart';
import 'package:koto_blue_sharks/utils/utils.dart';

class ForgotPasswordController extends GetxController {
  final isLoadingLogin = false.obs;
  final OtpProvider otpProvider = OtpProvider();

  final emailTextFieldController = TextEditingController();
  final Rx<int>? otpId = null;

  @override
  void onInit() async {
    super.onInit();
    otpProvider.onInit();

    AnalyticsService.logPageView(Routes.FORGOT_PASSWORD);

  }

  void sendOtp(BuildContext context, String selectedPlayer, String selectedPlayerName, bool isFromHome) async {
    final email = emailTextFieldController.text;

    print("send ${email}");
    final response = await otpProvider.requestOtp(email, "${otpId?.value}", (error){
      Utils.showError(context, LocaleKeys.error_login_message.tr, null );
    }, false);

    Get.to(() => RegisterOtpScreen(email: email, fromScreen: isFromHome ? "forgotPasswordHome" : "forgotPassword", otpId: "${response.id}", selectedPlayer: selectedPlayer, selectedPlayerName: selectedPlayerName, isRegister: false,));
  }
}
