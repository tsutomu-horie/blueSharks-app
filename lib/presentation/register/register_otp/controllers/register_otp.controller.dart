import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/views/views/warning_dialog_view.dart';
import 'package:koto_blue_sharks/presentation/register/register_member_fanclub/register_member_fanclub.screen.dart';

class RegisterOtpController extends GetxController {
  final TextEditingController otpController = TextEditingController();
  var otp = ''.obs;
  
  void onSubmitOtp(String email, BuildContext context) {
    print(otp.value);
    if (otp.isNotEmpty && otp.value.length > 5) {
      Get.to(() => RegisterMemberFanclubScreen(email: email,));
    } else {
      WarningDialogView.showWarningDialog(
        context: context,
        title: 'Warning!',
        message: 'This is a warning message.',
      );
    }
  }
}
