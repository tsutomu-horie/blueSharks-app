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
      type: json['type'] as String,
      userable_type: json['userable_type'] as String,
      userable_id: (json['userable_id'] as num).toInt(),
      created_at: json['created_at'] as String,
      updated_at: json['updated_at'] as String,
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
