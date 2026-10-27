import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/models/auth/auth.dart';
import 'package:koto_blue_sharks/app/data/models/info/notification.dart';
import 'package:koto_blue_sharks/app/providers/auth/login_response_diagnostics.dart';
import 'package:koto_blue_sharks/app/services/auth_token.dart';
import 'package:koto_blue_sharks/app/services/notification_token_sync.dart';
import 'package:koto_blue_sharks/utils/Constant.dart';

class AuthProvider extends GetConnect {
  @override
  void onInit() {
    httpClient.baseUrl = Constants.baseUrlAuthApi;
  }

  Future<Auth> login(
      String username, String password, Function() onError) async {
    try {
      final response = await requestLogin({
        'email': username,
        'password': password,
      }).timeout(const Duration(seconds: 20));

      final status = response.statusCode;
      if (status == null || status <= 0) {
        throw const LoginFailure(LoginFailureKind.network);
      }
      if (status == 401 || status == 403 || status == 422) {
        onError();
        throw const LoginFailure(LoginFailureKind.rejected);
      }
      if (status < 200 || status >= 300) {
        throw const LoginFailure(LoginFailureKind.server);
      }
      final body = response.body;
      if (body is! Map<String, dynamic> ||
          body['data'] is! Map<String, dynamic>) {
        throw const LoginFailure(LoginFailureKind.invalidResponse);
      }
      final auth = Auth.fromJson(body['data'] as Map<String, dynamic>);
      if (auth.access_token.trim().isEmpty) {
        throw const LoginFailure(LoginFailureKind.invalidResponse);
      }
      return auth;
    } on TimeoutException {
      throw const LoginFailure(LoginFailureKind.network);
    } on SocketException {
      throw const LoginFailure(LoginFailureKind.network);
    } on FormatException {
      throw const LoginFailure(LoginFailureKind.invalidResponse);
    } on TypeError {
      throw const LoginFailure(LoginFailureKind.invalidResponse);
    }
  }

  @protected
  Future<Response<dynamic>> requestLogin(Map<String, dynamic> body) {
    return kDebugMode
        ? httpClient.post<dynamic>(
            'login',
            body: body,
            responseInterceptor: (_, __, rawResponse) async {
              debugPrint(loginResponseDiagnosticLine(rawResponse));
              return null;
            },
          )
        : post<dynamic>('login', body);
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

  static final _notificationSender = NotificationTokenRegistration<Response>(
    currentSession: () => AuthToken.sessionVersion,
  );

  // Keep the original signature: No14 and existing mock overrides use it.
  Future<Response?> updateNotificationToken(String fcm) =>
      updateNotificationTokenWhileCurrent(fcm,
          expectedSessionVersion: AuthToken.sessionVersion,
          isActive: () => true);

  Future<Response?> updateNotificationTokenWhileCurrent(String fcm,
      {required int expectedSessionVersion,
      required bool Function() isActive}) =>
      _notificationSender.send(fcm,
          expectedSession: expectedSessionVersion,
          isActive: isActive,
          operation: (canSend) async {
            final snapshot = await AuthToken().readSessionSnapshot();
            final token = snapshot.token;
            // Snapshot acquisition is serialized with No13's token mutations.
            // A new session number alone does not mean its write has completed.
            // Recheck the paired session and lease immediately before post.
            if (!canSend() ||
                snapshot.sessionVersion != expectedSessionVersion ||
                token == null) {
              return null;
            }
            httpClient.baseUrl = Constants.baseUrlAuthApi;
            final response = await post('notifications/create-fcm', {
              'fcm_token': fcm,
            }, headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            });
            if (response.hasError) {
              throw StateError('Notification synchronization unavailable');
            }
            return response;
          });

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

// Deliberately contains no response body, credentials, or transport exception.
enum LoginFailureKind { rejected, network, server, invalidResponse }

class LoginFailure implements Exception {
  const LoginFailure(this.kind);
  final LoginFailureKind kind;
}
