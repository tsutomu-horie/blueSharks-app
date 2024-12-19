// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

NotificationItem _$NotificationItemFromJson(Map<String, dynamic> json) {
  return _Notification.fromJson(json);
}

/// @nodoc
mixin _$NotificationItem {
  dynamic get id => throw _privateConstructorUsedError;
  int? get notifiable_id => throw _privateConstructorUsedError;
  String? get notifiable_type => throw _privateConstructorUsedError;
  String get created_at => throw _privateConstructorUsedError;
  String get updated_at => throw _privateConstructorUsedError;
  NotificationData get data => throw _privateConstructorUsedError;
  DateTime? get read_at => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $NotificationItemCopyWith<NotificationItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NotificationItemCopyWith<$Res> {
  factory $NotificationItemCopyWith(
          NotificationItem value, $Res Function(NotificationItem) then) =
      _$NotificationItemCopyWithImpl<$Res, NotificationItem>;
  @useResult
  $Res call(
      {dynamic id,
      int? notifiable_id,
      String? notifiable_type,
      String created_at,
      String updated_at,
      NotificationData data,
      DateTime? read_at});

  $NotificationDataCopyWith<$Res> get data;
}

/// @nodoc
class _$NotificationItemCopyWithImpl<$Res, $Val extends NotificationItem>
    implements $NotificationItemCopyWith<$Res> {
  _$NotificationItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? notifiable_id = freezed,
    Object? notifiable_type = freezed,
    Object? created_at = null,
    Object? updated_at = null,
    Object? data = null,
    Object? read_at = freezed,
  }) {
    return _then(_value.copyWith(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as dynamic,
      notifiable_id: freezed == notifiable_id
          ? _value.notifiable_id
          : notifiable_id // ignore: cast_nullable_to_non_nullable
              as int?,
      notifiable_type: freezed == notifiable_type
          ? _value.notifiable_type
          : notifiable_type // ignore: cast_nullable_to_non_nullable
              as String?,
      created_at: null == created_at
          ? _value.created_at
          : created_at // ignore: cast_nullable_to_non_nullable
              as String,
      updated_at: null == updated_at
          ? _value.updated_at
          : updated_at // ignore: cast_nullable_to_non_nullable
              as String,
      data: null == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as NotificationData,
      read_at: freezed == read_at
          ? _value.read_at
          : read_at // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $NotificationDataCopyWith<$Res> get data {
    return $NotificationDataCopyWith<$Res>(_value.data, (value) {
      return _then(_value.copyWith(data: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$NotificationImplCopyWith<$Res>
    implements $NotificationItemCopyWith<$Res> {
  factory _$$NotificationImplCopyWith(
          _$NotificationImpl value, $Res Function(_$NotificationImpl) then) =
      __$$NotificationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {dynamic id,
      int? notifiable_id,
      String? notifiable_type,
      String created_at,
      String updated_at,
      NotificationData data,
      DateTime? read_at});

  @override
  $NotificationDataCopyWith<$Res> get data;
}

/// @nodoc
class __$$NotificationImplCopyWithImpl<$Res>
    extends _$NotificationItemCopyWithImpl<$Res, _$NotificationImpl>
    implements _$$NotificationImplCopyWith<$Res> {
  __$$NotificationImplCopyWithImpl(
      _$NotificationImpl _value, $Res Function(_$NotificationImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? notifiable_id = freezed,
    Object? notifiable_type = freezed,
    Object? created_at = null,
    Object? updated_at = null,
    Object? data = null,
    Object? read_at = freezed,
  }) {
    return _then(_$NotificationImpl(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as dynamic,
      notifiable_id: freezed == notifiable_id
          ? _value.notifiable_id
          : notifiable_id // ignore: cast_nullable_to_non_nullable
              as int?,
      notifiable_type: freezed == notifiable_type
          ? _value.notifiable_type
          : notifiable_type // ignore: cast_nullable_to_non_nullable
              as String?,
      created_at: null == created_at
          ? _value.created_at
          : created_at // ignore: cast_nullable_to_non_nullable
              as String,
      updated_at: null == updated_at
          ? _value.updated_at
          : updated_at // ignore: cast_nullable_to_non_nullable
              as String,
      data: null == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as NotificationData,
      read_at: freezed == read_at
          ? _value.read_at
          : read_at // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$NotificationImpl implements _Notification {
  const _$NotificationImpl(
      {required this.id,
      this.notifiable_id,
      this.notifiable_type,
      required this.created_at,
      required this.updated_at,
      required this.data,
      this.read_at});

  factory _$NotificationImpl.fromJson(Map<String, dynamic> json) =>
      _$$NotificationImplFromJson(json);

  @override
  final dynamic id;
  @override
  final int? notifiable_id;
  @override
  final String? notifiable_type;
  @override
  final String created_at;
  @override
  final String updated_at;
  @override
  final NotificationData data;
  @override
  final DateTime? read_at;

  @override
  String toString() {
    return 'NotificationItem(id: $id, notifiable_id: $notifiable_id, notifiable_type: $notifiable_type, created_at: $created_at, updated_at: $updated_at, data: $data, read_at: $read_at)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NotificationImpl &&
            const DeepCollectionEquality().equals(other.id, id) &&
            (identical(other.notifiable_id, notifiable_id) ||
                other.notifiable_id == notifiable_id) &&
            (identical(other.notifiable_type, notifiable_type) ||
                other.notifiable_type == notifiable_type) &&
            (identical(other.created_at, created_at) ||
                other.created_at == created_at) &&
            (identical(other.updated_at, updated_at) ||
                other.updated_at == updated_at) &&
            (identical(other.data, data) || other.data == data) &&
            (identical(other.read_at, read_at) || other.read_at == read_at));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(id),
      notifiable_id,
      notifiable_type,
      created_at,
      updated_at,
      data,
      read_at);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$NotificationImplCopyWith<_$NotificationImpl> get copyWith =>
      __$$NotificationImplCopyWithImpl<_$NotificationImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$NotificationImplToJson(
      this,
    );
  }
}

abstract class _Notification implements NotificationItem {
  const factory _Notification(
      {required final dynamic id,
      final int? notifiable_id,
      final String? notifiable_type,
      required final String created_at,
      required final String updated_at,
      required final NotificationData data,
      final DateTime? read_at}) = _$NotificationImpl;

  factory _Notification.fromJson(Map<String, dynamic> json) =
      _$NotificationImpl.fromJson;

  @override
  dynamic get id;
  @override
  int? get notifiable_id;
  @override
  String? get notifiable_type;
  @override
  String get created_at;
  @override
  String get updated_at;
  @override
  NotificationData get data;
  @override
  DateTime? get read_at;
  @override
  @JsonKey(ignore: true)
  _$$NotificationImplCopyWith<_$NotificationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

NotificationData _$NotificationDataFromJson(Map<String, dynamic> json) {
  return _NotificationData.fromJson(json);
}

/// @nodoc
mixin _$NotificationData {
  String get body => throw _privateConstructorUsedError;
  String get model => throw _privateConstructorUsedError;
  dynamic get model_id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get photo => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $NotificationDataCopyWith<NotificationData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NotificationDataCopyWith<$Res> {
  factory $NotificationDataCopyWith(
          NotificationData value, $Res Function(NotificationData) then) =
      _$NotificationDataCopyWithImpl<$Res, NotificationData>;
  @useResult
  $Res call(
      {String body,
      String model,
      dynamic model_id,
      String title,
      String? photo});
}

/// @nodoc
class _$NotificationDataCopyWithImpl<$Res, $Val extends NotificationData>
    implements $NotificationDataCopyWith<$Res> {
  _$NotificationDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? body = null,
    Object? model = null,
    Object? model_id = freezed,
    Object? title = null,
    Object? photo = freezed,
  }) {
    return _then(_value.copyWith(
      body: null == body
          ? _value.body
          : body // ignore: cast_nullable_to_non_nullable
              as String,
      model: null == model
          ? _value.model
          : model // ignore: cast_nullable_to_non_nullable
              as String,
      model_id: freezed == model_id
          ? _value.model_id
          : model_id // ignore: cast_nullable_to_non_nullable
              as dynamic,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      photo: freezed == photo
          ? _value.photo
          : photo // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$NotificationDataImplCopyWith<$Res>
    implements $NotificationDataCopyWith<$Res> {
  factory _$$NotificationDataImplCopyWith(_$NotificationDataImpl value,
          $Res Function(_$NotificationDataImpl) then) =
      __$$NotificationDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String body,
      String model,
      dynamic model_id,
      String title,
      String? photo});
}

/// @nodoc
class __$$NotificationDataImplCopyWithImpl<$Res>
    extends _$NotificationDataCopyWithImpl<$Res, _$NotificationDataImpl>
    implements _$$NotificationDataImplCopyWith<$Res> {
  __$$NotificationDataImplCopyWithImpl(_$NotificationDataImpl _value,
      $Res Function(_$NotificationDataImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? body = null,
    Object? model = null,
    Object? model_id = freezed,
    Object? title = null,
    Object? photo = freezed,
  }) {
    return _then(_$NotificationDataImpl(
      body: null == body
          ? _value.body
          : body // ignore: cast_nullable_to_non_nullable
              as String,
      model: null == model
          ? _value.model
          : model // ignore: cast_nullable_to_non_nullable
              as String,
      model_id: freezed == model_id
          ? _value.model_id
          : model_id // ignore: cast_nullable_to_non_nullable
              as dynamic,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      photo: freezed == photo
          ? _value.photo
          : photo // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$NotificationDataImpl implements _NotificationData {
  const _$NotificationDataImpl(
      {required this.body,
      required this.model,
      required this.model_id,
      required this.title,
      this.photo});

  factory _$NotificationDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$NotificationDataImplFromJson(json);

  @override
  final String body;
  @override
  final String model;
  @override
  final dynamic model_id;
  @override
  final String title;
  @override
  final String? photo;

  @override
  String toString() {
    return 'NotificationData(body: $body, model: $model, model_id: $model_id, title: $title, photo: $photo)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NotificationDataImpl &&
            (identical(other.body, body) || other.body == body) &&
            (identical(other.model, model) || other.model == model) &&
            const DeepCollectionEquality().equals(other.model_id, model_id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.photo, photo) || other.photo == photo));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, body, model,
      const DeepCollectionEquality().hash(model_id), title, photo);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$NotificationDataImplCopyWith<_$NotificationDataImpl> get copyWith =>
      __$$NotificationDataImplCopyWithImpl<_$NotificationDataImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$NotificationDataImplToJson(
      this,
    );
  }
}

abstract class _NotificationData implements NotificationData {
  const factory _NotificationData(
      {required final String body,
      required final String model,
      required final dynamic model_id,
      required final String title,
      final String? photo}) = _$NotificationDataImpl;

  factory _NotificationData.fromJson(Map<String, dynamic> json) =
      _$NotificationDataImpl.fromJson;

  @override
  String get body;
  @override
  String get model;
  @override
  dynamic get model_id;
  @override
  String get title;
  @override
  String? get photo;
  @override
  @JsonKey(ignore: true)
  _$$NotificationDataImplCopyWith<_$NotificationDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
