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
    String? type,
    String? userable_type,
    int? userable_id,
    String? created_at,
    String? updated_at,
    required String access_token,
  }) = _Auth;

  factory Auth.fromJson(Map<String, dynamic> json) => _$AuthFromJson(json);
}

@freezed
class UserData with _$UserData {
  const factory UserData({
    @JsonKey(name: 'account_id') required String accountId,
    @JsonKey(name: 'created_at') required String createdAt,
    required String email,
    String? gender,
    required int id,
    @JsonKey(name: 'is_verified') required bool isVerified,
    @JsonKey(name: 'is_either_matched') bool? isEitherMatched,
    @JsonKey(name: 'kan_first_name') String? kanFirstName,
    @JsonKey(name: 'kan_last_name') String? kanLastName,
    @JsonKey(name: 'kat_first_name') String? katFirstName,
    @JsonKey(name: 'kat_last_name') String? katLastName,
    @JsonKey(name: 'customer_level') String? customerLevel,
  }) = _UserData;

  factory UserData.fromJson(Map<String, dynamic> json) => _$UserDataFromJson(json);
}