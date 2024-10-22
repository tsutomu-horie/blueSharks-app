import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/models/auth/auth.dart';
import 'package:koto_blue_sharks/app/data/models/otp/otp.dart';
import 'package:koto_blue_sharks/utils/Constant.dart';

class OtpProvider extends GetConnect {
  @override
  void onInit() {
    httpClient.baseUrl = Constants.baseUrlAuthApi;
  }

  Future<Otp> requestOtp(String address, String? otpId,  Function onError) async {
    final url = Uri.parse('otp/send?address=$address&otp_id=$otpId');
    print("load ${httpClient.baseUrl}${url.toString()}");

    final response = await post(
      url.toString(),{}
    );

    if (response.hasError) {
      onError();
      throw Exception('Failed to login: ${response.statusText}');
    }

    print("Login successful, received data: ${response.body}");

    return Otp.fromJson(response.body["data"]);
  }

  Future<Response<dynamic>> verifyOtp(String code, String? otpId,  Function onError) async {
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
      onError();
      throw Exception('Failed to login: ${response.statusText}');
    }

    print("Login successful, received data: ${response.body}");

    return response;
  }
}
