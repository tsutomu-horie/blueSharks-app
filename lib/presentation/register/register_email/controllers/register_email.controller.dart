import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/providers/otp/otp_provider.dart';
import 'package:koto_blue_sharks/app/services/analytics_service.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/infrastructure/navigation/routes.dart';
import 'package:koto_blue_sharks/presentation/main/main.screen.dart';
import 'package:koto_blue_sharks/utils/my_shared_pref.dart';
import 'package:koto_blue_sharks/utils/utils.dart';

class RegisterEmailController extends GetxController {
  final textFieldController = TextEditingController();
  final OtpProvider otpProvider = OtpProvider();

  @override
  void onInit() async {
    super.onInit();
    otpProvider.onInit();

    AnalyticsService.logPageView(Routes.REGISTER_EMAIL);

  }

  void sendOtp(Function(int) onSuccess, BuildContext context) async {
    final email = textFieldController.text;

      final response = await otpProvider.requestOtp(email, null, (error){
        Utils.handleErrorOtp(error, context);
      },true);

      print("response ${response}");
      onSuccess(response.id);
  }

  void setWallpaper(String selectedPlayer, String playerName){
    MySharedPref.setWallpaper(selectedPlayer);
    MySharedPref.setFirstOpen("alreadyOpen");
    MySharedPref.setWallpaperName(playerName);

    print("set wallpaper link ${selectedPlayer}");
    Get.offAll(() => const MainScreen());
  }
}
