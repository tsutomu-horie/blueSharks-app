// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'member.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Member _$MemberFromJson(Map<String, dynamic> json) {
  return _Member.fromJson(json);
}

/// @nodoc
mixin _$Member {
  @HiveField(0)
  int get id => throw _privateConstructorUsedError;
  @HiveField(1)
  String get date => throw _privateConstructorUsedError;
  @HiveField(2)
  String get modified => throw _privateConstructorUsedError;
  @HiveField(3)
  String get slug => throw _privateConstructorUsedError;
  @HiveField(4)
  String get status => throw _privateConstructorUsedError;
  @HiveField(5)
  String get type => throw _privateConstructorUsedError;
  @HiveField(6)
  String get link => throw _privateConstructorUsedError;
  @HiveField(7)
  Title get title => throw _privateConstructorUsedError;
  @HiveField(12)
  String? get playerNameKatakana => throw _privateConstructorUsedError;
  @HiveField(8)
  int? get categoryId => throw _privateConstructorUsedError;
  @HiveField(9)
  String? get categorySlug => throw _privateConstructorUsedError;
  @HiveField(10)
  String? get categoryName => throw _privateConstructorUsedError;
  @HiveField(11)
  CustomField? get custom_field => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MemberCopyWith<Member> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MemberCopyWith<$Res> {
  factory $MemberCopyWith(Member value, $Res Function(Member) then) =
      _$MemberCopyWithImpl<$Res, Member>;
  @useResult
  $Res call(
      {@HiveField(0) int id,
      @HiveField(1) String date,
      @HiveField(2) String modified,
      @HiveField(3) String slug,
      @HiveField(4) String status,
      @HiveField(5) String type,
      @HiveField(6) String link,
      @HiveField(7) Title title,
      @HiveField(12) String? playerNameKatakana,
      @HiveField(8) int? categoryId,
      @HiveField(9) String? categorySlug,
      @HiveField(10) String? categoryName,
      @HiveField(11) CustomField? custom_field});

  $TitleCopyWith<$Res> get title;
  $CustomFieldCopyWith<$Res>? get custom_field;
}

/// @nodoc
class _$MemberCopyWithImpl<$Res, $Val extends Member>
    implements $MemberCopyWith<$Res> {
  _$MemberCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? date = null,
    Object? modified = null,
    Object? slug = null,
    Object? status = null,
    Object? type = null,
    Object? link = null,
    Object? title = null,
    Object? playerNameKatakana = freezed,
    Object? categoryId = freezed,
    Object? categorySlug = freezed,
    Object? categoryName = freezed,
    Object? custom_field = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as String,
      modified: null == modified
          ? _value.modified
          : modified // ignore: cast_nullable_to_non_nullable
              as String,
      slug: null == slug
          ? _value.slug
          : slug // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      link: null == link
          ? _value.link
          : link // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as Title,
      playerNameKatakana: freezed == playerNameKatakana
          ? _value.playerNameKatakana
          : playerNameKatakana // ignore: cast_nullable_to_non_nullable
              as String?,
      categoryId: freezed == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as int?,
      categorySlug: freezed == categorySlug
          ? _value.categorySlug
          : categorySlug // ignore: cast_nullable_to_non_nullable
              as String?,
      categoryName: freezed == categoryName
          ? _value.categoryName
          : categoryName // ignore: cast_nullable_to_non_nullable
              as String?,
      custom_field: freezed == custom_field
          ? _value.custom_field
          : custom_field // ignore: cast_nullable_to_non_nullable
              as CustomField?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $TitleCopyWith<$Res> get title {
    return $TitleCopyWith<$Res>(_value.title, (value) {
      return _then(_value.copyWith(title: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $CustomFieldCopyWith<$Res>? get custom_field {
    if (_value.custom_field == null) {
      return null;
    }

    return $CustomFieldCopyWith<$Res>(_value.custom_field!, (value) {
      return _then(_value.copyWith(custom_field: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MemberImplCopyWith<$Res> implements $MemberCopyWith<$Res> {
  factory _$$MemberImplCopyWith(
          _$MemberImpl value, $Res Function(_$MemberImpl) then) =
      __$$MemberImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@HiveField(0) int id,
      @HiveField(1) String date,
      @HiveField(2) String modified,
      @HiveField(3) String slug,
      @HiveField(4) String status,
      @HiveField(5) String type,
      @HiveField(6) String link,
      @HiveField(7) Title title,
      @HiveField(12) String? playerNameKatakana,
      @HiveField(8) int? categoryId,
      @HiveField(9) String? categorySlug,
      @HiveField(10) String? categoryName,
      @HiveField(11) CustomField? custom_field});

  @override
  $TitleCopyWith<$Res> get title;
  @override
  $CustomFieldCopyWith<$Res>? get custom_field;
}

/// @nodoc
class __$$MemberImplCopyWithImpl<$Res>
    extends _$MemberCopyWithImpl<$Res, _$MemberImpl>
    implements _$$MemberImplCopyWith<$Res> {
  __$$MemberImplCopyWithImpl(
      _$MemberImpl _value, $Res Function(_$MemberImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? date = null,
    Object? modified = null,
    Object? slug = null,
    Object? status = null,
    Object? type = null,
    Object? link = null,
    Object? title = null,
    Object? playerNameKatakana = freezed,
    Object? categoryId = freezed,
    Object? categorySlug = freezed,
    Object? categoryName = freezed,
    Object? custom_field = freezed,
  }) {
    return _then(_$MemberImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as String,
      modified: null == modified
          ? _value.modified
          : modified // ignore: cast_nullable_to_non_nullable
              as String,
      slug: null == slug
          ? _value.slug
          : slug // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      link: null == link
          ? _value.link
          : link // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as Title,
      playerNameKatakana: freezed == playerNameKatakana
          ? _value.playerNameKatakana
          : playerNameKatakana // ignore: cast_nullable_to_non_nullable
              as String?,
      categoryId: freezed == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as int?,
      categorySlug: freezed == categorySlug
          ? _value.categorySlug
          : categorySlug // ignore: cast_nullable_to_non_nullable
              as String?,
      categoryName: freezed == categoryName
          ? _value.categoryName
          : categoryName // ignore: cast_nullable_to_non_nullable
              as String?,
      custom_field: freezed == custom_field
          ? _value.custom_field
          : custom_field // ignore: cast_nullable_to_non_nullable
              as CustomField?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MemberImpl implements _Member {
  _$MemberImpl(
      {@HiveField(0) required this.id,
      @HiveField(1) required this.date,
      @HiveField(2) required this.modified,
      @HiveField(3) required this.slug,
      @HiveField(4) required this.status,
      @HiveField(5) required this.type,
      @HiveField(6) required this.link,
      @HiveField(7) required this.title,
      @HiveField(12) this.playerNameKatakana,
      @HiveField(8) required this.categoryId,
      @HiveField(9) required this.categorySlug,
      @HiveField(10) required this.categoryName,
      @HiveField(11) required this.custom_field});

  factory _$MemberImpl.fromJson(Map<String, dynamic> json) =>
      _$$MemberImplFromJson(json);

  @override
  @HiveField(0)
  final int id;
  @override
  @HiveField(1)
  final String date;
  @override
  @HiveField(2)
  final String modified;
  @override
  @HiveField(3)
  final String slug;
  @override
  @HiveField(4)
  final String status;
  @override
  @HiveField(5)
  final String type;
  @override
  @HiveField(6)
  final String link;
  @override
  @HiveField(7)
  final Title title;
  @override
  @HiveField(12)
  final String? playerNameKatakana;
  @override
  @HiveField(8)
  final int? categoryId;
  @override
  @HiveField(9)
  final String? categorySlug;
  @override
  @HiveField(10)
  final String? categoryName;
  @override
  @HiveField(11)
  final CustomField? custom_field;

  @override
  String toString() {
    return 'Member(id: $id, date: $date, modified: $modified, slug: $slug, status: $status, type: $type, link: $link, title: $title, playerNameKatakana: $playerNameKatakana, categoryId: $categoryId, categorySlug: $categorySlug, categoryName: $categoryName, custom_field: $custom_field)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MemberImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.modified, modified) ||
                other.modified == modified) &&
            (identical(other.slug, slug) || other.slug == slug) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.link, link) || other.link == link) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.playerNameKatakana, playerNameKatakana) ||
                other.playerNameKatakana == playerNameKatakana) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.categorySlug, categorySlug) ||
                other.categorySlug == categorySlug) &&
            (identical(other.categoryName, categoryName) ||
                other.categoryName == categoryName) &&
            (identical(other.custom_field, custom_field) ||
                other.custom_field == custom_field));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      date,
      modified,
      slug,
      status,
      type,
      link,
      title,
      playerNameKatakana,
      categoryId,
      categorySlug,
      categoryName,
      custom_field);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MemberImplCopyWith<_$MemberImpl> get copyWith =>
      __$$MemberImplCopyWithImpl<_$MemberImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MemberImplToJson(
      this,
    );
  }
}

abstract class _Member implements Member {
  factory _Member(
      {@HiveField(0) required final int id,
      @HiveField(1) required final String date,
      @HiveField(2) required final String modified,
      @HiveField(3) required final String slug,
      @HiveField(4) required final String status,
      @HiveField(5) required final String type,
      @HiveField(6) required final String link,
      @HiveField(7) required final Title title,
      @HiveField(12) final String? playerNameKatakana,
      @HiveField(8) required final int? categoryId,
      @HiveField(9) required final String? categorySlug,
      @HiveField(10) required final String? categoryName,
      @HiveField(11) required final CustomField? custom_field}) = _$MemberImpl;

  factory _Member.fromJson(Map<String, dynamic> json) = _$MemberImpl.fromJson;

  @override
  @HiveField(0)
  int get id;
  @override
  @HiveField(1)
  String get date;
  @override
  @HiveField(2)
  String get modified;
  @override
  @HiveField(3)
  String get slug;
  @override
  @HiveField(4)
  String get status;
  @override
  @HiveField(5)
  String get type;
  @override
  @HiveField(6)
  String get link;
  @override
  @HiveField(7)
  Title get title;
  @override
  @HiveField(12)
  String? get playerNameKatakana;
  @override
  @HiveField(8)
  int? get categoryId;
  @override
  @HiveField(9)
  String? get categorySlug;
  @override
  @HiveField(10)
  String? get categoryName;
  @override
  @HiveField(11)
  CustomField? get custom_field;
  @override
  @JsonKey(ignore: true)
  _$$MemberImplCopyWith<_$MemberImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CombineMember _$CombineMemberFromJson(Map<String, dynamic> json) {
  return _CombineMember.fromJson(json);
}

/// @nodoc
mixin _$CombineMember {
  @HiveField(0)
  String get playerName => throw _privateConstructorUsedError;
  @HiveField(1)
  String get position =>
      throw _privateConstructorUsedError; // e.g., hooker, scrumhalf, etc.
  @HiveField(2)
  String get parentPosition =>
      throw _privateConstructorUsedError; // e.g., forward, back, staff
  @HiveField(3)
  int get id => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CombineMemberCopyWith<CombineMember> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CombineMemberCopyWith<$Res> {
  factory $CombineMemberCopyWith(
          CombineMember value, $Res Function(CombineMember) then) =
      _$CombineMemberCopyWithImpl<$Res, CombineMember>;
  @useResult
  $Res call(
      {@HiveField(0) String playerName,
      @HiveField(1) String position,
      @HiveField(2) String parentPosition,
      @HiveField(3) int id});
}

/// @nodoc
class _$CombineMemberCopyWithImpl<$Res, $Val extends CombineMember>
    implements $CombineMemberCopyWith<$Res> {
  _$CombineMemberCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? playerName = null,
    Object? position = null,
    Object? parentPosition = null,
    Object? id = null,
  }) {
    return _then(_value.copyWith(
      playerName: null == playerName
          ? _value.playerName
          : playerName // ignore: cast_nullable_to_non_nullable
              as String,
      position: null == position
          ? _value.position
          : position // ignore: cast_nullable_to_non_nullable
              as String,
      parentPosition: null == parentPosition
          ? _value.parentPosition
          : parentPosition // ignore: cast_nullable_to_non_nullable
              as String,
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CombineMemberImplCopyWith<$Res>
    implements $CombineMemberCopyWith<$Res> {
  factory _$$CombineMemberImplCopyWith(
          _$CombineMemberImpl value, $Res Function(_$CombineMemberImpl) then) =
      __$$CombineMemberImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@HiveField(0) String playerName,
      @HiveField(1) String position,
      @HiveField(2) String parentPosition,
      @HiveField(3) int id});
}

/// @nodoc
class __$$CombineMemberImplCopyWithImpl<$Res>
    extends _$CombineMemberCopyWithImpl<$Res, _$CombineMemberImpl>
    implements _$$CombineMemberImplCopyWith<$Res> {
  __$$CombineMemberImplCopyWithImpl(
      _$CombineMemberImpl _value, $Res Function(_$CombineMemberImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? playerName = null,
    Object? position = null,
    Object? parentPosition = null,
    Object? id = null,
  }) {
    return _then(_$CombineMemberImpl(
      playerName: null == playerName
          ? _value.playerName
          : playerName // ignore: cast_nullable_to_non_nullable
              as String,
      position: null == position
          ? _value.position
          : position // ignore: cast_nullable_to_non_nullable
              as String,
      parentPosition: null == parentPosition
          ? _value.parentPosition
          : parentPosition // ignore: cast_nullable_to_non_nullable
              as String,
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CombineMemberImpl implements _CombineMember {
  _$CombineMemberImpl(
      {@HiveField(0) required this.playerName,
      @HiveField(1) required this.position,
      @HiveField(2) required this.parentPosition,
      @HiveField(3) required this.id});

  factory _$CombineMemberImpl.fromJson(Map<String, dynamic> json) =>
      _$$CombineMemberImplFromJson(json);

  @override
  @HiveField(0)
  final String playerName;
  @override
  @HiveField(1)
  final String position;
// e.g., hooker, scrumhalf, etc.
  @override
  @HiveField(2)
  final String parentPosition;
// e.g., forward, back, staff
  @override
  @HiveField(3)
  final int id;

  @override
  String toString() {
    return 'CombineMember(playerName: $playerName, position: $position, parentPosition: $parentPosition, id: $id)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CombineMemberImpl &&
            (identical(other.playerName, playerName) ||
                other.playerName == playerName) &&
            (identical(other.position, position) ||
                other.position == position) &&
            (identical(other.parentPosition, parentPosition) ||
                other.parentPosition == parentPosition) &&
            (identical(other.id, id) || other.id == id));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, playerName, position, parentPosition, id);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CombineMemberImplCopyWith<_$CombineMemberImpl> get copyWith =>
      __$$CombineMemberImplCopyWithImpl<_$CombineMemberImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CombineMemberImplToJson(
      this,
    );
  }
}

abstract class _CombineMember implements CombineMember {
  factory _CombineMember(
      {@HiveField(0) required final String playerName,
      @HiveField(1) required final String position,
      @HiveField(2) required final String parentPosition,
      @HiveField(3) required final int id}) = _$CombineMemberImpl;

  factory _CombineMember.fromJson(Map<String, dynamic> json) =
      _$CombineMemberImpl.fromJson;

  @override
  @HiveField(0)
  String get playerName;
  @override
  @HiveField(1)
  String get position;
  @override // e.g., hooker, scrumhalf, etc.
  @HiveField(2)
  String get parentPosition;
  @override // e.g., forward, back, staff
  @HiveField(3)
  int get id;
  @override
  @JsonKey(ignore: true)
  _$$CombineMemberImplCopyWith<_$CombineMemberImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
