// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$NotificationImpl _$$NotificationImplFromJson(Map<String, dynamic> json) =>
    _$NotificationImpl(
      id: json['id'] as String,
      notifiable_id: (json['notifiable_id'] as num).toInt(),
      notifiable_type: json['notifiable_type'] as String,
      created_at: DateTime.parse(json['created_at'] as String),
      updated_at: DateTime.parse(json['updated_at'] as String),
      data: NotificationData.fromJson(json['data'] as Map<String, dynamic>),
      read_at: json['read_at'] == null
          ? null
          : DateTime.parse(json['read_at'] as String),
    );

Map<String, dynamic> _$$NotificationImplToJson(_$NotificationImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'notifiable_id': instance.notifiable_id,
      'notifiable_type': instance.notifiable_type,
      'created_at': instance.created_at.toIso8601String(),
      'updated_at': instance.updated_at.toIso8601String(),
      'data': instance.data,
      'read_at': instance.read_at?.toIso8601String(),
    };

_$NotificationDataImpl _$$NotificationDataImplFromJson(
        Map<String, dynamic> json) =>
    _$NotificationDataImpl(
      body: json['body'] as String,
      model: json['model'] as String,
      model_id: json['model_id'] as String,
      title: json['title'] as String,
    );

Map<String, dynamic> _$$NotificationDataImplToJson(
        _$NotificationDataImpl instance) =>
    <String, dynamic>{
      'body': instance.body,
      'model': instance.model,
      'model_id': instance.model_id,
      'title': instance.title,
    };
