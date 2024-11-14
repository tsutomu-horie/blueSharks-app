import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/api/auth/AuthToken.dart';
import 'package:koto_blue_sharks/app/data/api/auth/auth_provider.dart';
import 'package:koto_blue_sharks/presentation/splash/splash.screen.dart';

class DeleteAccountConfirmationController extends GetxController {
  final emailTextFieldController = TextEditingController();
  final emailText = "".obs;
  final AuthProvider apiProvider = AuthProvider();

  void onDeleteAccount() async {
    apiProvider.onInit();
    final auth = AuthToken();
    final token = await auth.getAccessToken();


    print("response token = $token");
    final response = await apiProvider.deleteProfile(token!, (){
      print("error get profile ");
    });

    await auth.deleteToken();
    Get.offAll(() => const SplashScreen());
  }
}
