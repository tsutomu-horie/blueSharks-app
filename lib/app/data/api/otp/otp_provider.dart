import 'dart:ffi';

import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/models/auth/auth.dart';
import 'package:koto_blue_sharks/app/data/models/otp/otp.dart';
import 'package:koto_blue_sharks/utils/Constant.dart';

class OtpProvider extends GetConnect {
  @override
  void onInit() {
    httpClient.baseUrl = Constants.baseUrlAuthApi;
  }

  Future<Otp> requestOtp(String address, String? otpId, Function(String) onError, bool isRegister) async {
    final url = Uri.parse('otp/send?address=$address&otp_id=$otpId');
    print("load ${httpClient.baseUrl}${url.toString()}");

    final response = await post(
      url.toString(),{
      "is_registered": isRegister,
    }
    );

    print("ertur ${response.body}");

    if (response.hasError) {
      onError("${response.body["errors"]}");
      throw Exception('Failed to login: ${response.statusText}');
    }

    print("Login successful, received data: ${response.body}");

    return Otp.fromJson(response.body["data"]);
  }

  Future<Otp> forgotPasswordOtp(String address, String? otpId,  Function onError) async {
    final url = Uri.parse('forgot-password');
    print("load ${httpClient.baseUrl}${url.toString()}");

    final Map<String, dynamic> body = {
      "address": address,
      "otp_id": otpId,
    };

    final response = await post(
        url.toString(),body
    );

    if (response.hasError) {
      onError();
      throw Exception('Failed to login: ${response.statusText}');
    }

    print("Login successful, received data: ${response.body}");

    return Otp.fromJson(response.body["data"]);
  }

  Future<Response<dynamic>> verifyOtp(String code, String? otpId,  Function(String) onError) async {
    final url = Uri.parse('otp/verify');
    print("load ${httpClient.baseUrl}${url.toString()}");

    final Map<String, dynamic> body = {
      "otp_id": "$otpId",
      "code": code,
    };

    final response = await post(
        url.toString(),body
    );
    print("send data ${body}");
    if (response.hasError) {
      onError("${response.body}");
      throw Exception('Failed to login: ${response.body}');
    }

    print("Login successful, received data: ${response.body}");

    return response;
  }
}
