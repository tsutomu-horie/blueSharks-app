import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/api/auth/AuthToken.dart';
import 'package:koto_blue_sharks/app/data/api/auth/auth_provider.dart';
import 'package:koto_blue_sharks/app/data/api/userPreferences/wallpaper_preference.dart';
import 'package:koto_blue_sharks/presentation/FanClubConfirmation/fan_club_confirmation.screen.dart';

class RegisterMemberFanclubController extends GetxController {
  final idTextFieldController = TextEditingController();
  final passwordTextFieldController = TextEditingController();
  final AuthProvider apiProvider = AuthProvider();

  var isPasswordHidden = true.obs;

  @override
  void onInit() async {
    super.onInit();
    apiProvider.onInit();
  }

  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  void onRegister(String otpId, String email, Function showError, Function showSuccess, String playerName) async {
    print("onRrror");
    final response = await apiProvider.register(idTextFieldController.text, email, otpId, passwordTextFieldController.text, (String errorText){
      showError();
    });

    AuthToken storage = AuthToken();
    await storage.saveAccessToken(response.access_token);

    WallpaperPreferences wallpaper = WallpaperPreferences();
    await wallpaper.saveWallpaper(playerName);

    Get.offAll(() => FanClubConfirmationScreen(email: email, id: idTextFieldController.text, isNotification: true, playerSelected: playerName,));
    // showSuccess();
  }

}
