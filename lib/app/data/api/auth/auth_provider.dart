import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/models/auth/auth.dart';
import 'package:koto_blue_sharks/utils/Constant.dart';

class AuthProvider extends GetConnect {
  @override
  void onInit() {
    httpClient.baseUrl = Constants.baseUrlAuthApi;
  }

  Future<Auth> login(String username, String password, Function() onError) async {
    final url = Uri.parse('login');
    print("load ${httpClient.baseUrl}${url.toString()}");

    final Map<String, dynamic> body = {
      "email": username,
      "password": password,
    };

    final response = await post(
      url.toString(), body, // Send the body in the request
    );

    print("Login successful2 , ${response.body}");

    if (response.hasError) {
      onError();
      throw Exception('Failed to login: ${response.statusText}');
    }

    print("Login successful, received data: ${response.body}");

    return Auth.fromJson(response.body["data"]);
  }

  Future<Auth> register(String acountId, String email, String otpId, String password, Function(String) onError) async {
    final url = Uri.parse('register');
    print("load ${httpClient.baseUrl}${url.toString()}");

    final Map<String, dynamic> body = {
      "account_id": acountId,
      "email": email,
      "otp_id": otpId,
      "password": password,
    };

    final response = await post(
      url.toString(), body, // Send the body in the request
    );

    print("Login successful2 , ${response.body}");

    if (response.hasError) {
      onError("${response.statusText}");
      throw Exception('Failed to login: ${response.statusText}');
    }

    print("Login successful, received data: ${response.body}");

    return Auth.fromJson(response.body["data"]);
  }

  Future<Response> resetPassword(String otpId, String password, String passwordConfirmation,Function onError) async {
    final url = Uri.parse('reset-password');
    print("load ${httpClient.baseUrl}${url.toString()}");

    final Map<String, dynamic> body = {
      "otp_id": otpId,
      "password": password,
      "password_confirmation": passwordConfirmation,
    };

    final response = await post(
      url.toString(), body, // Send the body in the request
    );

    print("Login successful2 , ${response.body}");

    if (response.hasError) {
      onError();
      throw Exception('Failed to login: ${response.statusText}');
    }

    print("Login successful, received data: ${response.body}");

    return response;
  }

  Future<UserData> getProfile(String token, Function onError) async {
    final url = Uri.parse('profile');
    print("load ${httpClient.baseUrl}${url.toString()}");

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json', // Optional, depending on the API
    };

    final response = await get(
      url.toString(), headers: headers // Send the body in the request
    );

    print("Login successful2 , ${response.body}");

    if (response.hasError) {
      onError();
      throw Exception('Failed to login: ${response.statusText}');
    }

    print("Login successful, received data: ${response.body}");

    return UserData.fromJson(response.body["data"]);
    return UserData.fromJson(response.body["data"]);
  }


}
