// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AuthImpl _$$AuthImplFromJson(Map<String, dynamic> json) => _$AuthImpl(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      email: json['email'] as String,
      email_verified_at: json['email_verified_at'] as String?,
      type: json['type'] as String?,
      userable_type: json['userable_type'] as String?,
      userable_id: (json['userable_id'] as num?)?.toInt(),
      created_at: json['created_at'] as String?,
      updated_at: json['updated_at'] as String?,
      access_token: json['access_token'] as String,
    );

Map<String, dynamic> _$$AuthImplToJson(_$AuthImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'email_verified_at': instance.email_verified_at,
      'type': instance.type,
      'userable_type': instance.userable_type,
      'userable_id': instance.userable_id,
      'created_at': instance.created_at,
      'updated_at': instance.updated_at,
      'access_token': instance.access_token,
    };

_$UserDataImpl _$$UserDataImplFromJson(Map<String, dynamic> json) =>
    _$UserDataImpl(
      accountId: json['account_id'] as String,
      createdAt: json['created_at'] as String,
      email: json['email'] as String,
      gender: json['gender'] as String?,
      id: (json['id'] as num).toInt(),
      isVerified: json['is_verified'] as bool,
      isEitherMatched: json['is_either_matched'] as bool?,
      kanFirstName: json['kan_first_name'] as String?,
      kanLastName: json['kan_last_name'] as String?,
      katFirstName: json['kat_first_name'] as String?,
      katLastName: json['kat_last_name'] as String?,
      customerLevel: json['customer_level'] as String?,
    );

Map<String, dynamic> _$$UserDataImplToJson(_$UserDataImpl instance) =>
    <String, dynamic>{
      'account_id': instance.accountId,
      'created_at': instance.createdAt,
      'email': instance.email,
      'gender': instance.gender,
      'id': instance.id,
      'is_verified': instance.isVerified,
      'is_either_matched': instance.isEitherMatched,
      'kan_first_name': instance.kanFirstName,
      'kan_last_name': instance.kanLastName,
      'kat_first_name': instance.katFirstName,
      'kat_last_name': instance.katLastName,
      'customer_level': instance.customerLevel,
    };
