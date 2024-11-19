import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/api/auth/auth_provider.dart';
import 'package:koto_blue_sharks/app/data/api/otp/otp_provider.dart';
import 'package:koto_blue_sharks/app/data/api/userPreferences/notification_preference.dart';
import 'package:koto_blue_sharks/app/data/api/userPreferences/wallpaper_preference.dart';
import 'package:koto_blue_sharks/app/services/AnalyticsService.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/infrastructure/navigation/routes.dart';
import 'package:koto_blue_sharks/utils/my_shared_pref.dart';
import 'package:koto_blue_sharks/utils/utils.dart';

class FanClubConfirmationController extends GetxController {
  final isSelectNotificaiton = true.obs;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController idController = TextEditingController();
  final playerLinkController = "".obs;
  final playerNameController = "".obs;
  final AuthProvider apiProvider = AuthProvider();
  final OtpProvider otpProvider = OtpProvider();

  var isKeyboardVisible = false.obs;


  @override
  void onInit() {
    super.onInit();
    apiProvider.onInit();

    AnalyticsService.logPageView(Routes.FAN_CLUB_CONFIRMATION);

  }

  void updateProfile(Function(String, String, String, String, bool) onSuccess) async {
    // final notification = NotificationPreference();
    // final notificationSetting = isSelectNotificaiton.value ? "active" : "inactive" ;
    // notification.saveNotificationSetting(notificationSetting);

    // final wallpaperPreference = WallpaperPreferences();
    // wallpaperPreference.saveWallpaper(playerNameController.value);
    print("update profile ${playerLinkController.value}");
    MySharedPref.setWallpaper(playerLinkController.value);
    MySharedPref.setWallpaperName(playerNameController.value);
    MySharedPref.setNotification(isSelectNotificaiton.value ? LocaleKeys.active.tr : LocaleKeys.inactive.tr);

    final response = apiProvider.updateProfile(emailController.text, idController.text, "male", (){

    });

    if (response != null) {
      onSuccess(emailController.text, idController.text, playerLinkController.value, playerNameController.value, isSelectNotificaiton.value);
      Get.back();
    }
  }

  void sendOtp(Function(int) onSuccess, bool isRegister, BuildContext context) async {
    otpProvider.onInit();

    final email = emailController.text;

    final response = await otpProvider.requestOtp(email, null, (error){
      Utils.handleErrorOtp(error, context);
    }, isRegister);

    onSuccess(response.id);
  }

  void updateKeyboardVisibility(BuildContext context) {
    isKeyboardVisible.value = MediaQuery.of(context).viewInsets.bottom > 0;
  }
}
