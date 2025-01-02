import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/api/auth/AuthToken.dart';
import 'package:koto_blue_sharks/app/data/api/auth/auth_provider.dart';
import 'package:koto_blue_sharks/app/services/analytics_service.dart';
import 'package:koto_blue_sharks/infrastructure/navigation/routes.dart';
import 'package:koto_blue_sharks/presentation/main/controllers/main.controller.dart';
import 'package:koto_blue_sharks/utils/my_shared_pref.dart';
import 'package:koto_blue_sharks/utils/utils.dart';
import 'package:koto_blue_sharks/presentation/screens.dart';

class RegisterMemberFanclubController extends GetxController {
  final idTextFieldController = TextEditingController();
  final passwordTextFieldController = TextEditingController();
  final AuthProvider apiProvider = AuthProvider();

  var isPasswordHidden = true.obs;

  @override
  void onInit() async {
    super.onInit();
    apiProvider.onInit();

    AnalyticsService.logPageView(Routes.REGISTER_MEMBER_FANCLUB);

  }

  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  void onRegister(String otpId, String email, Function showError, Function showSuccess, String playerLink, String playerName, BuildContext context, bool isFromHome) async {
    print("set wallpaper ${playerLink}");
    final response = await apiProvider.register(idTextFieldController.text, email, otpId, passwordTextFieldController.text, (String errorText){
      Utils.showError(context, "Something wrong", errorText);
    });

    AuthToken storage = AuthToken();
    await storage.saveAccessToken(response.access_token);

    // WallpaperPreferences wallpaper = WallpaperPreferences();
    // await wallpaper.saveWallpaper(playerName);
    MySharedPref.setWallpaper(playerLink);
    MySharedPref.setWallpaperName(playerName);

    Utils.showCustomSuccessRegisterDialog(context, () {
      if (!isFromHome) {
        Get.offAll(() => FanClubConfirmationScreen(
              email: email,
              id: idTextFieldController.text,
              isNotification: true,
              playerSelected: playerLink,
              playerSelectedName: playerName,
              isFromHome: false,
            ));
      } else {
        Get.offAll(() => const MainScreen(initialTab: 2));

        final mainController = Get.find<MainController>();
        mainController.refreshUnreadMessageCount();
      }
    });

    // showSuccess();
  }

}
