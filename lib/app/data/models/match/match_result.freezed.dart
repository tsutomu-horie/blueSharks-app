// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'match_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

MatchResult _$MatchResultFromJson(Map<String, dynamic> json) {
  return _MatchResult.fromJson(json);
}

/// @nodoc
mixin _$MatchResult {
  int get id => throw _privateConstructorUsedError;
  int get count => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String get link => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get slug => throw _privateConstructorUsedError;
  String get taxonomy => throw _privateConstructorUsedError;
  int get parent => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MatchResultCopyWith<MatchResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MatchResultCopyWith<$Res> {
  factory $MatchResultCopyWith(
          MatchResult value, $Res Function(MatchResult) then) =
      _$MatchResultCopyWithImpl<$Res, MatchResult>;
  @useResult
  $Res call(
      {int id,
      int count,
      String description,
      String link,
      String name,
      String slug,
      String taxonomy,
      int parent});
}

/// @nodoc
class _$MatchResultCopyWithImpl<$Res, $Val extends MatchResult>
    implements $MatchResultCopyWith<$Res> {
  _$MatchResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? count = null,
    Object? description = null,
    Object? link = null,
    Object? name = null,
    Object? slug = null,
    Object? taxonomy = null,
    Object? parent = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      count: null == count
          ? _value.count
          : count // ignore: cast_nullable_to_non_nullable
              as int,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      link: null == link
          ? _value.link
          : link // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      slug: null == slug
          ? _value.slug
          : slug // ignore: cast_nullable_to_non_nullable
              as String,
      taxonomy: null == taxonomy
          ? _value.taxonomy
          : taxonomy // ignore: cast_nullable_to_non_nullable
              as String,
      parent: null == parent
          ? _value.parent
          : parent // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MatchResultImplCopyWith<$Res>
    implements $MatchResultCopyWith<$Res> {
  factory _$$MatchResultImplCopyWith(
          _$MatchResultImpl value, $Res Function(_$MatchResultImpl) then) =
      __$$MatchResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      int count,
      String description,
      String link,
      String name,
      String slug,
      String taxonomy,
      int parent});
}

/// @nodoc
class __$$MatchResultImplCopyWithImpl<$Res>
    extends _$MatchResultCopyWithImpl<$Res, _$MatchResultImpl>
    implements _$$MatchResultImplCopyWith<$Res> {
  __$$MatchResultImplCopyWithImpl(
      _$MatchResultImpl _value, $Res Function(_$MatchResultImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? count = null,
    Object? description = null,
    Object? link = null,
    Object? name = null,
    Object? slug = null,
    Object? taxonomy = null,
    Object? parent = null,
  }) {
    return _then(_$MatchResultImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      count: null == count
          ? _value.count
          : count // ignore: cast_nullable_to_non_nullable
              as int,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      link: null == link
          ? _value.link
          : link // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      slug: null == slug
          ? _value.slug
          : slug // ignore: cast_nullable_to_non_nullable
              as String,
      taxonomy: null == taxonomy
          ? _value.taxonomy
          : taxonomy // ignore: cast_nullable_to_non_nullable
              as String,
      parent: null == parent
          ? _value.parent
          : parent // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MatchResultImpl implements _MatchResult {
  _$MatchResultImpl(
      {required this.id,
      required this.count,
      required this.description,
      required this.link,
      required this.name,
      required this.slug,
      required this.taxonomy,
      required this.parent});

  factory _$MatchResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$MatchResultImplFromJson(json);

  @override
  final int id;
  @override
  final int count;
  @override
  final String description;
  @override
  final String link;
  @override
  final String name;
  @override
  final String slug;
  @override
  final String taxonomy;
  @override
  final int parent;

  @override
  String toString() {
    return 'MatchResult(id: $id, count: $count, description: $description, link: $link, name: $name, slug: $slug, taxonomy: $taxonomy, parent: $parent)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MatchResultImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.count, count) || other.count == count) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.link, link) || other.link == link) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.slug, slug) || other.slug == slug) &&
            (identical(other.taxonomy, taxonomy) ||
                other.taxonomy == taxonomy) &&
            (identical(other.parent, parent) || other.parent == parent));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, count, description, link, name, slug, taxonomy, parent);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MatchResultImplCopyWith<_$MatchResultImpl> get copyWith =>
      __$$MatchResultImplCopyWithImpl<_$MatchResultImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MatchResultImplToJson(
      this,
    );
  }
}

abstract class _MatchResult implements MatchResult {
  factory _MatchResult(
      {required final int id,
      required final int count,
      required final String description,
      required final String link,
      required final String name,
      required final String slug,
      required final String taxonomy,
      required final int parent}) = _$MatchResultImpl;

  factory _MatchResult.fromJson(Map<String, dynamic> json) =
      _$MatchResultImpl.fromJson;

  @override
  int get id;
  @override
  int get count;
  @override
  String get description;
  @override
  String get link;
  @override
  String get name;
  @override
  String get slug;
  @override
  String get taxonomy;
  @override
  int get parent;
  @override
  @JsonKey(ignore: true)
  _$$MatchResultImplCopyWith<_$MatchResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MatchResultBySeason _$MatchResultBySeasonFromJson(Map<String, dynamic> json) {
  return _MatchResultBySeason.fromJson(json);
}

/// @nodoc
mixin _$MatchResultBySeason {
  int get id => throw _privateConstructorUsedError;
  String get date => throw _privateConstructorUsedError;
  String get date_gmt => throw _privateConstructorUsedError;
  String get modified => throw _privateConstructorUsedError;
  String get modified_gmt => throw _privateConstructorUsedError;
  String get slug => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  String get link => throw _privateConstructorUsedError;
  int get author => throw _privateConstructorUsedError;
  Rendered get title => throw _privateConstructorUsedError;
  int get featured_media => throw _privateConstructorUsedError;
  String get comment_status => throw _privateConstructorUsedError;
  String get ping_status => throw _privateConstructorUsedError;
  bool get sticky => throw _privateConstructorUsedError;
  String get template => throw _privateConstructorUsedError;
  String get format => throw _privateConstructorUsedError;
  List<int> get categories => throw _privateConstructorUsedError;
  List<dynamic> get tags => throw _privateConstructorUsedError;
  String? get jetpack_featured_media_url => throw _privateConstructorUsedError;
  bool? get jetpack_sharing_enabled => throw _privateConstructorUsedError;
  String? get jetpack_shortlink => throw _privateConstructorUsedError;
  CustomField get custom_field => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MatchResultBySeasonCopyWith<MatchResultBySeason> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MatchResultBySeasonCopyWith<$Res> {
  factory $MatchResultBySeasonCopyWith(
          MatchResultBySeason value, $Res Function(MatchResultBySeason) then) =
      _$MatchResultBySeasonCopyWithImpl<$Res, MatchResultBySeason>;
  @useResult
  $Res call(
      {int id,
      String date,
      String date_gmt,
      String modified,
      String modified_gmt,
      String slug,
      String status,
      String type,
      String link,
      int author,
      Rendered title,
      int featured_media,
      String comment_status,
      String ping_status,
      bool sticky,
      String template,
      String format,
      List<int> categories,
      List<dynamic> tags,
      String? jetpack_featured_media_url,
      bool? jetpack_sharing_enabled,
      String? jetpack_shortlink,
      CustomField custom_field});

  $RenderedCopyWith<$Res> get title;
  $CustomFieldCopyWith<$Res> get custom_field;
}

/// @nodoc
class _$MatchResultBySeasonCopyWithImpl<$Res, $Val extends MatchResultBySeason>
    implements $MatchResultBySeasonCopyWith<$Res> {
  _$MatchResultBySeasonCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? date = null,
    Object? date_gmt = null,
    Object? modified = null,
    Object? modified_gmt = null,
    Object? slug = null,
    Object? status = null,
    Object? type = null,
    Object? link = null,
    Object? author = null,
    Object? title = null,
    Object? featured_media = null,
    Object? comment_status = null,
    Object? ping_status = null,
    Object? sticky = null,
    Object? template = null,
    Object? format = null,
    Object? categories = null,
    Object? tags = null,
    Object? jetpack_featured_media_url = freezed,
    Object? jetpack_sharing_enabled = freezed,
    Object? jetpack_shortlink = freezed,
    Object? custom_field = null,
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
      date_gmt: null == date_gmt
          ? _value.date_gmt
          : date_gmt // ignore: cast_nullable_to_non_nullable
              as String,
      modified: null == modified
          ? _value.modified
          : modified // ignore: cast_nullable_to_non_nullable
              as String,
      modified_gmt: null == modified_gmt
          ? _value.modified_gmt
          : modified_gmt // ignore: cast_nullable_to_non_nullable
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
      author: null == author
          ? _value.author
          : author // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as Rendered,
      featured_media: null == featured_media
          ? _value.featured_media
          : featured_media // ignore: cast_nullable_to_non_nullable
              as int,
      comment_status: null == comment_status
          ? _value.comment_status
          : comment_status // ignore: cast_nullable_to_non_nullable
              as String,
      ping_status: null == ping_status
          ? _value.ping_status
          : ping_status // ignore: cast_nullable_to_non_nullable
              as String,
      sticky: null == sticky
          ? _value.sticky
          : sticky // ignore: cast_nullable_to_non_nullable
              as bool,
      template: null == template
          ? _value.template
          : template // ignore: cast_nullable_to_non_nullable
              as String,
      format: null == format
          ? _value.format
          : format // ignore: cast_nullable_to_non_nullable
              as String,
      categories: null == categories
          ? _value.categories
          : categories // ignore: cast_nullable_to_non_nullable
              as List<int>,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<dynamic>,
      jetpack_featured_media_url: freezed == jetpack_featured_media_url
          ? _value.jetpack_featured_media_url
          : jetpack_featured_media_url // ignore: cast_nullable_to_non_nullable
              as String?,
      jetpack_sharing_enabled: freezed == jetpack_sharing_enabled
          ? _value.jetpack_sharing_enabled
          : jetpack_sharing_enabled // ignore: cast_nullable_to_non_nullable
              as bool?,
      jetpack_shortlink: freezed == jetpack_shortlink
          ? _value.jetpack_shortlink
          : jetpack_shortlink // ignore: cast_nullable_to_non_nullable
              as String?,
      custom_field: null == custom_field
          ? _value.custom_field
          : custom_field // ignore: cast_nullable_to_non_nullable
              as CustomField,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $RenderedCopyWith<$Res> get title {
    return $RenderedCopyWith<$Res>(_value.title, (value) {
      return _then(_value.copyWith(title: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $CustomFieldCopyWith<$Res> get custom_field {
    return $CustomFieldCopyWith<$Res>(_value.custom_field, (value) {
      return _then(_value.copyWith(custom_field: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MatchResultBySeasonImplCopyWith<$Res>
    implements $MatchResultBySeasonCopyWith<$Res> {
  factory _$$MatchResultBySeasonImplCopyWith(_$MatchResultBySeasonImpl value,
          $Res Function(_$MatchResultBySeasonImpl) then) =
      __$$MatchResultBySeasonImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String date,
      String date_gmt,
      String modified,
      String modified_gmt,
      String slug,
      String status,
      String type,
      String link,
      int author,
      Rendered title,
      int featured_media,
      String comment_status,
      String ping_status,
      bool sticky,
      String template,
      String format,
      List<int> categories,
      List<dynamic> tags,
      String? jetpack_featured_media_url,
      bool? jetpack_sharing_enabled,
      String? jetpack_shortlink,
      CustomField custom_field});

  @override
  $RenderedCopyWith<$Res> get title;
  @override
  $CustomFieldCopyWith<$Res> get custom_field;
}

/// @nodoc
class __$$MatchResultBySeasonImplCopyWithImpl<$Res>
    extends _$MatchResultBySeasonCopyWithImpl<$Res, _$MatchResultBySeasonImpl>
    implements _$$MatchResultBySeasonImplCopyWith<$Res> {
  __$$MatchResultBySeasonImplCopyWithImpl(_$MatchResultBySeasonImpl _value,
      $Res Function(_$MatchResultBySeasonImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? date = null,
    Object? date_gmt = null,
    Object? modified = null,
    Object? modified_gmt = null,
    Object? slug = null,
    Object? status = null,
    Object? type = null,
    Object? link = null,
    Object? author = null,
    Object? title = null,
    Object? featured_media = null,
    Object? comment_status = null,
    Object? ping_status = null,
    Object? sticky = null,
    Object? template = null,
    Object? format = null,
    Object? categories = null,
    Object? tags = null,
    Object? jetpack_featured_media_url = freezed,
    Object? jetpack_sharing_enabled = freezed,
    Object? jetpack_shortlink = freezed,
    Object? custom_field = null,
  }) {
    return _then(_$MatchResultBySeasonImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as String,
      date_gmt: null == date_gmt
          ? _value.date_gmt
          : date_gmt // ignore: cast_nullable_to_non_nullable
              as String,
      modified: null == modified
          ? _value.modified
          : modified // ignore: cast_nullable_to_non_nullable
              as String,
      modified_gmt: null == modified_gmt
          ? _value.modified_gmt
          : modified_gmt // ignore: cast_nullable_to_non_nullable
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
      author: null == author
          ? _value.author
          : author // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as Rendered,
      featured_media: null == featured_media
          ? _value.featured_media
          : featured_media // ignore: cast_nullable_to_non_nullable
              as int,
      comment_status: null == comment_status
          ? _value.comment_status
          : comment_status // ignore: cast_nullable_to_non_nullable
              as String,
      ping_status: null == ping_status
          ? _value.ping_status
          : ping_status // ignore: cast_nullable_to_non_nullable
              as String,
      sticky: null == sticky
          ? _value.sticky
          : sticky // ignore: cast_nullable_to_non_nullable
              as bool,
      template: null == template
          ? _value.template
          : template // ignore: cast_nullable_to_non_nullable
              as String,
      format: null == format
          ? _value.format
          : format // ignore: cast_nullable_to_non_nullable
              as String,
      categories: null == categories
          ? _value._categories
          : categories // ignore: cast_nullable_to_non_nullable
              as List<int>,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<dynamic>,
      jetpack_featured_media_url: freezed == jetpack_featured_media_url
          ? _value.jetpack_featured_media_url
          : jetpack_featured_media_url // ignore: cast_nullable_to_non_nullable
              as String?,
      jetpack_sharing_enabled: freezed == jetpack_sharing_enabled
          ? _value.jetpack_sharing_enabled
          : jetpack_sharing_enabled // ignore: cast_nullable_to_non_nullable
              as bool?,
      jetpack_shortlink: freezed == jetpack_shortlink
          ? _value.jetpack_shortlink
          : jetpack_shortlink // ignore: cast_nullable_to_non_nullable
              as String?,
      custom_field: null == custom_field
          ? _value.custom_field
          : custom_field // ignore: cast_nullable_to_non_nullable
              as CustomField,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MatchResultBySeasonImpl implements _MatchResultBySeason {
  _$MatchResultBySeasonImpl(
      {required this.id,
      required this.date,
      required this.date_gmt,
      required this.modified,
      required this.modified_gmt,
      required this.slug,
      required this.status,
      required this.type,
      required this.link,
      required this.author,
      required this.title,
      required this.featured_media,
      required this.comment_status,
      required this.ping_status,
      required this.sticky,
      required this.template,
      required this.format,
      required final List<int> categories,
      required final List<dynamic> tags,
      required this.jetpack_featured_media_url,
      required this.jetpack_sharing_enabled,
      required this.jetpack_shortlink,
      required this.custom_field})
      : _categories = categories,
        _tags = tags;

  factory _$MatchResultBySeasonImpl.fromJson(Map<String, dynamic> json) =>
      _$$MatchResultBySeasonImplFromJson(json);

  @override
  final int id;
  @override
  final String date;
  @override
  final String date_gmt;
  @override
  final String modified;
  @override
  final String modified_gmt;
  @override
  final String slug;
  @override
  final String status;
  @override
  final String type;
  @override
  final String link;
  @override
  final int author;
  @override
  final Rendered title;
  @override
  final int featured_media;
  @override
  final String comment_status;
  @override
  final String ping_status;
  @override
  final bool sticky;
  @override
  final String template;
  @override
  final String format;
  final List<int> _categories;
  @override
  List<int> get categories {
    if (_categories is EqualUnmodifiableListView) return _categories;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_categories);
  }

  final List<dynamic> _tags;
  @override
  List<dynamic> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  final String? jetpack_featured_media_url;
  @override
  final bool? jetpack_sharing_enabled;
  @override
  final String? jetpack_shortlink;
  @override
  final CustomField custom_field;

  @override
  String toString() {
    return 'MatchResultBySeason(id: $id, date: $date, date_gmt: $date_gmt, modified: $modified, modified_gmt: $modified_gmt, slug: $slug, status: $status, type: $type, link: $link, author: $author, title: $title, featured_media: $featured_media, comment_status: $comment_status, ping_status: $ping_status, sticky: $sticky, template: $template, format: $format, categories: $categories, tags: $tags, jetpack_featured_media_url: $jetpack_featured_media_url, jetpack_sharing_enabled: $jetpack_sharing_enabled, jetpack_shortlink: $jetpack_shortlink, custom_field: $custom_field)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MatchResultBySeasonImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.date_gmt, date_gmt) ||
                other.date_gmt == date_gmt) &&
            (identical(other.modified, modified) ||
                other.modified == modified) &&
            (identical(other.modified_gmt, modified_gmt) ||
                other.modified_gmt == modified_gmt) &&
            (identical(other.slug, slug) || other.slug == slug) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.link, link) || other.link == link) &&
            (identical(other.author, author) || other.author == author) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.featured_media, featured_media) ||
                other.featured_media == featured_media) &&
            (identical(other.comment_status, comment_status) ||
                other.comment_status == comment_status) &&
            (identical(other.ping_status, ping_status) ||
                other.ping_status == ping_status) &&
            (identical(other.sticky, sticky) || other.sticky == sticky) &&
            (identical(other.template, template) ||
                other.template == template) &&
            (identical(other.format, format) || other.format == format) &&
            const DeepCollectionEquality()
                .equals(other._categories, _categories) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.jetpack_featured_media_url,
                    jetpack_featured_media_url) ||
                other.jetpack_featured_media_url ==
                    jetpack_featured_media_url) &&
            (identical(
                    other.jetpack_sharing_enabled, jetpack_sharing_enabled) ||
                other.jetpack_sharing_enabled == jetpack_sharing_enabled) &&
            (identical(other.jetpack_shortlink, jetpack_shortlink) ||
                other.jetpack_shortlink == jetpack_shortlink) &&
            (identical(other.custom_field, custom_field) ||
                other.custom_field == custom_field));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        date,
        date_gmt,
        modified,
        modified_gmt,
        slug,
        status,
        type,
        link,
        author,
        title,
        featured_media,
        comment_status,
        ping_status,
        sticky,
        template,
        format,
        const DeepCollectionEquality().hash(_categories),
        const DeepCollectionEquality().hash(_tags),
        jetpack_featured_media_url,
        jetpack_sharing_enabled,
        jetpack_shortlink,
        custom_field
      ]);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MatchResultBySeasonImplCopyWith<_$MatchResultBySeasonImpl> get copyWith =>
      __$$MatchResultBySeasonImplCopyWithImpl<_$MatchResultBySeasonImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MatchResultBySeasonImplToJson(
      this,
    );
  }
}

abstract class _MatchResultBySeason implements MatchResultBySeason {
  factory _MatchResultBySeason(
      {required final int id,
      required final String date,
      required final String date_gmt,
      required final String modified,
      required final String modified_gmt,
      required final String slug,
      required final String status,
      required final String type,
      required final String link,
      required final int author,
      required final Rendered title,
      required final int featured_media,
      required final String comment_status,
      required final String ping_status,
      required final bool sticky,
      required final String template,
      required final String format,
      required final List<int> categories,
      required final List<dynamic> tags,
      required final String? jetpack_featured_media_url,
      required final bool? jetpack_sharing_enabled,
      required final String? jetpack_shortlink,
      required final CustomField custom_field}) = _$MatchResultBySeasonImpl;

  factory _MatchResultBySeason.fromJson(Map<String, dynamic> json) =
      _$MatchResultBySeasonImpl.fromJson;

  @override
  int get id;
  @override
  String get date;
  @override
  String get date_gmt;
  @override
  String get modified;
  @override
  String get modified_gmt;
  @override
  String get slug;
  @override
  String get status;
  @override
  String get type;
  @override
  String get link;
  @override
  int get author;
  @override
  Rendered get title;
  @override
  int get featured_media;
  @override
  String get comment_status;
  @override
  String get ping_status;
  @override
  bool get sticky;
  @override
  String get template;
  @override
  String get format;
  @override
  List<int> get categories;
  @override
  List<dynamic> get tags;
  @override
  String? get jetpack_featured_media_url;
  @override
  bool? get jetpack_sharing_enabled;
  @override
  String? get jetpack_shortlink;
  @override
  CustomField get custom_field;
  @override
  @JsonKey(ignore: true)
  _$$MatchResultBySeasonImplCopyWith<_$MatchResultBySeasonImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CustomField _$CustomFieldFromJson(Map<String, dynamic> json) {
  return _CustomField.fromJson(json);
}

/// @nodoc
mixin _$CustomField {
  @JsonKey(name: 'game_date')
  List<String>? get gameDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'game_time')
  List<String>? get gameTime => throw _privateConstructorUsedError;
  List<String>? get location => throw _privateConstructorUsedError;
  List<String>? get team_1 => throw _privateConstructorUsedError;
  List<String>? get team_logo_1 => throw _privateConstructorUsedError;
  List<String>? get team_2 => throw _privateConstructorUsedError;
  List<String>? get team_logo_2 => throw _privateConstructorUsedError;
  List<String>? get game_result => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CustomFieldCopyWith<CustomField> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CustomFieldCopyWith<$Res> {
  factory $CustomFieldCopyWith(
          CustomField value, $Res Function(CustomField) then) =
      _$CustomFieldCopyWithImpl<$Res, CustomField>;
  @useResult
  $Res call(
      {@JsonKey(name: 'game_date') List<String>? gameDate,
      @JsonKey(name: 'game_time') List<String>? gameTime,
      List<String>? location,
      List<String>? team_1,
      List<String>? team_logo_1,
      List<String>? team_2,
      List<String>? team_logo_2,
      List<String>? game_result});
}

/// @nodoc
class _$CustomFieldCopyWithImpl<$Res, $Val extends CustomField>
    implements $CustomFieldCopyWith<$Res> {
  _$CustomFieldCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? gameDate = freezed,
    Object? gameTime = freezed,
    Object? location = freezed,
    Object? team_1 = freezed,
    Object? team_logo_1 = freezed,
    Object? team_2 = freezed,
    Object? team_logo_2 = freezed,
    Object? game_result = freezed,
  }) {
    return _then(_value.copyWith(
      gameDate: freezed == gameDate
          ? _value.gameDate
          : gameDate // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      gameTime: freezed == gameTime
          ? _value.gameTime
          : gameTime // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      location: freezed == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      team_1: freezed == team_1
          ? _value.team_1
          : team_1 // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      team_logo_1: freezed == team_logo_1
          ? _value.team_logo_1
          : team_logo_1 // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      team_2: freezed == team_2
          ? _value.team_2
          : team_2 // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      team_logo_2: freezed == team_logo_2
          ? _value.team_logo_2
          : team_logo_2 // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      game_result: freezed == game_result
          ? _value.game_result
          : game_result // ignore: cast_nullable_to_non_nullable
              as List<String>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CustomFieldImplCopyWith<$Res>
    implements $CustomFieldCopyWith<$Res> {
  factory _$$CustomFieldImplCopyWith(
          _$CustomFieldImpl value, $Res Function(_$CustomFieldImpl) then) =
      __$$CustomFieldImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'game_date') List<String>? gameDate,
      @JsonKey(name: 'game_time') List<String>? gameTime,
      List<String>? location,
      List<String>? team_1,
      List<String>? team_logo_1,
      List<String>? team_2,
      List<String>? team_logo_2,
      List<String>? game_result});
}

/// @nodoc
class __$$CustomFieldImplCopyWithImpl<$Res>
    extends _$CustomFieldCopyWithImpl<$Res, _$CustomFieldImpl>
    implements _$$CustomFieldImplCopyWith<$Res> {
  __$$CustomFieldImplCopyWithImpl(
      _$CustomFieldImpl _value, $Res Function(_$CustomFieldImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? gameDate = freezed,
    Object? gameTime = freezed,
    Object? location = freezed,
    Object? team_1 = freezed,
    Object? team_logo_1 = freezed,
    Object? team_2 = freezed,
    Object? team_logo_2 = freezed,
    Object? game_result = freezed,
  }) {
    return _then(_$CustomFieldImpl(
      gameDate: freezed == gameDate
          ? _value._gameDate
          : gameDate // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      gameTime: freezed == gameTime
          ? _value._gameTime
          : gameTime // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      location: freezed == location
          ? _value._location
          : location // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      team_1: freezed == team_1
          ? _value._team_1
          : team_1 // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      team_logo_1: freezed == team_logo_1
          ? _value._team_logo_1
          : team_logo_1 // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      team_2: freezed == team_2
          ? _value._team_2
          : team_2 // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      team_logo_2: freezed == team_logo_2
          ? _value._team_logo_2
          : team_logo_2 // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      game_result: freezed == game_result
          ? _value._game_result
          : game_result // ignore: cast_nullable_to_non_nullable
              as List<String>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CustomFieldImpl implements _CustomField {
  _$CustomFieldImpl(
      {@JsonKey(name: 'game_date') required final List<String>? gameDate,
      @JsonKey(name: 'game_time') required final List<String>? gameTime,
      required final List<String>? location,
      required final List<String>? team_1,
      final List<String>? team_logo_1,
      required final List<String>? team_2,
      required final List<String>? team_logo_2,
      required final List<String>? game_result})
      : _gameDate = gameDate,
        _gameTime = gameTime,
        _location = location,
        _team_1 = team_1,
        _team_logo_1 = team_logo_1,
        _team_2 = team_2,
        _team_logo_2 = team_logo_2,
        _game_result = game_result;

  factory _$CustomFieldImpl.fromJson(Map<String, dynamic> json) =>
      _$$CustomFieldImplFromJson(json);

  final List<String>? _gameDate;
  @override
  @JsonKey(name: 'game_date')
  List<String>? get gameDate {
    final value = _gameDate;
    if (value == null) return null;
    if (_gameDate is EqualUnmodifiableListView) return _gameDate;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _gameTime;
  @override
  @JsonKey(name: 'game_time')
  List<String>? get gameTime {
    final value = _gameTime;
    if (value == null) return null;
    if (_gameTime is EqualUnmodifiableListView) return _gameTime;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _location;
  @override
  List<String>? get location {
    final value = _location;
    if (value == null) return null;
    if (_location is EqualUnmodifiableListView) return _location;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _team_1;
  @override
  List<String>? get team_1 {
    final value = _team_1;
    if (value == null) return null;
    if (_team_1 is EqualUnmodifiableListView) return _team_1;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _team_logo_1;
  @override
  List<String>? get team_logo_1 {
    final value = _team_logo_1;
    if (value == null) return null;
    if (_team_logo_1 is EqualUnmodifiableListView) return _team_logo_1;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _team_2;
  @override
  List<String>? get team_2 {
    final value = _team_2;
    if (value == null) return null;
    if (_team_2 is EqualUnmodifiableListView) return _team_2;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _team_logo_2;
  @override
  List<String>? get team_logo_2 {
    final value = _team_logo_2;
    if (value == null) return null;
    if (_team_logo_2 is EqualUnmodifiableListView) return _team_logo_2;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _game_result;
  @override
  List<String>? get game_result {
    final value = _game_result;
    if (value == null) return null;
    if (_game_result is EqualUnmodifiableListView) return _game_result;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'CustomField(gameDate: $gameDate, gameTime: $gameTime, location: $location, team_1: $team_1, team_logo_1: $team_logo_1, team_2: $team_2, team_logo_2: $team_logo_2, game_result: $game_result)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CustomFieldImpl &&
            const DeepCollectionEquality().equals(other._gameDate, _gameDate) &&
            const DeepCollectionEquality().equals(other._gameTime, _gameTime) &&
            const DeepCollectionEquality().equals(other._location, _location) &&
            const DeepCollectionEquality().equals(other._team_1, _team_1) &&
            const DeepCollectionEquality()
                .equals(other._team_logo_1, _team_logo_1) &&
            const DeepCollectionEquality().equals(other._team_2, _team_2) &&
            const DeepCollectionEquality()
                .equals(other._team_logo_2, _team_logo_2) &&
            const DeepCollectionEquality()
                .equals(other._game_result, _game_result));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_gameDate),
      const DeepCollectionEquality().hash(_gameTime),
      const DeepCollectionEquality().hash(_location),
      const DeepCollectionEquality().hash(_team_1),
      const DeepCollectionEquality().hash(_team_logo_1),
      const DeepCollectionEquality().hash(_team_2),
      const DeepCollectionEquality().hash(_team_logo_2),
      const DeepCollectionEquality().hash(_game_result));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CustomFieldImplCopyWith<_$CustomFieldImpl> get copyWith =>
      __$$CustomFieldImplCopyWithImpl<_$CustomFieldImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CustomFieldImplToJson(
      this,
    );
  }
}

abstract class _CustomField implements CustomField {
  factory _CustomField(
      {@JsonKey(name: 'game_date') required final List<String>? gameDate,
      @JsonKey(name: 'game_time') required final List<String>? gameTime,
      required final List<String>? location,
      required final List<String>? team_1,
      final List<String>? team_logo_1,
      required final List<String>? team_2,
      required final List<String>? team_logo_2,
      required final List<String>? game_result}) = _$CustomFieldImpl;

  factory _CustomField.fromJson(Map<String, dynamic> json) =
      _$CustomFieldImpl.fromJson;

  @override
  @JsonKey(name: 'game_date')
  List<String>? get gameDate;
  @override
  @JsonKey(name: 'game_time')
  List<String>? get gameTime;
  @override
  List<String>? get location;
  @override
  List<String>? get team_1;
  @override
  List<String>? get team_logo_1;
  @override
  List<String>? get team_2;
  @override
  List<String>? get team_logo_2;
  @override
  List<String>? get game_result;
  @override
  @JsonKey(ignore: true)
  _$$CustomFieldImplCopyWith<_$CustomFieldImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Rendered _$RenderedFromJson(Map<String, dynamic> json) {
  return _Rendered.fromJson(json);
}

/// @nodoc
mixin _$Rendered {
  String get rendered => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $RenderedCopyWith<Rendered> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RenderedCopyWith<$Res> {
  factory $RenderedCopyWith(Rendered value, $Res Function(Rendered) then) =
      _$RenderedCopyWithImpl<$Res, Rendered>;
  @useResult
  $Res call({String rendered});
}

/// @nodoc
class _$RenderedCopyWithImpl<$Res, $Val extends Rendered>
    implements $RenderedCopyWith<$Res> {
  _$RenderedCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? rendered = null,
  }) {
    return _then(_value.copyWith(
      rendered: null == rendered
          ? _value.rendered
          : rendered // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RenderedImplCopyWith<$Res>
    implements $RenderedCopyWith<$Res> {
  factory _$$RenderedImplCopyWith(
          _$RenderedImpl value, $Res Function(_$RenderedImpl) then) =
      __$$RenderedImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String rendered});
}

/// @nodoc
class __$$RenderedImplCopyWithImpl<$Res>
    extends _$RenderedCopyWithImpl<$Res, _$RenderedImpl>
    implements _$$RenderedImplCopyWith<$Res> {
  __$$RenderedImplCopyWithImpl(
      _$RenderedImpl _value, $Res Function(_$RenderedImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? rendered = null,
  }) {
    return _then(_$RenderedImpl(
      rendered: null == rendered
          ? _value.rendered
          : rendered // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RenderedImpl implements _Rendered {
  _$RenderedImpl({required this.rendered});

  factory _$RenderedImpl.fromJson(Map<String, dynamic> json) =>
      _$$RenderedImplFromJson(json);

  @override
  final String rendered;

  @override
  String toString() {
    return 'Rendered(rendered: $rendered)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RenderedImpl &&
            (identical(other.rendered, rendered) ||
                other.rendered == rendered));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, rendered);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RenderedImplCopyWith<_$RenderedImpl> get copyWith =>
      __$$RenderedImplCopyWithImpl<_$RenderedImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RenderedImplToJson(
      this,
    );
  }
}

abstract class _Rendered implements Rendered {
  factory _Rendered({required final String rendered}) = _$RenderedImpl;

  factory _Rendered.fromJson(Map<String, dynamic> json) =
      _$RenderedImpl.fromJson;

  @override
  String get rendered;
  @override
  @JsonKey(ignore: true)
  _$$RenderedImplCopyWith<_$RenderedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
