import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth.freezed.dart';
part 'auth.g.dart';

@freezed
class Auth with _$Auth {
  factory Auth({
    required int id,
    required String name,
    required String email,
    String? email_verified_at,
    required String? type,
    required String userable_type,
    required int userable_id,
    required String created_at,
    required String updated_at,
    required String access_token,
  }) = _Auth;

  factory Auth.fromJson(Map<String, dynamic> json) => _$AuthFromJson(json);
}
