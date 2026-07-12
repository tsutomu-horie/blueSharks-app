// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'otp.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OtpImpl _$$OtpImplFromJson(Map<String, dynamic> json) => _$OtpImpl(
      id: (json['id'] as num).toInt(),
      address: json['address'] as String,
      expired_at: json['expired_at'] as String,
    );

Map<String, dynamic> _$$OtpImplToJson(_$OtpImpl instance) => <String, dynamic>{
      'id': instance.id,
      'address': instance.address,
      'expired_at': instance.expired_at,
    };
