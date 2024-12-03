import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/api/otp/otp_provider.dart';
import 'package:koto_blue_sharks/app/services/AnalyticsService.dart';
import 'package:koto_blue_sharks/app/views/views/warning_dialog_view.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/infrastructure/navigation/routes.dart';
import 'package:koto_blue_sharks/presentation/forgotPassword/forgot_password.screen.dart';
import 'package:koto_blue_sharks/presentation/register/register_member_fanclub/register_member_fanclub.screen.dart';
import 'package:koto_blue_sharks/presentation/reset_password/reset_password.screen.dart';
import 'package:koto_blue_sharks/utils/utils.dart';

class RegisterOtpController extends GetxController {
  final TextEditingController otpController = TextEditingController();
  var otp = ''.obs;
  var otp_id = ''.obs;
  var hasError = false.obs;
  final OtpProvider otpProvider = OtpProvider();

  RxInt resendAttempts = 0.obs;
  RxInt timerSeconds = 30.obs;
  RxBool canResend = false.obs;
  Timer? _timer;

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  @override
  void onInit() async {
    super.onInit();
    otpProvider.onInit();
    startResendTimer();

    AnalyticsService.logPageView(Routes.REGISTER_OTP);

  }

  String get formattedTime {
    int minutes = timerSeconds.value ~/ 60;
    int seconds = timerSeconds.value % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void onSubmitOtp(String email, BuildContext context, String fromScreen, String? otpId, String selectedPlayer, String selectedPlayerName, Function? onSuccess, bool isRegister) async {
    print(otp.value);
    if (otp.isNotEmpty && otp.value.length > 4) {
      print("isfrom ${fromScreen}");
      if (fromScreen == "register" || fromScreen == "register_home") {
        final response = await otpProvider.verifyOtp(otp.value, otp_id.value, (errorMessage){
          var newMessage = "";
          //todo:: move to localization
          if (errorMessage.contains("verify_otp")) {
            newMessage = "入力したOTPコードが間違っています。もう一度お試しください。";
          } else if (errorMessage.contains("otp_max_limit")) {
            newMessage = "OTPの送信回数が多すぎる。";
          } else {
            newMessage = "メール送信エラー。\nしばらくしてから再度メールを送信してください。";
          }

          Utils.showError(context, "", newMessage);

          print("error on submit otp ");
        });



        if (response != null) {
          Get.to(() => RegisterMemberFanclubScreen(email: email, otpId: otp_id.value, selectedPlayer: selectedPlayer, selectedPlayerName: selectedPlayerName, isFromHome: fromScreen == "register_home",),);
        }

      } else if (fromScreen == "forgotPassword" || fromScreen == "home" || fromScreen == "forgotPasswordHome" ) {

        final response = await otpProvider.verifyOtp(otp.value, otp_id.value, (errorMessage){
          var newMessage = "";
          if (errorMessage.contains("verify_otp")) {
            newMessage = "送信されたOTPが正しくありません。";
          } else if (errorMessage.contains("otp_max_limit")) {
            newMessage = "OTPの送信回数が多すぎる。";
          } else {
            newMessage = "メール送信エラー。\nしばらくしてから再度メールを送信してください。";
          }

          Utils.showError(context, "", newMessage);

          print("error on submit otp ");
        });

        if (response != null) {
          Get.to(() => ResetPasswordScreen(otp_id.value, isFromHome: fromScreen == "forgotPasswordHome" ? true : false,));
        }


      } else if (fromScreen == "editProfile") {
        final response = await otpProvider.verifyOtp(otp.value, otp_id.value, (errorMessage){
          var newMessage = "";
          //todo:: move to localization
          if (errorMessage.contains("verify_otp")) {
            newMessage = "入力したOTPコードが間違っています。もう一度お試しください。";
          } else if (errorMessage.contains("otp_max_limit")) {
            newMessage = "OTPの送信回数が多すぎる。";
          } else {
            newMessage = "メール送信エラー。\nしばらくしてから再度メールを送信してください。";
          }

          Utils.showError(context, "", newMessage);

          print("error on submit otp ");
        });

        if (response != null) {
          Get.back();
          if (onSuccess != null) {
              onSuccess();
          }
        }
      }

      if (onSuccess != null) {
        if (fromScreen != "editProfile") {
          onSuccess();
        }
      }
    } else {
      hasError.value = true;
      Utils.showError(
          context,
          "",  // Empty title as per your utils pattern
          "OTPコードを入力してください。"  // Please enter OTP code in Japanese
      );
    }
  }

  void resendOtp(String email, BuildContext context, String? otpId, bool isRegister) async {
    final response = await otpProvider.requestOtp(email, otpId,  (error){
      Utils.handleErrorOtp(error, context);
    }, isRegister);

    otp_id.value = "${response.id}";
    }

  void startResendTimer() {
    canResend.value = false;
    timerSeconds.value = 30;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timerSeconds.value > 0) {
        timerSeconds.value--;
      } else {
        timer.cancel();
        canResend.value = true;
      }
    });
  }

  void handleResendOtp(String email, BuildContext context, String? otpId, bool isRegister) {
    if (resendAttempts.value >= 3) {
      // Show dialog for 1-minute cooldown
      Utils.showError(context, LocaleKeys.otp_limit_title.tr, LocaleKeys.otp_limit_message.tr);
      Future.delayed(const Duration(minutes: 1), () {
        resendAttempts.value = 0;
        canResend.value = true;
      });
    } else {
      resendAttempts.value++;
      resendOtp(email, context, otpId, isRegister);
      startResendTimer();
    }
  }
}
