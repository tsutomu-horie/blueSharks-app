import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthToken {
  final _storage = const FlutterSecureStorage();

  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: 'accessToken', value: token.replaceAll('"', ''));
  }

  Future<String?> getAccessToken() async {
    const _storage = FlutterSecureStorage();
    try {
      final accessToken = await _storage.read(key: 'accessToken');
      return accessToken;
    } on PlatformException catch (e) {
      // Workaround for https://github.com/mogol/flutter_secure_storage/issues/43
      print("get error secure storage ${e}");
      await _storage.deleteAll();
    }
    return null;
    // String? token = await _storage.read(key: 'accessToken');
    //
    // if (token != null){
    //   return "Bearer $token";
    // }
    //
    // return null;
  }

  Future<void> deleteToken() async {
    return await _storage.delete(key: 'accessToken');
  }
}
