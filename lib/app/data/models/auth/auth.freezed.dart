// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Auth _$AuthFromJson(Map<String, dynamic> json) {
  return _Auth.fromJson(json);
}

/// @nodoc
mixin _$Auth {
  int get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  String? get email_verified_at => throw _privateConstructorUsedError;
  String? get type => throw _privateConstructorUsedError;
  String? get userable_type => throw _privateConstructorUsedError;
  int? get userable_id => throw _privateConstructorUsedError;
  String? get created_at => throw _privateConstructorUsedError;
  String? get updated_at => throw _privateConstructorUsedError;
  String get access_token => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AuthCopyWith<Auth> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AuthCopyWith<$Res> {
  factory $AuthCopyWith(Auth value, $Res Function(Auth) then) =
      _$AuthCopyWithImpl<$Res, Auth>;
  @useResult
  $Res call(
      {int id,
      String name,
      String email,
      String? email_verified_at,
      String? type,
      String? userable_type,
      int? userable_id,
      String? created_at,
      String? updated_at,
      String access_token});
}

/// @nodoc
class _$AuthCopyWithImpl<$Res, $Val extends Auth>
    implements $AuthCopyWith<$Res> {
  _$AuthCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? email = null,
    Object? email_verified_at = freezed,
    Object? type = freezed,
    Object? userable_type = freezed,
    Object? userable_id = freezed,
    Object? created_at = freezed,
    Object? updated_at = freezed,
    Object? access_token = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      email_verified_at: freezed == email_verified_at
          ? _value.email_verified_at
          : email_verified_at // ignore: cast_nullable_to_non_nullable
              as String?,
      type: freezed == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String?,
      userable_type: freezed == userable_type
          ? _value.userable_type
          : userable_type // ignore: cast_nullable_to_non_nullable
              as String?,
      userable_id: freezed == userable_id
          ? _value.userable_id
          : userable_id // ignore: cast_nullable_to_non_nullable
              as int?,
      created_at: freezed == created_at
          ? _value.created_at
          : created_at // ignore: cast_nullable_to_non_nullable
              as String?,
      updated_at: freezed == updated_at
          ? _value.updated_at
          : updated_at // ignore: cast_nullable_to_non_nullable
              as String?,
      access_token: null == access_token
          ? _value.access_token
          : access_token // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AuthImplCopyWith<$Res> implements $AuthCopyWith<$Res> {
  factory _$$AuthImplCopyWith(
          _$AuthImpl value, $Res Function(_$AuthImpl) then) =
      __$$AuthImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String name,
      String email,
      String? email_verified_at,
      String? type,
      String? userable_type,
      int? userable_id,
      String? created_at,
      String? updated_at,
      String access_token});
}

/// @nodoc
class __$$AuthImplCopyWithImpl<$Res>
    extends _$AuthCopyWithImpl<$Res, _$AuthImpl>
    implements _$$AuthImplCopyWith<$Res> {
  __$$AuthImplCopyWithImpl(_$AuthImpl _value, $Res Function(_$AuthImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? email = null,
    Object? email_verified_at = freezed,
    Object? type = freezed,
    Object? userable_type = freezed,
    Object? userable_id = freezed,
    Object? created_at = freezed,
    Object? updated_at = freezed,
    Object? access_token = null,
  }) {
    return _then(_$AuthImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      email_verified_at: freezed == email_verified_at
          ? _value.email_verified_at
          : email_verified_at // ignore: cast_nullable_to_non_nullable
              as String?,
      type: freezed == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String?,
      userable_type: freezed == userable_type
          ? _value.userable_type
          : userable_type // ignore: cast_nullable_to_non_nullable
              as String?,
      userable_id: freezed == userable_id
          ? _value.userable_id
          : userable_id // ignore: cast_nullable_to_non_nullable
              as int?,
      created_at: freezed == created_at
          ? _value.created_at
          : created_at // ignore: cast_nullable_to_non_nullable
              as String?,
      updated_at: freezed == updated_at
          ? _value.updated_at
          : updated_at // ignore: cast_nullable_to_non_nullable
              as String?,
      access_token: null == access_token
          ? _value.access_token
          : access_token // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AuthImpl implements _Auth {
  _$AuthImpl(
      {required this.id,
      required this.name,
      required this.email,
      this.email_verified_at,
      this.type,
      this.userable_type,
      this.userable_id,
      this.created_at,
      this.updated_at,
      required this.access_token});

  factory _$AuthImpl.fromJson(Map<String, dynamic> json) =>
      _$$AuthImplFromJson(json);

  @override
  final int id;
  @override
  final String name;
  @override
  final String email;
  @override
  final String? email_verified_at;
  @override
  final String? type;
  @override
  final String? userable_type;
  @override
  final int? userable_id;
  @override
  final String? created_at;
  @override
  final String? updated_at;
  @override
  final String access_token;

  @override
  String toString() {
    return 'Auth(id: $id, name: $name, email: $email, email_verified_at: $email_verified_at, type: $type, userable_type: $userable_type, userable_id: $userable_id, created_at: $created_at, updated_at: $updated_at, access_token: $access_token)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AuthImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.email_verified_at, email_verified_at) ||
                other.email_verified_at == email_verified_at) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.userable_type, userable_type) ||
                other.userable_type == userable_type) &&
            (identical(other.userable_id, userable_id) ||
                other.userable_id == userable_id) &&
            (identical(other.created_at, created_at) ||
                other.created_at == created_at) &&
            (identical(other.updated_at, updated_at) ||
                other.updated_at == updated_at) &&
            (identical(other.access_token, access_token) ||
                other.access_token == access_token));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      email,
      email_verified_at,
      type,
      userable_type,
      userable_id,
      created_at,
      updated_at,
      access_token);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AuthImplCopyWith<_$AuthImpl> get copyWith =>
      __$$AuthImplCopyWithImpl<_$AuthImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AuthImplToJson(
      this,
    );
  }
}

abstract class _Auth implements Auth {
  factory _Auth(
      {required final int id,
      required final String name,
      required final String email,
      final String? email_verified_at,
      final String? type,
      final String? userable_type,
      final int? userable_id,
      final String? created_at,
      final String? updated_at,
      required final String access_token}) = _$AuthImpl;

  factory _Auth.fromJson(Map<String, dynamic> json) = _$AuthImpl.fromJson;

  @override
  int get id;
  @override
  String get name;
  @override
  String get email;
  @override
  String? get email_verified_at;
  @override
  String? get type;
  @override
  String? get userable_type;
  @override
  int? get userable_id;
  @override
  String? get created_at;
  @override
  String? get updated_at;
  @override
  String get access_token;
  @override
  @JsonKey(ignore: true)
  _$$AuthImplCopyWith<_$AuthImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UserData _$UserDataFromJson(Map<String, dynamic> json) {
  return _UserData.fromJson(json);
}

/// @nodoc
mixin _$UserData {
  @JsonKey(name: 'account_id')
  String get accountId => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  String get createdAt => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  String? get gender => throw _privateConstructorUsedError;
  int get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_verified')
  bool get isVerified => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_either_matched')
  bool? get isEitherMatched => throw _privateConstructorUsedError;
  @JsonKey(name: 'kan_first_name')
  String? get kanFirstName => throw _privateConstructorUsedError;
  @JsonKey(name: 'kan_last_name')
  String? get kanLastName => throw _privateConstructorUsedError;
  @JsonKey(name: 'kat_first_name')
  String? get katFirstName => throw _privateConstructorUsedError;
  @JsonKey(name: 'kat_last_name')
  String? get katLastName => throw _privateConstructorUsedError;
  @JsonKey(name: 'customer_level')
  String? get customerLevel => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_notification')
  bool? get isNotification => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UserDataCopyWith<UserData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserDataCopyWith<$Res> {
  factory $UserDataCopyWith(UserData value, $Res Function(UserData) then) =
      _$UserDataCopyWithImpl<$Res, UserData>;
  @useResult
  $Res call(
      {@JsonKey(name: 'account_id') String accountId,
      @JsonKey(name: 'created_at') String createdAt,
      String email,
      String? gender,
      int id,
      @JsonKey(name: 'is_verified') bool isVerified,
      @JsonKey(name: 'is_either_matched') bool? isEitherMatched,
      @JsonKey(name: 'kan_first_name') String? kanFirstName,
      @JsonKey(name: 'kan_last_name') String? kanLastName,
      @JsonKey(name: 'kat_first_name') String? katFirstName,
      @JsonKey(name: 'kat_last_name') String? katLastName,
      @JsonKey(name: 'customer_level') String? customerLevel,
      @JsonKey(name: 'is_notification') bool? isNotification});
}

/// @nodoc
class _$UserDataCopyWithImpl<$Res, $Val extends UserData>
    implements $UserDataCopyWith<$Res> {
  _$UserDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? accountId = null,
    Object? createdAt = null,
    Object? email = null,
    Object? gender = freezed,
    Object? id = null,
    Object? isVerified = null,
    Object? isEitherMatched = freezed,
    Object? kanFirstName = freezed,
    Object? kanLastName = freezed,
    Object? katFirstName = freezed,
    Object? katLastName = freezed,
    Object? customerLevel = freezed,
    Object? isNotification = freezed,
  }) {
    return _then(_value.copyWith(
      accountId: null == accountId
          ? _value.accountId
          : accountId // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      gender: freezed == gender
          ? _value.gender
          : gender // ignore: cast_nullable_to_non_nullable
              as String?,
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      isVerified: null == isVerified
          ? _value.isVerified
          : isVerified // ignore: cast_nullable_to_non_nullable
              as bool,
      isEitherMatched: freezed == isEitherMatched
          ? _value.isEitherMatched
          : isEitherMatched // ignore: cast_nullable_to_non_nullable
              as bool?,
      kanFirstName: freezed == kanFirstName
          ? _value.kanFirstName
          : kanFirstName // ignore: cast_nullable_to_non_nullable
              as String?,
      kanLastName: freezed == kanLastName
          ? _value.kanLastName
          : kanLastName // ignore: cast_nullable_to_non_nullable
              as String?,
      katFirstName: freezed == katFirstName
          ? _value.katFirstName
          : katFirstName // ignore: cast_nullable_to_non_nullable
              as String?,
      katLastName: freezed == katLastName
          ? _value.katLastName
          : katLastName // ignore: cast_nullable_to_non_nullable
              as String?,
      customerLevel: freezed == customerLevel
          ? _value.customerLevel
          : customerLevel // ignore: cast_nullable_to_non_nullable
              as String?,
      isNotification: freezed == isNotification
          ? _value.isNotification
          : isNotification // ignore: cast_nullable_to_non_nullable
              as bool?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserDataImplCopyWith<$Res>
    implements $UserDataCopyWith<$Res> {
  factory _$$UserDataImplCopyWith(
          _$UserDataImpl value, $Res Function(_$UserDataImpl) then) =
      __$$UserDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'account_id') String accountId,
      @JsonKey(name: 'created_at') String createdAt,
      String email,
      String? gender,
      int id,
      @JsonKey(name: 'is_verified') bool isVerified,
      @JsonKey(name: 'is_either_matched') bool? isEitherMatched,
      @JsonKey(name: 'kan_first_name') String? kanFirstName,
      @JsonKey(name: 'kan_last_name') String? kanLastName,
      @JsonKey(name: 'kat_first_name') String? katFirstName,
      @JsonKey(name: 'kat_last_name') String? katLastName,
      @JsonKey(name: 'customer_level') String? customerLevel,
      @JsonKey(name: 'is_notification') bool? isNotification});
}

/// @nodoc
class __$$UserDataImplCopyWithImpl<$Res>
    extends _$UserDataCopyWithImpl<$Res, _$UserDataImpl>
    implements _$$UserDataImplCopyWith<$Res> {
  __$$UserDataImplCopyWithImpl(
      _$UserDataImpl _value, $Res Function(_$UserDataImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? accountId = null,
    Object? createdAt = null,
    Object? email = null,
    Object? gender = freezed,
    Object? id = null,
    Object? isVerified = null,
    Object? isEitherMatched = freezed,
    Object? kanFirstName = freezed,
    Object? kanLastName = freezed,
    Object? katFirstName = freezed,
    Object? katLastName = freezed,
    Object? customerLevel = freezed,
    Object? isNotification = freezed,
  }) {
    return _then(_$UserDataImpl(
      accountId: null == accountId
          ? _value.accountId
          : accountId // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      gender: freezed == gender
          ? _value.gender
          : gender // ignore: cast_nullable_to_non_nullable
              as String?,
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      isVerified: null == isVerified
          ? _value.isVerified
          : isVerified // ignore: cast_nullable_to_non_nullable
              as bool,
      isEitherMatched: freezed == isEitherMatched
          ? _value.isEitherMatched
          : isEitherMatched // ignore: cast_nullable_to_non_nullable
              as bool?,
      kanFirstName: freezed == kanFirstName
          ? _value.kanFirstName
          : kanFirstName // ignore: cast_nullable_to_non_nullable
              as String?,
      kanLastName: freezed == kanLastName
          ? _value.kanLastName
          : kanLastName // ignore: cast_nullable_to_non_nullable
              as String?,
      katFirstName: freezed == katFirstName
          ? _value.katFirstName
          : katFirstName // ignore: cast_nullable_to_non_nullable
              as String?,
      katLastName: freezed == katLastName
          ? _value.katLastName
          : katLastName // ignore: cast_nullable_to_non_nullable
              as String?,
      customerLevel: freezed == customerLevel
          ? _value.customerLevel
          : customerLevel // ignore: cast_nullable_to_non_nullable
              as String?,
      isNotification: freezed == isNotification
          ? _value.isNotification
          : isNotification // ignore: cast_nullable_to_non_nullable
              as bool?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserDataImpl implements _UserData {
  const _$UserDataImpl(
      {@JsonKey(name: 'account_id') required this.accountId,
      @JsonKey(name: 'created_at') required this.createdAt,
      required this.email,
      this.gender,
      required this.id,
      @JsonKey(name: 'is_verified') required this.isVerified,
      @JsonKey(name: 'is_either_matched') this.isEitherMatched,
      @JsonKey(name: 'kan_first_name') this.kanFirstName,
      @JsonKey(name: 'kan_last_name') this.kanLastName,
      @JsonKey(name: 'kat_first_name') this.katFirstName,
      @JsonKey(name: 'kat_last_name') this.katLastName,
      @JsonKey(name: 'customer_level') this.customerLevel,
      @JsonKey(name: 'is_notification') this.isNotification});

  factory _$UserDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserDataImplFromJson(json);

  @override
  @JsonKey(name: 'account_id')
  final String accountId;
  @override
  @JsonKey(name: 'created_at')
  final String createdAt;
  @override
  final String email;
  @override
  final String? gender;
  @override
  final int id;
  @override
  @JsonKey(name: 'is_verified')
  final bool isVerified;
  @override
  @JsonKey(name: 'is_either_matched')
  final bool? isEitherMatched;
  @override
  @JsonKey(name: 'kan_first_name')
  final String? kanFirstName;
  @override
  @JsonKey(name: 'kan_last_name')
  final String? kanLastName;
  @override
  @JsonKey(name: 'kat_first_name')
  final String? katFirstName;
  @override
  @JsonKey(name: 'kat_last_name')
  final String? katLastName;
  @override
  @JsonKey(name: 'customer_level')
  final String? customerLevel;
  @override
  @JsonKey(name: 'is_notification')
  final bool? isNotification;

  @override
  String toString() {
    return 'UserData(accountId: $accountId, createdAt: $createdAt, email: $email, gender: $gender, id: $id, isVerified: $isVerified, isEitherMatched: $isEitherMatched, kanFirstName: $kanFirstName, kanLastName: $kanLastName, katFirstName: $katFirstName, katLastName: $katLastName, customerLevel: $customerLevel, isNotification: $isNotification)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserDataImpl &&
            (identical(other.accountId, accountId) ||
                other.accountId == accountId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.gender, gender) || other.gender == gender) &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.isVerified, isVerified) ||
                other.isVerified == isVerified) &&
            (identical(other.isEitherMatched, isEitherMatched) ||
                other.isEitherMatched == isEitherMatched) &&
            (identical(other.kanFirstName, kanFirstName) ||
                other.kanFirstName == kanFirstName) &&
            (identical(other.kanLastName, kanLastName) ||
                other.kanLastName == kanLastName) &&
            (identical(other.katFirstName, katFirstName) ||
                other.katFirstName == katFirstName) &&
            (identical(other.katLastName, katLastName) ||
                other.katLastName == katLastName) &&
            (identical(other.customerLevel, customerLevel) ||
                other.customerLevel == customerLevel) &&
            (identical(other.isNotification, isNotification) ||
                other.isNotification == isNotification));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      accountId,
      createdAt,
      email,
      gender,
      id,
      isVerified,
      isEitherMatched,
      kanFirstName,
      kanLastName,
      katFirstName,
      katLastName,
      customerLevel,
      isNotification);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UserDataImplCopyWith<_$UserDataImpl> get copyWith =>
      __$$UserDataImplCopyWithImpl<_$UserDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserDataImplToJson(
      this,
    );
  }
}

abstract class _UserData implements UserData {
  const factory _UserData(
          {@JsonKey(name: 'account_id') required final String accountId,
          @JsonKey(name: 'created_at') required final String createdAt,
          required final String email,
          final String? gender,
          required final int id,
          @JsonKey(name: 'is_verified') required final bool isVerified,
          @JsonKey(name: 'is_either_matched') final bool? isEitherMatched,
          @JsonKey(name: 'kan_first_name') final String? kanFirstName,
          @JsonKey(name: 'kan_last_name') final String? kanLastName,
          @JsonKey(name: 'kat_first_name') final String? katFirstName,
          @JsonKey(name: 'kat_last_name') final String? katLastName,
          @JsonKey(name: 'customer_level') final String? customerLevel,
          @JsonKey(name: 'is_notification') final bool? isNotification}) =
      _$UserDataImpl;

  factory _UserData.fromJson(Map<String, dynamic> json) =
      _$UserDataImpl.fromJson;

  @override
  @JsonKey(name: 'account_id')
  String get accountId;
  @override
  @JsonKey(name: 'created_at')
  String get createdAt;
  @override
  String get email;
  @override
  String? get gender;
  @override
  int get id;
  @override
  @JsonKey(name: 'is_verified')
  bool get isVerified;
  @override
  @JsonKey(name: 'is_either_matched')
  bool? get isEitherMatched;
  @override
  @JsonKey(name: 'kan_first_name')
  String? get kanFirstName;
  @override
  @JsonKey(name: 'kan_last_name')
  String? get kanLastName;
  @override
  @JsonKey(name: 'kat_first_name')
  String? get katFirstName;
  @override
  @JsonKey(name: 'kat_last_name')
  String? get katLastName;
  @override
  @JsonKey(name: 'customer_level')
  String? get customerLevel;
  @override
  @JsonKey(name: 'is_notification')
  bool? get isNotification;
  @override
  @JsonKey(ignore: true)
  _$$UserDataImplCopyWith<_$UserDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
