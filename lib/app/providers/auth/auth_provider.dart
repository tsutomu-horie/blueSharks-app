import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/models/auth/auth.dart';
import 'package:koto_blue_sharks/app/data/models/info/notification.dart';
import 'package:koto_blue_sharks/app/providers/auth/login_response_diagnostics.dart';
import 'package:koto_blue_sharks/app/services/auth_token.dart';
import 'package:koto_blue_sharks/utils/Constant.dart';

class AuthProvider extends GetConnect {
  @override
  void onInit() {
    httpClient.baseUrl = Constants.baseUrlAuthApi;
  }

  Future<Auth> login(String username, String password, Function() onError) async {
    final url = Uri.parse('login');
    debugPrint("load ${httpClient.baseUrl}${url.toString()}");

    final Map<String, dynamic> body = {
      "email": username,
      "password": password,
    };

    final response = kDebugMode
        ? await httpClient.post<dynamic>(
            url.toString(),
            body: body,
            responseInterceptor: (_, __, rawResponse) async {
              debugPrint(loginResponseDiagnosticLine(rawResponse));
              // Returning null preserves GetX's normal body decoding.
              return null;
            },
          )
        : await post<dynamic>(url.toString(), body);

    if (response.hasError) {
      onError();
      throw Exception('Failed to login: ${response.statusText}');
    }

    return Auth.fromJson(response.body["data"]);
  }

  Future<Auth> register(String acountId, String email, String otpId, String password, Function(String) onError) async {
    final url = Uri.parse('register');
    debugPrint("load ${httpClient.baseUrl}${url.toString()}");

    final Map<String, dynamic> body = {
      "account_id": acountId,
      "email": email,
      "otp_id": otpId,
      "password": password,
    };


    final response = await post(
      url.toString(), body, // Send the body in the request
    );


    if (response.hasError) {
      onError("${response.statusText}");
      throw Exception('Failed to login: ${response.statusText}');
    }


    return Auth.fromJson(response.body["data"]);
  }

  Future<Response> resetPassword(String otpId, String password, String passwordConfirmation,Function onError) async {
    final url = Uri.parse('reset-password');
    debugPrint("load ${httpClient.baseUrl}${url.toString()}");

    final Map<String, dynamic> body = {
      "otp_id": otpId,
      "password": password,
      "password_confirmation": passwordConfirmation,
    };

    final response = await post(
      url.toString(), body, // Send the body in the request
    );


    if (response.hasError) {
      onError();
      throw Exception('Failed to login: ${response.statusText}');
    }


    return response;
  }

  Future<Response> updateProfile(String email, String accountId, String gender,Function onError, bool isNotification) async {
    final url = Uri.parse('profile');
    debugPrint("load ${httpClient.baseUrl}${url.toString()}");

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
      "is_notification": isNotification,
    };

    final response = await patch(
      url.toString(), body, headers: headers // Send the body in the request
    );


    if (response.hasError) {
      onError();
      throw Exception('Failed to login: ${response.statusText}');
    }


    return response;
  }

  Future<Response> updatePassword(String currentPassword, String confirmPassword, String newPassword,Function(String, String) onError) async {
    httpClient.baseUrl = Constants.baseUrlAuthApi;

    final url = Uri.parse('new-password');
    debugPrint("load ${httpClient.baseUrl}${url.toString()}");

    final auth = AuthToken();
    final token = await auth.getAccessToken();

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json', // Optional, depending on the API
    };

    final Map<String, dynamic> body = {
      "confirm_password": confirmPassword,
      "new_password": newPassword,
      "old_password": currentPassword,
    };

    final response = await patch(
      url.toString(), body, headers: headers // Send the body in the request
    );


    if (response.hasError) {
      onError("${response.body['errors']}", "${response.body['message']}");
      throw Exception('Failed to login: ${response.statusText}');
    }


    return response;
  }

  Future<UserData> getProfile(String token, Function onError) async {
    final url = Uri.parse('profile');
    debugPrint("load ${httpClient.baseUrl}${url.toString()}");

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json', // Optional, depending on the API
    };

    final response = await get(
      url.toString(), headers: headers // Send the body in the request
    );

    if (response.hasError) {
      onError();
      throw Exception('Failed to login: ${response.statusText}');
    }

    return UserData.fromJson(response.body["data"]);
  }

  Future<UserData> refreshProfile(String token, Function onError) async {
    final url = Uri.parse('profile/refresh');
    debugPrint("load ${httpClient.baseUrl}${url.toString()}");

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json', // Optional, depending on the API
    };

    final response = await get(
        url.toString(), headers: headers // Send the body in the request
    );

    if (response.hasError) {
      onError();
      throw Exception('Failed to login: ${response.statusText}');
    }

    return UserData.fromJson(response.body["data"]);
  }

  Future<Response> deleteProfile(String token, Function onError) async {
    final url = Uri.parse('profile');
    debugPrint("load ${httpClient.baseUrl}${url.toString()}");

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json', // Optional, depending on the API
    };

    final response = await delete(
      url.toString(), headers: headers // Send the body in the request
    );


    if (response.hasError) {
      onError();
      throw Exception('Failed to login: ${response.statusText}');
    }


    return response;
  }

  Future<Response?> updateNotificationToken(String fcm) async {
    httpClient.baseUrl = Constants.baseUrlAuthApi;

    final url = Uri.parse('notifications/create-fcm');
    debugPrint("load ${httpClient.baseUrl}${url.toString()}");

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


      if (response.hasError) {
        throw Exception('Failed to send fcm token: ${response.statusText}');
      }


      return response;
    } else {
      return null;
    }
  }

  Future<List<NotificationItem>> getNotificationList() async {
    httpClient.baseUrl = Constants.baseUrlAuthApi;

    final url = Uri.parse('notifications');
    debugPrint("load ${httpClient.baseUrl}${url.toString()}");

    final auth = AuthToken();
    final token = await auth.getAccessToken();

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json', // Optional, depending on the API
    };

    final response = await get(
        url.toString(), headers: headers // Send the body in the request
    );


    if (response.hasError) {
      throw Exception('Failed to send fcm token: ${response.statusText}');
    }


    return (response.body['data'] as List)
        .map((json) => NotificationItem.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<int> getUnreadNotification() async {
    httpClient.baseUrl = Constants.baseUrlAuthApi;

    final url = Uri.parse('notifications/unread');

    final auth = AuthToken();
    final token = await auth.getAccessToken();

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json', // Optional, depending on the API
    };

    final response = await get(
        url.toString(), headers: headers // Send the body in the request
    );


    if (response.hasError) {
      throw Exception('Failed to send fcm token: ${response.statusText}');
    }


    return (response.body['data']['unread']);
  }

  Future<Response> readNotification(String notificationId) async {
    httpClient.baseUrl = Constants.baseUrlAuthApi;

    final url = Uri.parse('notifications/$notificationId');

    final auth = AuthToken();
    final token = await auth.getAccessToken();

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json', // Optional, depending on the API
    };

    final response = await patch(
        url.toString(), null, headers: headers // Send the body in the request
    );


    if (response.hasError) {
      throw Exception('Failed to send fcm token: ${response.statusText}');
    }


    return response;
  }

  Future<Response> logoutAccount(String token) async {
    httpClient.baseUrl = Constants.baseUrlAuthApi;

    final url = Uri.parse('logout');

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json', // Optional, depending on the API
    };

    final response = await post(
        url.toString(), null, headers: headers // Send the body in the request
    );

    // A 401 means the bearer token is already invalid, such as after the
    // server revoked it but the earlier response did not reach the client.
    // Clearing the stale local session is safe; other errors remain failures.
    if (response.statusCode == 401) {
      return response;
    }

    if (response.hasError) {
      throw Exception('Failed to send fcm token: ${response.statusText}');
    }

    return response;
  }

}
