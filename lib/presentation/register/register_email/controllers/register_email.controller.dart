import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/api/otp/otp_provider.dart';
import 'package:koto_blue_sharks/app/services/AnalyticsService.dart';
import 'package:koto_blue_sharks/infrastructure/navigation/routes.dart';
import 'package:koto_blue_sharks/presentation/main/main.screen.dart';
import 'package:koto_blue_sharks/utils/my_shared_pref.dart';

class RegisterEmailController extends GetxController {
  final textFieldController = TextEditingController();
  final OtpProvider otpProvider = OtpProvider();

  @override
  void onInit() async {
    super.onInit();
    otpProvider.onInit();

    AnalyticsService.logPageView(Routes.REGISTER_EMAIL);

  }

  void sendOtp(Function(int) onSuccess) async {
    final email = textFieldController.text;

      final response = await otpProvider.requestOtp(email, null, (){
        //todo::display error
        print("error on submit otp");
      });

      onSuccess(response.id);
  }

  void setWallpaper(String selectedPlayer, String playerName){
    MySharedPref.setWallpaper(selectedPlayer);
    MySharedPref.setWallpaperName(playerName);
    Get.offAll(() => const MainScreen());
  }
}
