import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/api/auth/AuthToken.dart';
import 'package:koto_blue_sharks/app/data/api/auth/auth_provider.dart';
import 'package:koto_blue_sharks/app/data/api/userPreferences/wallpaper_preference.dart';
import 'package:koto_blue_sharks/app/data/models/auth/auth.dart';
import 'package:koto_blue_sharks/app/services/AnalyticsService.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/infrastructure/navigation/routes.dart';
import 'package:koto_blue_sharks/presentation/main/main.screen.dart';
import 'package:koto_blue_sharks/utils/fcm_helper.dart';
import 'package:koto_blue_sharks/utils/my_shared_pref.dart';
import 'package:koto_blue_sharks/utils/utils.dart';

class LoginController extends GetxController {
  final AuthProvider apiProvider = AuthProvider();

  final emailTextFieldController = TextEditingController();
  final passwordTextFieldController = TextEditingController();

  final isLoadingLogin = false.obs;

  var isPasswordHidden = true.obs;


  @override
  void onInit() async {
    super.onInit();
    apiProvider.onInit();

    AnalyticsService.logPageView(Routes.LOGIN);

  }

  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  void login(BuildContext context, String selectedPlayer, String selectedPlayerName, bool isFromHome) async {
    isLoadingLogin.value = true; // Start loading

    try {
      print("before get data");
      final response = await apiProvider.login(
          emailTextFieldController.text,
          passwordTextFieldController.text,
          (){
            Utils.showError(context, "メールアドレスまたはIDが確認できませんでした。ご登録情報を再度ご確認ください", "ファンクラブ会員情報の更新には最大12時間かかります。ご登録情報が正しい場合には、しばらくしてから再度会員連携を行ってください。");
          },
      );


      if (response.access_token.isNotEmpty) {
        // Process successful login
        AuthToken storage = AuthToken();
        await storage.saveAccessToken(response.access_token);

        // WallpaperPreferences wallpaper = WallpaperPreferences();
        // await wallpaper.saveWallpaper(selectedPlayer);
        MySharedPref.setWallpaper(selectedPlayer);
        MySharedPref.setWallpaperName(selectedPlayerName);


        print("get data ${selectedPlayer})");
        await FcmHelper.initFcm();
        MySharedPref.setFirstOpen("alreadyOpen");

        if (!isFromHome) {
          Get.offAll(() => const MainScreen());
        } else {
          Get.back(result: true);
        }
      }
    } catch (e) {
      print("catch $e");
    } finally {
      isLoadingLogin.value = false; // End loading
    }
  }

}
