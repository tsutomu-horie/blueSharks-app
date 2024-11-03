import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/api/auth/auth_provider.dart';
import 'package:koto_blue_sharks/app/data/api/otp/otp_provider.dart';
import 'package:koto_blue_sharks/app/data/api/userPreferences/notification_preference.dart';
import 'package:koto_blue_sharks/app/data/api/userPreferences/wallpaper_preference.dart';

class FanClubConfirmationController extends GetxController {
  final isSelectNotificaiton = true.obs;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController idController = TextEditingController();
  final playerNameController = "".obs;
  final AuthProvider apiProvider = AuthProvider();
  final OtpProvider otpProvider = OtpProvider();


  @override
  void onInit() {
    super.onInit();
    apiProvider.onInit();
  }

  void updateProfile(Function(String, String, String, bool) onSuccess) async {
    final notification = NotificationPreference();
    final notificationSetting = isSelectNotificaiton.value ? "active" : "inactive" ;
    notification.saveNotificationSetting(notificationSetting);

    final wallpaperPreference = WallpaperPreferences();
    wallpaperPreference.saveWallpaper(playerNameController.value);

    final response = apiProvider.updateProfile(emailController.text, idController.text, "male", (){

    });

    if (response != null) {
      onSuccess(emailController.text, idController.text, playerNameController.value, isSelectNotificaiton.value);
      Get.back();
    }
  }

  void sendOtp(Function(int) onSuccess) async {
    otpProvider.onInit();

    final email = emailController.text;

    final response = await otpProvider.requestOtp(email, null, (){
      //todo::display error
      print("error on submit otp");
    });

    onSuccess(response.id);
  }
}
