import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification.freezed.dart';
part 'notification.g.dart';

@freezed
class NotificationItem with _$NotificationItem {
  const factory NotificationItem({
    required dynamic id,
    int? notifiable_id,
    String? notifiable_type,
    required String created_at,
    required String updated_at,
    required NotificationData data,
    DateTime? read_at,
  }) = _Notification;

  factory NotificationItem.fromJson(Map<String, dynamic> json) =>
      _$NotificationItemFromJson(json);
}

@freezed
class NotificationData with _$NotificationData {
  const factory NotificationData({
    required String body,
    required String model,
    required dynamic model_id,
    required String title,
    String? photo,
  }) = _NotificationData;

  factory NotificationData.fromJson(Map<String, dynamic> json) =>
      _$NotificationDataFromJson(json);
}
