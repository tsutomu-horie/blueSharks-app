import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/api/auth/AuthToken.dart';
import 'package:koto_blue_sharks/app/data/models/auth/auth.dart';
import 'package:koto_blue_sharks/app/data/models/info/notification.dart';
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

  Future<Response> updateProfile(String email, String accountId, String gender,Function onError) async {
    final url = Uri.parse('profile');
    print("load ${httpClient.baseUrl}${url.toString()}");

    final auth = AuthToken();
    final token = await auth.getAccessToken();

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json', // Optional, depending on the API
    };

    final Map<String, dynamic> body = {
      "email": email,
      "account_id": accountId,
      "gender": "male",
    };

    final response = await patch(
      url.toString(), body, headers: headers // Send the body in the request
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
  }

  Future<Response?> updateNotificationToken(String fcm) async {
    httpClient.baseUrl = Constants.baseUrlAuthApi;

    final url = Uri.parse('notifications/create-fcm');
    print("load ${httpClient.baseUrl}${url.toString()}");

    final auth = AuthToken();
    final token = await auth.getAccessToken();

    if (token != null) {
      final Map<String, dynamic> body = {
        "fcm_token": fcm,
      };

      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json', // Optional, depending on the API
      };

      final response = await post(
          url.toString(), body, headers: headers // Send the body in the request
      );

      print("Login successful2 , ${response.body}");

      if (response.hasError) {
        throw Exception('Failed to send fcm token: ${response.statusText}');
      }

      print("Login successful, received data: ${response}");

      return response;
    } else {
      return null;
    }
  }

  Future<List<Notification>> getNotificationList() async {
    httpClient.baseUrl = Constants.baseUrlAuthApi;

    final url = Uri.parse('notifications');
    print("load ${httpClient.baseUrl}${url.toString()}");

    final auth = AuthToken();
    final token = await auth.getAccessToken();

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json', // Optional, depending on the API
    };

    final response = await get(
        url.toString(), headers: headers // Send the body in the request
    );

    print("Login successful2 , ${response.body}");

    if (response.hasError) {
      throw Exception('Failed to send fcm token: ${response.statusText}');
    }

    print("Login successful, received data: ${response.body}");

    return (response.body['data'] as List)
        .map((json) => Notification.fromJson(json as Map<String, dynamic>))
        .toList();
  }

}
