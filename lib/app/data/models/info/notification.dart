import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification.freezed.dart';
part 'notification.g.dart';

@freezed
class Notification with _$Notification {
  const factory Notification({
    required String id,
    required int notifiable_id,
    required String notifiable_type,
    required DateTime created_at,
    required DateTime updated_at,
    required NotificationData data,
    DateTime? read_at,
  }) = _Notification;

  factory Notification.fromJson(Map<String, dynamic> json) =>
      _$NotificationFromJson(json);
}

@freezed
class NotificationData with _$NotificationData {
  const factory NotificationData({
    required String body,
    required String model,
    required String model_id,
    required String title,
  }) = _NotificationData;

  factory NotificationData.fromJson(Map<String, dynamic> json) =>
      _$NotificationDataFromJson(json);
}
