import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/api/otp/otp_provider.dart';
import 'package:koto_blue_sharks/app/services/AnalyticsService.dart';
import 'package:koto_blue_sharks/app/views/views/warning_dialog_view.dart';
import 'package:koto_blue_sharks/infrastructure/navigation/routes.dart';
import 'package:koto_blue_sharks/presentation/forgotPassword/forgot_password.screen.dart';
import 'package:koto_blue_sharks/presentation/register/register_member_fanclub/register_member_fanclub.screen.dart';
import 'package:koto_blue_sharks/presentation/reset_password/reset_password.screen.dart';

class RegisterOtpController extends GetxController {
  final TextEditingController otpController = TextEditingController();
  var otp = ''.obs;
  var otp_id = ''.obs;
  final OtpProvider otpProvider = OtpProvider();

  @override
  void onInit() async {
    super.onInit();
    otpProvider.onInit();

    AnalyticsService.logPageView(Routes.REGISTER_OTP);

  }
  
  void onSubmitOtp(String email, BuildContext context, String fromScreen, String? otpId, String selectedPlayer, String selectedPlayerName, Function? onSuccess) async {
    print(otp.value);
    if (otp.isNotEmpty && otp.value.length > 4) {
      print("isfrom ${fromScreen}");
      if (fromScreen == "register" || fromScreen == "register_home") {
        final response = await otpProvider.verifyOtp(otp.value, otp_id.value, (){
          //todo::display error
          print("error on submit otp ");
        });



        if (response != null) {
          Get.to(() => RegisterMemberFanclubScreen(email: email, otpId: otp_id.value, selectedPlayer: selectedPlayer, selectedPlayerName: selectedPlayerName,));
        }

      } else if (fromScreen == "forgotPassword" || fromScreen == "home" ) {

        final response = await otpProvider.verifyOtp(otp.value, otp_id.value, (){
          //todo::display error
          print("error on submit otp ");
        });



        if (response != null) {
          Get.to(() => ResetPasswordScreen(otp_id.value));
        }


      } else if (fromScreen == "editProfile") {
        Get.back();
      }

      if (onSuccess != null) {
        onSuccess();
      }
    } else {
      WarningDialogView.showWarningDialog(
        context: context,
        title: 'Warning!',
        message: 'This is a warning message.',
      );
    }
  }

  void resendOtp(String email, BuildContext context, String? otpId) async {
    print(otp.value);
    if (otp.isNotEmpty && otp.value.length > 4) {
      final response = await otpProvider.requestOtp(email, otpId,  (){
        //todo::display error
        print("error on submit otp");
      });

      if (response.id != null) {
        otp_id.value = "${response.id}";
      }

    } else {
      WarningDialogView.showWarningDialog(
        context: context,
        title: 'Warning!',
        message: 'This is a warning message.',
      );
    }
  }
}
