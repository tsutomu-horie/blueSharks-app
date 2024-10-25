import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthToken {
  final _storage = const FlutterSecureStorage();

  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: 'accessToken', value: token.replaceAll('"', ''));
  }

  Future<String?> getAccessToken() async {
    String? token = await _storage.read(key: 'accessToken');

    if (token != null){
      return "Bearer $token";
    }

    return null;
  }

  Future<void> deleteToken() async {
    return await _storage.delete(key: 'accessToken');
  }
}
