import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/api/otp/otp_provider.dart';

class RegisterEmailController extends GetxController {
  final textFieldController = TextEditingController();
  final OtpProvider otpProvider = OtpProvider();

  @override
  void onInit() async {
    super.onInit();
    otpProvider.onInit();
  }

  void sendOtp(Function(int) onSuccess) async {
    final email = textFieldController.text;

      final response = await otpProvider.requestOtp(email, null, (){
        //todo::display error
        print("error on submit otp");
      });

      onSuccess(response.id);


  }
}
