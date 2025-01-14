import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/models/auth/auth.dart';
import 'package:koto_blue_sharks/app/providers/auth/auth_provider.dart';
import 'package:koto_blue_sharks/app/providers/otp/otp_provider.dart';
import 'package:koto_blue_sharks/app/services/analytics_service.dart';
import 'package:koto_blue_sharks/app/services/auth_token.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/infrastructure/navigation/routes.dart';
import 'package:koto_blue_sharks/utils/Constant.dart';
import 'package:koto_blue_sharks/utils/my_shared_pref.dart';
import 'package:koto_blue_sharks/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class FanClubConfirmationController extends GetxController {
  final isSelectNotificaiton = true.obs;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController idController = TextEditingController();
  final playerLinkController = "".obs;
  final playerNameController = "".obs;
  final AuthProvider apiProvider = AuthProvider();
  final OtpProvider otpProvider = OtpProvider();

  var isKeyboardVisible = false.obs;
  final Rx<UserData?> profileData = Rx<UserData?>(null);
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    apiProvider.onInit();

    AnalyticsService.logPageView(Routes.FAN_CLUB_CONFIRMATION);

    getProfile();
  }

  void refreshProfile() async {
    final auth = AuthToken();
    final token = await auth.getAccessToken();

    print("response token = $token");
    if (token != null) {
      final response = await apiProvider.refreshProfile(token, () {
        print("error get profile ");
      });

      profileData.value = response;
      isSelectNotificaiton.value = response.isNotification ?? true;

          print("finish profile ${response}");
      isLoading.value = false;
    }
  }

  void getProfile() async {
    final auth = AuthToken();
    final token = await auth.getAccessToken();

    if (token != null) {
      print("response token = $token");
      final response = await apiProvider.getProfile(token, () {
        print("error get profile ");
      });

      profileData.value = response;
      isSelectNotificaiton.value = response.isNotification ?? true;

      print("finish profile ${response}");
      isLoading.value = false;
    }
  }

  void updateProfile(Function(String, String, String, String, bool) onSuccess) async {
    MySharedPref.setWallpaper(playerLinkController.value);
    MySharedPref.setWallpaperName(playerNameController.value);
    // MySharedPref.setNotification(isSelectNotificaiton.value ? LocaleKeys.active.tr : LocaleKeys.inactive.tr);
    print("isSelect notif ${isSelectNotificaiton.value}");
    final response = apiProvider.updateProfile(emailController.text, idController.text, "male", (){

    }, isSelectNotificaiton.value);

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

  void launchFanClub(){
    launchExternalWeb(Constants.fanClubUrl);
  }

  void launchExternalWeb(String url) async {
    final Uri webUrl = Uri.parse(url); // Replace with your profile URL
    if (await canLaunchUrl(webUrl)) {
      await launchUrl(webUrl);
    } else {
      throw 'Could not launch $webUrl';
    }
  }
}
