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

Category _$CategoryFromJson(Map<String, dynamic> json) {
  return _MatchResult.fromJson(json);
}

/// @nodoc
mixin _$Category {
  @HiveField(0)
  int get id => throw _privateConstructorUsedError;
  @HiveField(1)
  int get count => throw _privateConstructorUsedError;
  @HiveField(2)
  String get description => throw _privateConstructorUsedError;
  @HiveField(3)
  String get link => throw _privateConstructorUsedError;
  @HiveField(4)
  String get name => throw _privateConstructorUsedError;
  @HiveField(5)
  String get slug => throw _privateConstructorUsedError;
  @HiveField(6)
  String get taxonomy => throw _privateConstructorUsedError;
  @HiveField(7)
  int get parent => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CategoryCopyWith<Category> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CategoryCopyWith<$Res> {
  factory $CategoryCopyWith(Category value, $Res Function(Category) then) =
      _$CategoryCopyWithImpl<$Res, Category>;
  @useResult
  $Res call(
      {@HiveField(0) int id,
      @HiveField(1) int count,
      @HiveField(2) String description,
      @HiveField(3) String link,
      @HiveField(4) String name,
      @HiveField(5) String slug,
      @HiveField(6) String taxonomy,
      @HiveField(7) int parent});
}

/// @nodoc
class _$CategoryCopyWithImpl<$Res, $Val extends Category>
    implements $CategoryCopyWith<$Res> {
  _$CategoryCopyWithImpl(this._value, this._then);

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
    implements $CategoryCopyWith<$Res> {
  factory _$$MatchResultImplCopyWith(
          _$MatchResultImpl value, $Res Function(_$MatchResultImpl) then) =
      __$$MatchResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@HiveField(0) int id,
      @HiveField(1) int count,
      @HiveField(2) String description,
      @HiveField(3) String link,
      @HiveField(4) String name,
      @HiveField(5) String slug,
      @HiveField(6) String taxonomy,
      @HiveField(7) int parent});
}

/// @nodoc
class __$$MatchResultImplCopyWithImpl<$Res>
    extends _$CategoryCopyWithImpl<$Res, _$MatchResultImpl>
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
  const _$MatchResultImpl(
      {@HiveField(0) required this.id,
      @HiveField(1) required this.count,
      @HiveField(2) required this.description,
      @HiveField(3) required this.link,
      @HiveField(4) required this.name,
      @HiveField(5) required this.slug,
      @HiveField(6) required this.taxonomy,
      @HiveField(7) required this.parent});

  factory _$MatchResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$MatchResultImplFromJson(json);

  @override
  @HiveField(0)
  final int id;
  @override
  @HiveField(1)
  final int count;
  @override
  @HiveField(2)
  final String description;
  @override
  @HiveField(3)
  final String link;
  @override
  @HiveField(4)
  final String name;
  @override
  @HiveField(5)
  final String slug;
  @override
  @HiveField(6)
  final String taxonomy;
  @override
  @HiveField(7)
  final int parent;

  @override
  String toString() {
    return 'Category(id: $id, count: $count, description: $description, link: $link, name: $name, slug: $slug, taxonomy: $taxonomy, parent: $parent)';
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

abstract class _MatchResult implements Category {
  const factory _MatchResult(
      {@HiveField(0) required final int id,
      @HiveField(1) required final int count,
      @HiveField(2) required final String description,
      @HiveField(3) required final String link,
      @HiveField(4) required final String name,
      @HiveField(5) required final String slug,
      @HiveField(6) required final String taxonomy,
      @HiveField(7) required final int parent}) = _$MatchResultImpl;

  factory _MatchResult.fromJson(Map<String, dynamic> json) =
      _$MatchResultImpl.fromJson;

  @override
  @HiveField(0)
  int get id;
  @override
  @HiveField(1)
  int get count;
  @override
  @HiveField(2)
  String get description;
  @override
  @HiveField(3)
  String get link;
  @override
  @HiveField(4)
  String get name;
  @override
  @HiveField(5)
  String get slug;
  @override
  @HiveField(6)
  String get taxonomy;
  @override
  @HiveField(7)
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
  Rendered get content => throw _privateConstructorUsedError;

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
      CustomField custom_field,
      Rendered content});

  $RenderedCopyWith<$Res> get title;
  $CustomFieldCopyWith<$Res> get custom_field;
  $RenderedCopyWith<$Res> get content;
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
    Object? content = null,
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
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as Rendered,
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

  @override
  @pragma('vm:prefer-inline')
  $RenderedCopyWith<$Res> get content {
    return $RenderedCopyWith<$Res>(_value.content, (value) {
      return _then(_value.copyWith(content: value) as $Val);
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
      CustomField custom_field,
      Rendered content});

  @override
  $RenderedCopyWith<$Res> get title;
  @override
  $CustomFieldCopyWith<$Res> get custom_field;
  @override
  $RenderedCopyWith<$Res> get content;
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
    Object? content = null,
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
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as Rendered,
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
      required this.custom_field,
      required this.content})
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
  final Rendered content;

  @override
  String toString() {
    return 'MatchResultBySeason(id: $id, date: $date, date_gmt: $date_gmt, modified: $modified, modified_gmt: $modified_gmt, slug: $slug, status: $status, type: $type, link: $link, author: $author, title: $title, featured_media: $featured_media, comment_status: $comment_status, ping_status: $ping_status, sticky: $sticky, template: $template, format: $format, categories: $categories, tags: $tags, jetpack_featured_media_url: $jetpack_featured_media_url, jetpack_sharing_enabled: $jetpack_sharing_enabled, jetpack_shortlink: $jetpack_shortlink, custom_field: $custom_field, content: $content)';
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
                other.custom_field == custom_field) &&
            (identical(other.content, content) || other.content == content));
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
        custom_field,
        content
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
      required final CustomField custom_field,
      required final Rendered content}) = _$MatchResultBySeasonImpl;

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
  Rendered get content;
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
  @HiveField(0)
  @JsonKey(name: 'game_date')
  List<String>? get gameDate => throw _privateConstructorUsedError;
  @HiveField(1)
  @JsonKey(name: 'game_time')
  List<String>? get gameTime => throw _privateConstructorUsedError;
  @HiveField(2)
  List<String>? get location => throw _privateConstructorUsedError;
  @HiveField(3)
  List<String>? get team_1 => throw _privateConstructorUsedError;
  @HiveField(4)
  List<String>? get team_logo_1 => throw _privateConstructorUsedError;
  @HiveField(5)
  List<String>? get team_2 => throw _privateConstructorUsedError;
  @HiveField(6)
  List<String>? get team_logo_2 => throw _privateConstructorUsedError;
  @HiveField(7)
  List<String>? get game_result => throw _privateConstructorUsedError;
  @HiveField(8)
  List<String>? get team_score_1 => throw _privateConstructorUsedError;
  @HiveField(9)
  List<String>? get team_score_2 => throw _privateConstructorUsedError;
  @HiveField(10)
  List<String>? get team_T_first_half_1 => throw _privateConstructorUsedError;
  @HiveField(11)
  List<String>? get team_T_second_half_1 => throw _privateConstructorUsedError;
  @HiveField(12)
  List<String>? get team_G_first_half_1 => throw _privateConstructorUsedError;
  @HiveField(13)
  List<String>? get team_G_second_half_1 => throw _privateConstructorUsedError;
  @HiveField(14)
  List<String>? get team_PG_first_half_1 => throw _privateConstructorUsedError;
  @HiveField(15)
  List<String>? get team_PG_second_half_1 => throw _privateConstructorUsedError;
  @HiveField(16)
  List<String>? get team_DG_first_half_1 => throw _privateConstructorUsedError;
  @HiveField(17)
  List<String>? get team_DG_second_half_1 => throw _privateConstructorUsedError;
  @HiveField(18)
  List<String>? get team_RESULT_first_half_1 =>
      throw _privateConstructorUsedError;
  @HiveField(19)
  List<String>? get team_RESULT_second_half_1 =>
      throw _privateConstructorUsedError;
  @HiveField(20)
  List<String>? get team_T_first_half_2 => throw _privateConstructorUsedError;
  @HiveField(21)
  List<String>? get team_T_second_half_2 => throw _privateConstructorUsedError;
  @HiveField(22)
  List<String>? get team_G_first_half_2 => throw _privateConstructorUsedError;
  @HiveField(23)
  List<String>? get team_G_second_half_2 => throw _privateConstructorUsedError;
  @HiveField(24)
  List<String>? get team_PG_first_half_2 => throw _privateConstructorUsedError;
  @HiveField(25)
  List<String>? get team_PG_second_half_2 => throw _privateConstructorUsedError;
  @HiveField(26)
  List<String>? get team_DG_first_half_2 => throw _privateConstructorUsedError;
  @HiveField(27)
  List<String>? get team_DG_second_half_2 => throw _privateConstructorUsedError;
  @HiveField(28)
  List<String>? get team_RESULT_first_half_2 =>
      throw _privateConstructorUsedError;
  @HiveField(29)
  List<String>? get team_RESULT_second_half_2 =>
      throw _privateConstructorUsedError;
  @HiveField(30)
  List<String>? get member_starting => throw _privateConstructorUsedError;
  @HiveField(31)
  List<String>? get member_reserves => throw _privateConstructorUsedError;
  @HiveField(32)
  List<String>? get photos => throw _privateConstructorUsedError;
  @HiveField(33)
  List<String>? get game_serial => throw _privateConstructorUsedError;
  @HiveField(34)
  List<String>? get member_captain =>
      throw _privateConstructorUsedError; //specific for player
  @HiveField(35)
  List<String>? get profile_image_1 =>
      throw _privateConstructorUsedError; //for profile picture
  @HiveField(36)
  List<String>? get main_image => throw _privateConstructorUsedError;
  @HiveField(37)
  List<String>? get profile_image_2 => throw _privateConstructorUsedError;
  @HiveField(38)
  List<String>? get graph_image => throw _privateConstructorUsedError;
  @HiveField(39)
  List<String>? get position_image => throw _privateConstructorUsedError;
  @HiveField(40)
  List<String>? get data_position => throw _privateConstructorUsedError;
  @HiveField(65)
  List<String>? get data_play_position => throw _privateConstructorUsedError;
  @HiveField(41)
  List<String>? get data_number => throw _privateConstructorUsedError;
  @HiveField(42)
  List<String>? get data_birthday => throw _privateConstructorUsedError;
  @HiveField(43)
  List<String>? get data_height_weight => throw _privateConstructorUsedError;
  @HiveField(44)
  List<String>? get data_birthplace => throw _privateConstructorUsedError;
  @HiveField(45)
  List<String>? get data_school => throw _privateConstructorUsedError;
  @HiveField(46)
  List<String>? get data_highschool => throw _privateConstructorUsedError;
  @HiveField(47)
  List<String>? get data_university => throw _privateConstructorUsedError;
  @HiveField(48)
  List<String>? get data_career => throw _privateConstructorUsedError;
  @HiveField(49)
  List<String>? get data_belong => throw _privateConstructorUsedError;
  @HiveField(50)
  List<String>? get data_award => throw _privateConstructorUsedError;
  @HiveField(51)
  List<String>? get data_enrolledyears => throw _privateConstructorUsedError;
  @HiveField(52)
  List<String>? get data_caps => throw _privateConstructorUsedError;
  @HiveField(53)
  List<String>? get words_nickname => throw _privateConstructorUsedError;
  @HiveField(54)
  List<String>? get words_dream_child_age => throw _privateConstructorUsedError;
  @HiveField(55)
  List<String>? get words_opportunity => throw _privateConstructorUsedError;
  @HiveField(56)
  List<String>? get words_playsseason => throw _privateConstructorUsedError;
  @HiveField(57)
  List<String>? get words_goodplay => throw _privateConstructorUsedError;
  @HiveField(58)
  List<String>? get words_wish => throw _privateConstructorUsedError;
  @HiveField(59)
  List<String>? get words_myboom => throw _privateConstructorUsedError;
  @HiveField(60)
  List<String>? get words_favoritebrand => throw _privateConstructorUsedError;
  @HiveField(61)
  List<String>? get words_color => throw _privateConstructorUsedError;
  @HiveField(62)
  List<String>? get words_shop => throw _privateConstructorUsedError;
  @HiveField(63)
  List<String>? get words_gift => throw _privateConstructorUsedError;
  @HiveField(64)
  List<String>? get words_favoritefood => throw _privateConstructorUsedError;
  @HiveField(66)
  List<String>? get words_localfood => throw _privateConstructorUsedError;

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
      {@HiveField(0) @JsonKey(name: 'game_date') List<String>? gameDate,
      @HiveField(1) @JsonKey(name: 'game_time') List<String>? gameTime,
      @HiveField(2) List<String>? location,
      @HiveField(3) List<String>? team_1,
      @HiveField(4) List<String>? team_logo_1,
      @HiveField(5) List<String>? team_2,
      @HiveField(6) List<String>? team_logo_2,
      @HiveField(7) List<String>? game_result,
      @HiveField(8) List<String>? team_score_1,
      @HiveField(9) List<String>? team_score_2,
      @HiveField(10) List<String>? team_T_first_half_1,
      @HiveField(11) List<String>? team_T_second_half_1,
      @HiveField(12) List<String>? team_G_first_half_1,
      @HiveField(13) List<String>? team_G_second_half_1,
      @HiveField(14) List<String>? team_PG_first_half_1,
      @HiveField(15) List<String>? team_PG_second_half_1,
      @HiveField(16) List<String>? team_DG_first_half_1,
      @HiveField(17) List<String>? team_DG_second_half_1,
      @HiveField(18) List<String>? team_RESULT_first_half_1,
      @HiveField(19) List<String>? team_RESULT_second_half_1,
      @HiveField(20) List<String>? team_T_first_half_2,
      @HiveField(21) List<String>? team_T_second_half_2,
      @HiveField(22) List<String>? team_G_first_half_2,
      @HiveField(23) List<String>? team_G_second_half_2,
      @HiveField(24) List<String>? team_PG_first_half_2,
      @HiveField(25) List<String>? team_PG_second_half_2,
      @HiveField(26) List<String>? team_DG_first_half_2,
      @HiveField(27) List<String>? team_DG_second_half_2,
      @HiveField(28) List<String>? team_RESULT_first_half_2,
      @HiveField(29) List<String>? team_RESULT_second_half_2,
      @HiveField(30) List<String>? member_starting,
      @HiveField(31) List<String>? member_reserves,
      @HiveField(32) List<String>? photos,
      @HiveField(33) List<String>? game_serial,
      @HiveField(34) List<String>? member_captain,
      @HiveField(35) List<String>? profile_image_1,
      @HiveField(36) List<String>? main_image,
      @HiveField(37) List<String>? profile_image_2,
      @HiveField(38) List<String>? graph_image,
      @HiveField(39) List<String>? position_image,
      @HiveField(40) List<String>? data_position,
      @HiveField(65) List<String>? data_play_position,
      @HiveField(41) List<String>? data_number,
      @HiveField(42) List<String>? data_birthday,
      @HiveField(43) List<String>? data_height_weight,
      @HiveField(44) List<String>? data_birthplace,
      @HiveField(45) List<String>? data_school,
      @HiveField(46) List<String>? data_highschool,
      @HiveField(47) List<String>? data_university,
      @HiveField(48) List<String>? data_career,
      @HiveField(49) List<String>? data_belong,
      @HiveField(50) List<String>? data_award,
      @HiveField(51) List<String>? data_enrolledyears,
      @HiveField(52) List<String>? data_caps,
      @HiveField(53) List<String>? words_nickname,
      @HiveField(54) List<String>? words_dream_child_age,
      @HiveField(55) List<String>? words_opportunity,
      @HiveField(56) List<String>? words_playsseason,
      @HiveField(57) List<String>? words_goodplay,
      @HiveField(58) List<String>? words_wish,
      @HiveField(59) List<String>? words_myboom,
      @HiveField(60) List<String>? words_favoritebrand,
      @HiveField(61) List<String>? words_color,
      @HiveField(62) List<String>? words_shop,
      @HiveField(63) List<String>? words_gift,
      @HiveField(64) List<String>? words_favoritefood,
      @HiveField(66) List<String>? words_localfood});
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
    Object? team_score_1 = freezed,
    Object? team_score_2 = freezed,
    Object? team_T_first_half_1 = freezed,
    Object? team_T_second_half_1 = freezed,
    Object? team_G_first_half_1 = freezed,
    Object? team_G_second_half_1 = freezed,
    Object? team_PG_first_half_1 = freezed,
    Object? team_PG_second_half_1 = freezed,
    Object? team_DG_first_half_1 = freezed,
    Object? team_DG_second_half_1 = freezed,
    Object? team_RESULT_first_half_1 = freezed,
    Object? team_RESULT_second_half_1 = freezed,
    Object? team_T_first_half_2 = freezed,
    Object? team_T_second_half_2 = freezed,
    Object? team_G_first_half_2 = freezed,
    Object? team_G_second_half_2 = freezed,
    Object? team_PG_first_half_2 = freezed,
    Object? team_PG_second_half_2 = freezed,
    Object? team_DG_first_half_2 = freezed,
    Object? team_DG_second_half_2 = freezed,
    Object? team_RESULT_first_half_2 = freezed,
    Object? team_RESULT_second_half_2 = freezed,
    Object? member_starting = freezed,
    Object? member_reserves = freezed,
    Object? photos = freezed,
    Object? game_serial = freezed,
    Object? member_captain = freezed,
    Object? profile_image_1 = freezed,
    Object? main_image = freezed,
    Object? profile_image_2 = freezed,
    Object? graph_image = freezed,
    Object? position_image = freezed,
    Object? data_position = freezed,
    Object? data_play_position = freezed,
    Object? data_number = freezed,
    Object? data_birthday = freezed,
    Object? data_height_weight = freezed,
    Object? data_birthplace = freezed,
    Object? data_school = freezed,
    Object? data_highschool = freezed,
    Object? data_university = freezed,
    Object? data_career = freezed,
    Object? data_belong = freezed,
    Object? data_award = freezed,
    Object? data_enrolledyears = freezed,
    Object? data_caps = freezed,
    Object? words_nickname = freezed,
    Object? words_dream_child_age = freezed,
    Object? words_opportunity = freezed,
    Object? words_playsseason = freezed,
    Object? words_goodplay = freezed,
    Object? words_wish = freezed,
    Object? words_myboom = freezed,
    Object? words_favoritebrand = freezed,
    Object? words_color = freezed,
    Object? words_shop = freezed,
    Object? words_gift = freezed,
    Object? words_favoritefood = freezed,
    Object? words_localfood = freezed,
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
      team_score_1: freezed == team_score_1
          ? _value.team_score_1
          : team_score_1 // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      team_score_2: freezed == team_score_2
          ? _value.team_score_2
          : team_score_2 // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      team_T_first_half_1: freezed == team_T_first_half_1
          ? _value.team_T_first_half_1
          : team_T_first_half_1 // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      team_T_second_half_1: freezed == team_T_second_half_1
          ? _value.team_T_second_half_1
          : team_T_second_half_1 // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      team_G_first_half_1: freezed == team_G_first_half_1
          ? _value.team_G_first_half_1
          : team_G_first_half_1 // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      team_G_second_half_1: freezed == team_G_second_half_1
          ? _value.team_G_second_half_1
          : team_G_second_half_1 // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      team_PG_first_half_1: freezed == team_PG_first_half_1
          ? _value.team_PG_first_half_1
          : team_PG_first_half_1 // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      team_PG_second_half_1: freezed == team_PG_second_half_1
          ? _value.team_PG_second_half_1
          : team_PG_second_half_1 // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      team_DG_first_half_1: freezed == team_DG_first_half_1
          ? _value.team_DG_first_half_1
          : team_DG_first_half_1 // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      team_DG_second_half_1: freezed == team_DG_second_half_1
          ? _value.team_DG_second_half_1
          : team_DG_second_half_1 // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      team_RESULT_first_half_1: freezed == team_RESULT_first_half_1
          ? _value.team_RESULT_first_half_1
          : team_RESULT_first_half_1 // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      team_RESULT_second_half_1: freezed == team_RESULT_second_half_1
          ? _value.team_RESULT_second_half_1
          : team_RESULT_second_half_1 // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      team_T_first_half_2: freezed == team_T_first_half_2
          ? _value.team_T_first_half_2
          : team_T_first_half_2 // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      team_T_second_half_2: freezed == team_T_second_half_2
          ? _value.team_T_second_half_2
          : team_T_second_half_2 // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      team_G_first_half_2: freezed == team_G_first_half_2
          ? _value.team_G_first_half_2
          : team_G_first_half_2 // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      team_G_second_half_2: freezed == team_G_second_half_2
          ? _value.team_G_second_half_2
          : team_G_second_half_2 // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      team_PG_first_half_2: freezed == team_PG_first_half_2
          ? _value.team_PG_first_half_2
          : team_PG_first_half_2 // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      team_PG_second_half_2: freezed == team_PG_second_half_2
          ? _value.team_PG_second_half_2
          : team_PG_second_half_2 // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      team_DG_first_half_2: freezed == team_DG_first_half_2
          ? _value.team_DG_first_half_2
          : team_DG_first_half_2 // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      team_DG_second_half_2: freezed == team_DG_second_half_2
          ? _value.team_DG_second_half_2
          : team_DG_second_half_2 // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      team_RESULT_first_half_2: freezed == team_RESULT_first_half_2
          ? _value.team_RESULT_first_half_2
          : team_RESULT_first_half_2 // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      team_RESULT_second_half_2: freezed == team_RESULT_second_half_2
          ? _value.team_RESULT_second_half_2
          : team_RESULT_second_half_2 // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      member_starting: freezed == member_starting
          ? _value.member_starting
          : member_starting // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      member_reserves: freezed == member_reserves
          ? _value.member_reserves
          : member_reserves // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      photos: freezed == photos
          ? _value.photos
          : photos // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      game_serial: freezed == game_serial
          ? _value.game_serial
          : game_serial // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      member_captain: freezed == member_captain
          ? _value.member_captain
          : member_captain // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      profile_image_1: freezed == profile_image_1
          ? _value.profile_image_1
          : profile_image_1 // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      main_image: freezed == main_image
          ? _value.main_image
          : main_image // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      profile_image_2: freezed == profile_image_2
          ? _value.profile_image_2
          : profile_image_2 // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      graph_image: freezed == graph_image
          ? _value.graph_image
          : graph_image // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      position_image: freezed == position_image
          ? _value.position_image
          : position_image // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      data_position: freezed == data_position
          ? _value.data_position
          : data_position // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      data_play_position: freezed == data_play_position
          ? _value.data_play_position
          : data_play_position // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      data_number: freezed == data_number
          ? _value.data_number
          : data_number // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      data_birthday: freezed == data_birthday
          ? _value.data_birthday
          : data_birthday // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      data_height_weight: freezed == data_height_weight
          ? _value.data_height_weight
          : data_height_weight // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      data_birthplace: freezed == data_birthplace
          ? _value.data_birthplace
          : data_birthplace // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      data_school: freezed == data_school
          ? _value.data_school
          : data_school // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      data_highschool: freezed == data_highschool
          ? _value.data_highschool
          : data_highschool // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      data_university: freezed == data_university
          ? _value.data_university
          : data_university // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      data_career: freezed == data_career
          ? _value.data_career
          : data_career // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      data_belong: freezed == data_belong
          ? _value.data_belong
          : data_belong // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      data_award: freezed == data_award
          ? _value.data_award
          : data_award // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      data_enrolledyears: freezed == data_enrolledyears
          ? _value.data_enrolledyears
          : data_enrolledyears // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      data_caps: freezed == data_caps
          ? _value.data_caps
          : data_caps // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      words_nickname: freezed == words_nickname
          ? _value.words_nickname
          : words_nickname // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      words_dream_child_age: freezed == words_dream_child_age
          ? _value.words_dream_child_age
          : words_dream_child_age // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      words_opportunity: freezed == words_opportunity
          ? _value.words_opportunity
          : words_opportunity // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      words_playsseason: freezed == words_playsseason
          ? _value.words_playsseason
          : words_playsseason // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      words_goodplay: freezed == words_goodplay
          ? _value.words_goodplay
          : words_goodplay // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      words_wish: freezed == words_wish
          ? _value.words_wish
          : words_wish // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      words_myboom: freezed == words_myboom
          ? _value.words_myboom
          : words_myboom // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      words_favoritebrand: freezed == words_favoritebrand
          ? _value.words_favoritebrand
          : words_favoritebrand // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      words_color: freezed == words_color
          ? _value.words_color
          : words_color // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      words_shop: freezed == words_shop
          ? _value.words_shop
          : words_shop // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      words_gift: freezed == words_gift
          ? _value.words_gift
          : words_gift // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      words_favoritefood: freezed == words_favoritefood
          ? _value.words_favoritefood
          : words_favoritefood // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      words_localfood: freezed == words_localfood
          ? _value.words_localfood
          : words_localfood // ignore: cast_nullable_to_non_nullable
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
      {@HiveField(0) @JsonKey(name: 'game_date') List<String>? gameDate,
      @HiveField(1) @JsonKey(name: 'game_time') List<String>? gameTime,
      @HiveField(2) List<String>? location,
      @HiveField(3) List<String>? team_1,
      @HiveField(4) List<String>? team_logo_1,
      @HiveField(5) List<String>? team_2,
      @HiveField(6) List<String>? team_logo_2,
      @HiveField(7) List<String>? game_result,
      @HiveField(8) List<String>? team_score_1,
      @HiveField(9) List<String>? team_score_2,
      @HiveField(10) List<String>? team_T_first_half_1,
      @HiveField(11) List<String>? team_T_second_half_1,
      @HiveField(12) List<String>? team_G_first_half_1,
      @HiveField(13) List<String>? team_G_second_half_1,
      @HiveField(14) List<String>? team_PG_first_half_1,
      @HiveField(15) List<String>? team_PG_second_half_1,
      @HiveField(16) List<String>? team_DG_first_half_1,
      @HiveField(17) List<String>? team_DG_second_half_1,
      @HiveField(18) List<String>? team_RESULT_first_half_1,
      @HiveField(19) List<String>? team_RESULT_second_half_1,
      @HiveField(20) List<String>? team_T_first_half_2,
      @HiveField(21) List<String>? team_T_second_half_2,
      @HiveField(22) List<String>? team_G_first_half_2,
      @HiveField(23) List<String>? team_G_second_half_2,
      @HiveField(24) List<String>? team_PG_first_half_2,
      @HiveField(25) List<String>? team_PG_second_half_2,
      @HiveField(26) List<String>? team_DG_first_half_2,
      @HiveField(27) List<String>? team_DG_second_half_2,
      @HiveField(28) List<String>? team_RESULT_first_half_2,
      @HiveField(29) List<String>? team_RESULT_second_half_2,
      @HiveField(30) List<String>? member_starting,
      @HiveField(31) List<String>? member_reserves,
      @HiveField(32) List<String>? photos,
      @HiveField(33) List<String>? game_serial,
      @HiveField(34) List<String>? member_captain,
      @HiveField(35) List<String>? profile_image_1,
      @HiveField(36) List<String>? main_image,
      @HiveField(37) List<String>? profile_image_2,
      @HiveField(38) List<String>? graph_image,
      @HiveField(39) List<String>? position_image,
      @HiveField(40) List<String>? data_position,
      @HiveField(65) List<String>? data_play_position,
      @HiveField(41) List<String>? data_number,
      @HiveField(42) List<String>? data_birthday,
      @HiveField(43) List<String>? data_height_weight,
      @HiveField(44) List<String>? data_birthplace,
      @HiveField(45) List<String>? data_school,
      @HiveField(46) List<String>? data_highschool,
      @HiveField(47) List<String>? data_university,
      @HiveField(48) List<String>? data_career,
      @HiveField(49) List<String>? data_belong,
      @HiveField(50) List<String>? data_award,
      @HiveField(51) List<String>? data_enrolledyears,
      @HiveField(52) List<String>? data_caps,
      @HiveField(53) List<String>? words_nickname,
      @HiveField(54) List<String>? words_dream_child_age,
      @HiveField(55) List<String>? words_opportunity,
      @HiveField(56) List<String>? words_playsseason,
      @HiveField(57) List<String>? words_goodplay,
      @HiveField(58) List<String>? words_wish,
      @HiveField(59) List<String>? words_myboom,
      @HiveField(60) List<String>? words_favoritebrand,
      @HiveField(61) List<String>? words_color,
      @HiveField(62) List<String>? words_shop,
      @HiveField(63) List<String>? words_gift,
      @HiveField(64) List<String>? words_favoritefood,
      @HiveField(66) List<String>? words_localfood});
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
    Object? team_score_1 = freezed,
    Object? team_score_2 = freezed,
    Object? team_T_first_half_1 = freezed,
    Object? team_T_second_half_1 = freezed,
    Object? team_G_first_half_1 = freezed,
    Object? team_G_second_half_1 = freezed,
    Object? team_PG_first_half_1 = freezed,
    Object? team_PG_second_half_1 = freezed,
    Object? team_DG_first_half_1 = freezed,
    Object? team_DG_second_half_1 = freezed,
    Object? team_RESULT_first_half_1 = freezed,
    Object? team_RESULT_second_half_1 = freezed,
    Object? team_T_first_half_2 = freezed,
    Object? team_T_second_half_2 = freezed,
    Object? team_G_first_half_2 = freezed,
    Object? team_G_second_half_2 = freezed,
    Object? team_PG_first_half_2 = freezed,
    Object? team_PG_second_half_2 = freezed,
    Object? team_DG_first_half_2 = freezed,
    Object? team_DG_second_half_2 = freezed,
    Object? team_RESULT_first_half_2 = freezed,
    Object? team_RESULT_second_half_2 = freezed,
    Object? member_starting = freezed,
    Object? member_reserves = freezed,
    Object? photos = freezed,
    Object? game_serial = freezed,
    Object? member_captain = freezed,
    Object? profile_image_1 = freezed,
    Object? main_image = freezed,
    Object? profile_image_2 = freezed,
    Object? graph_image = freezed,
    Object? position_image = freezed,
    Object? data_position = freezed,
    Object? data_play_position = freezed,
    Object? data_number = freezed,
    Object? data_birthday = freezed,
    Object? data_height_weight = freezed,
    Object? data_birthplace = freezed,
    Object? data_school = freezed,
    Object? data_highschool = freezed,
    Object? data_university = freezed,
    Object? data_career = freezed,
    Object? data_belong = freezed,
    Object? data_award = freezed,
    Object? data_enrolledyears = freezed,
    Object? data_caps = freezed,
    Object? words_nickname = freezed,
    Object? words_dream_child_age = freezed,
    Object? words_opportunity = freezed,
    Object? words_playsseason = freezed,
    Object? words_goodplay = freezed,
    Object? words_wish = freezed,
    Object? words_myboom = freezed,
    Object? words_favoritebrand = freezed,
    Object? words_color = freezed,
    Object? words_shop = freezed,
    Object? words_gift = freezed,
    Object? words_favoritefood = freezed,
    Object? words_localfood = freezed,
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
      team_score_1: freezed == team_score_1
          ? _value._team_score_1
          : team_score_1 // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      team_score_2: freezed == team_score_2
          ? _value._team_score_2
          : team_score_2 // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      team_T_first_half_1: freezed == team_T_first_half_1
          ? _value._team_T_first_half_1
          : team_T_first_half_1 // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      team_T_second_half_1: freezed == team_T_second_half_1
          ? _value._team_T_second_half_1
          : team_T_second_half_1 // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      team_G_first_half_1: freezed == team_G_first_half_1
          ? _value._team_G_first_half_1
          : team_G_first_half_1 // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      team_G_second_half_1: freezed == team_G_second_half_1
          ? _value._team_G_second_half_1
          : team_G_second_half_1 // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      team_PG_first_half_1: freezed == team_PG_first_half_1
          ? _value._team_PG_first_half_1
          : team_PG_first_half_1 // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      team_PG_second_half_1: freezed == team_PG_second_half_1
          ? _value._team_PG_second_half_1
          : team_PG_second_half_1 // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      team_DG_first_half_1: freezed == team_DG_first_half_1
          ? _value._team_DG_first_half_1
          : team_DG_first_half_1 // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      team_DG_second_half_1: freezed == team_DG_second_half_1
          ? _value._team_DG_second_half_1
          : team_DG_second_half_1 // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      team_RESULT_first_half_1: freezed == team_RESULT_first_half_1
          ? _value._team_RESULT_first_half_1
          : team_RESULT_first_half_1 // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      team_RESULT_second_half_1: freezed == team_RESULT_second_half_1
          ? _value._team_RESULT_second_half_1
          : team_RESULT_second_half_1 // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      team_T_first_half_2: freezed == team_T_first_half_2
          ? _value._team_T_first_half_2
          : team_T_first_half_2 // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      team_T_second_half_2: freezed == team_T_second_half_2
          ? _value._team_T_second_half_2
          : team_T_second_half_2 // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      team_G_first_half_2: freezed == team_G_first_half_2
          ? _value._team_G_first_half_2
          : team_G_first_half_2 // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      team_G_second_half_2: freezed == team_G_second_half_2
          ? _value._team_G_second_half_2
          : team_G_second_half_2 // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      team_PG_first_half_2: freezed == team_PG_first_half_2
          ? _value._team_PG_first_half_2
          : team_PG_first_half_2 // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      team_PG_second_half_2: freezed == team_PG_second_half_2
          ? _value._team_PG_second_half_2
          : team_PG_second_half_2 // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      team_DG_first_half_2: freezed == team_DG_first_half_2
          ? _value._team_DG_first_half_2
          : team_DG_first_half_2 // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      team_DG_second_half_2: freezed == team_DG_second_half_2
          ? _value._team_DG_second_half_2
          : team_DG_second_half_2 // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      team_RESULT_first_half_2: freezed == team_RESULT_first_half_2
          ? _value._team_RESULT_first_half_2
          : team_RESULT_first_half_2 // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      team_RESULT_second_half_2: freezed == team_RESULT_second_half_2
          ? _value._team_RESULT_second_half_2
          : team_RESULT_second_half_2 // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      member_starting: freezed == member_starting
          ? _value._member_starting
          : member_starting // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      member_reserves: freezed == member_reserves
          ? _value._member_reserves
          : member_reserves // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      photos: freezed == photos
          ? _value._photos
          : photos // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      game_serial: freezed == game_serial
          ? _value._game_serial
          : game_serial // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      member_captain: freezed == member_captain
          ? _value._member_captain
          : member_captain // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      profile_image_1: freezed == profile_image_1
          ? _value._profile_image_1
          : profile_image_1 // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      main_image: freezed == main_image
          ? _value._main_image
          : main_image // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      profile_image_2: freezed == profile_image_2
          ? _value._profile_image_2
          : profile_image_2 // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      graph_image: freezed == graph_image
          ? _value._graph_image
          : graph_image // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      position_image: freezed == position_image
          ? _value._position_image
          : position_image // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      data_position: freezed == data_position
          ? _value._data_position
          : data_position // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      data_play_position: freezed == data_play_position
          ? _value._data_play_position
          : data_play_position // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      data_number: freezed == data_number
          ? _value._data_number
          : data_number // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      data_birthday: freezed == data_birthday
          ? _value._data_birthday
          : data_birthday // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      data_height_weight: freezed == data_height_weight
          ? _value._data_height_weight
          : data_height_weight // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      data_birthplace: freezed == data_birthplace
          ? _value._data_birthplace
          : data_birthplace // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      data_school: freezed == data_school
          ? _value._data_school
          : data_school // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      data_highschool: freezed == data_highschool
          ? _value._data_highschool
          : data_highschool // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      data_university: freezed == data_university
          ? _value._data_university
          : data_university // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      data_career: freezed == data_career
          ? _value._data_career
          : data_career // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      data_belong: freezed == data_belong
          ? _value._data_belong
          : data_belong // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      data_award: freezed == data_award
          ? _value._data_award
          : data_award // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      data_enrolledyears: freezed == data_enrolledyears
          ? _value._data_enrolledyears
          : data_enrolledyears // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      data_caps: freezed == data_caps
          ? _value._data_caps
          : data_caps // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      words_nickname: freezed == words_nickname
          ? _value._words_nickname
          : words_nickname // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      words_dream_child_age: freezed == words_dream_child_age
          ? _value._words_dream_child_age
          : words_dream_child_age // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      words_opportunity: freezed == words_opportunity
          ? _value._words_opportunity
          : words_opportunity // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      words_playsseason: freezed == words_playsseason
          ? _value._words_playsseason
          : words_playsseason // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      words_goodplay: freezed == words_goodplay
          ? _value._words_goodplay
          : words_goodplay // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      words_wish: freezed == words_wish
          ? _value._words_wish
          : words_wish // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      words_myboom: freezed == words_myboom
          ? _value._words_myboom
          : words_myboom // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      words_favoritebrand: freezed == words_favoritebrand
          ? _value._words_favoritebrand
          : words_favoritebrand // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      words_color: freezed == words_color
          ? _value._words_color
          : words_color // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      words_shop: freezed == words_shop
          ? _value._words_shop
          : words_shop // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      words_gift: freezed == words_gift
          ? _value._words_gift
          : words_gift // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      words_favoritefood: freezed == words_favoritefood
          ? _value._words_favoritefood
          : words_favoritefood // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      words_localfood: freezed == words_localfood
          ? _value._words_localfood
          : words_localfood // ignore: cast_nullable_to_non_nullable
              as List<String>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CustomFieldImpl implements _CustomField {
  _$CustomFieldImpl(
      {@HiveField(0)
      @JsonKey(name: 'game_date')
      required final List<String>? gameDate,
      @HiveField(1)
      @JsonKey(name: 'game_time')
      required final List<String>? gameTime,
      @HiveField(2) required final List<String>? location,
      @HiveField(3) required final List<String>? team_1,
      @HiveField(4) final List<String>? team_logo_1,
      @HiveField(5) required final List<String>? team_2,
      @HiveField(6) required final List<String>? team_logo_2,
      @HiveField(7) required final List<String>? game_result,
      @HiveField(8) required final List<String>? team_score_1,
      @HiveField(9) required final List<String>? team_score_2,
      @HiveField(10) required final List<String>? team_T_first_half_1,
      @HiveField(11) required final List<String>? team_T_second_half_1,
      @HiveField(12) required final List<String>? team_G_first_half_1,
      @HiveField(13) required final List<String>? team_G_second_half_1,
      @HiveField(14) required final List<String>? team_PG_first_half_1,
      @HiveField(15) required final List<String>? team_PG_second_half_1,
      @HiveField(16) required final List<String>? team_DG_first_half_1,
      @HiveField(17) required final List<String>? team_DG_second_half_1,
      @HiveField(18) required final List<String>? team_RESULT_first_half_1,
      @HiveField(19) required final List<String>? team_RESULT_second_half_1,
      @HiveField(20) required final List<String>? team_T_first_half_2,
      @HiveField(21) required final List<String>? team_T_second_half_2,
      @HiveField(22) required final List<String>? team_G_first_half_2,
      @HiveField(23) required final List<String>? team_G_second_half_2,
      @HiveField(24) required final List<String>? team_PG_first_half_2,
      @HiveField(25) required final List<String>? team_PG_second_half_2,
      @HiveField(26) required final List<String>? team_DG_first_half_2,
      @HiveField(27) required final List<String>? team_DG_second_half_2,
      @HiveField(28) required final List<String>? team_RESULT_first_half_2,
      @HiveField(29) required final List<String>? team_RESULT_second_half_2,
      @HiveField(30) required final List<String>? member_starting,
      @HiveField(31) required final List<String>? member_reserves,
      @HiveField(32) required final List<String>? photos,
      @HiveField(33) required final List<String>? game_serial,
      @HiveField(34) required final List<String>? member_captain,
      @HiveField(35) final List<String>? profile_image_1,
      @HiveField(36) final List<String>? main_image,
      @HiveField(37) final List<String>? profile_image_2,
      @HiveField(38) final List<String>? graph_image,
      @HiveField(39) final List<String>? position_image,
      @HiveField(40) final List<String>? data_position,
      @HiveField(65) final List<String>? data_play_position,
      @HiveField(41) final List<String>? data_number,
      @HiveField(42) final List<String>? data_birthday,
      @HiveField(43) final List<String>? data_height_weight,
      @HiveField(44) final List<String>? data_birthplace,
      @HiveField(45) final List<String>? data_school,
      @HiveField(46) final List<String>? data_highschool,
      @HiveField(47) final List<String>? data_university,
      @HiveField(48) final List<String>? data_career,
      @HiveField(49) final List<String>? data_belong,
      @HiveField(50) final List<String>? data_award,
      @HiveField(51) final List<String>? data_enrolledyears,
      @HiveField(52) final List<String>? data_caps,
      @HiveField(53) final List<String>? words_nickname,
      @HiveField(54) final List<String>? words_dream_child_age,
      @HiveField(55) final List<String>? words_opportunity,
      @HiveField(56) final List<String>? words_playsseason,
      @HiveField(57) final List<String>? words_goodplay,
      @HiveField(58) final List<String>? words_wish,
      @HiveField(59) final List<String>? words_myboom,
      @HiveField(60) final List<String>? words_favoritebrand,
      @HiveField(61) final List<String>? words_color,
      @HiveField(62) final List<String>? words_shop,
      @HiveField(63) final List<String>? words_gift,
      @HiveField(64) final List<String>? words_favoritefood,
      @HiveField(66) final List<String>? words_localfood})
      : _gameDate = gameDate,
        _gameTime = gameTime,
        _location = location,
        _team_1 = team_1,
        _team_logo_1 = team_logo_1,
        _team_2 = team_2,
        _team_logo_2 = team_logo_2,
        _game_result = game_result,
        _team_score_1 = team_score_1,
        _team_score_2 = team_score_2,
        _team_T_first_half_1 = team_T_first_half_1,
        _team_T_second_half_1 = team_T_second_half_1,
        _team_G_first_half_1 = team_G_first_half_1,
        _team_G_second_half_1 = team_G_second_half_1,
        _team_PG_first_half_1 = team_PG_first_half_1,
        _team_PG_second_half_1 = team_PG_second_half_1,
        _team_DG_first_half_1 = team_DG_first_half_1,
        _team_DG_second_half_1 = team_DG_second_half_1,
        _team_RESULT_first_half_1 = team_RESULT_first_half_1,
        _team_RESULT_second_half_1 = team_RESULT_second_half_1,
        _team_T_first_half_2 = team_T_first_half_2,
        _team_T_second_half_2 = team_T_second_half_2,
        _team_G_first_half_2 = team_G_first_half_2,
        _team_G_second_half_2 = team_G_second_half_2,
        _team_PG_first_half_2 = team_PG_first_half_2,
        _team_PG_second_half_2 = team_PG_second_half_2,
        _team_DG_first_half_2 = team_DG_first_half_2,
        _team_DG_second_half_2 = team_DG_second_half_2,
        _team_RESULT_first_half_2 = team_RESULT_first_half_2,
        _team_RESULT_second_half_2 = team_RESULT_second_half_2,
        _member_starting = member_starting,
        _member_reserves = member_reserves,
        _photos = photos,
        _game_serial = game_serial,
        _member_captain = member_captain,
        _profile_image_1 = profile_image_1,
        _main_image = main_image,
        _profile_image_2 = profile_image_2,
        _graph_image = graph_image,
        _position_image = position_image,
        _data_position = data_position,
        _data_play_position = data_play_position,
        _data_number = data_number,
        _data_birthday = data_birthday,
        _data_height_weight = data_height_weight,
        _data_birthplace = data_birthplace,
        _data_school = data_school,
        _data_highschool = data_highschool,
        _data_university = data_university,
        _data_career = data_career,
        _data_belong = data_belong,
        _data_award = data_award,
        _data_enrolledyears = data_enrolledyears,
        _data_caps = data_caps,
        _words_nickname = words_nickname,
        _words_dream_child_age = words_dream_child_age,
        _words_opportunity = words_opportunity,
        _words_playsseason = words_playsseason,
        _words_goodplay = words_goodplay,
        _words_wish = words_wish,
        _words_myboom = words_myboom,
        _words_favoritebrand = words_favoritebrand,
        _words_color = words_color,
        _words_shop = words_shop,
        _words_gift = words_gift,
        _words_favoritefood = words_favoritefood,
        _words_localfood = words_localfood;

  factory _$CustomFieldImpl.fromJson(Map<String, dynamic> json) =>
      _$$CustomFieldImplFromJson(json);

  final List<String>? _gameDate;
  @override
  @HiveField(0)
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
  @HiveField(1)
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
  @HiveField(2)
  List<String>? get location {
    final value = _location;
    if (value == null) return null;
    if (_location is EqualUnmodifiableListView) return _location;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _team_1;
  @override
  @HiveField(3)
  List<String>? get team_1 {
    final value = _team_1;
    if (value == null) return null;
    if (_team_1 is EqualUnmodifiableListView) return _team_1;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _team_logo_1;
  @override
  @HiveField(4)
  List<String>? get team_logo_1 {
    final value = _team_logo_1;
    if (value == null) return null;
    if (_team_logo_1 is EqualUnmodifiableListView) return _team_logo_1;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _team_2;
  @override
  @HiveField(5)
  List<String>? get team_2 {
    final value = _team_2;
    if (value == null) return null;
    if (_team_2 is EqualUnmodifiableListView) return _team_2;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _team_logo_2;
  @override
  @HiveField(6)
  List<String>? get team_logo_2 {
    final value = _team_logo_2;
    if (value == null) return null;
    if (_team_logo_2 is EqualUnmodifiableListView) return _team_logo_2;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _game_result;
  @override
  @HiveField(7)
  List<String>? get game_result {
    final value = _game_result;
    if (value == null) return null;
    if (_game_result is EqualUnmodifiableListView) return _game_result;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _team_score_1;
  @override
  @HiveField(8)
  List<String>? get team_score_1 {
    final value = _team_score_1;
    if (value == null) return null;
    if (_team_score_1 is EqualUnmodifiableListView) return _team_score_1;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _team_score_2;
  @override
  @HiveField(9)
  List<String>? get team_score_2 {
    final value = _team_score_2;
    if (value == null) return null;
    if (_team_score_2 is EqualUnmodifiableListView) return _team_score_2;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _team_T_first_half_1;
  @override
  @HiveField(10)
  List<String>? get team_T_first_half_1 {
    final value = _team_T_first_half_1;
    if (value == null) return null;
    if (_team_T_first_half_1 is EqualUnmodifiableListView)
      return _team_T_first_half_1;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _team_T_second_half_1;
  @override
  @HiveField(11)
  List<String>? get team_T_second_half_1 {
    final value = _team_T_second_half_1;
    if (value == null) return null;
    if (_team_T_second_half_1 is EqualUnmodifiableListView)
      return _team_T_second_half_1;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _team_G_first_half_1;
  @override
  @HiveField(12)
  List<String>? get team_G_first_half_1 {
    final value = _team_G_first_half_1;
    if (value == null) return null;
    if (_team_G_first_half_1 is EqualUnmodifiableListView)
      return _team_G_first_half_1;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _team_G_second_half_1;
  @override
  @HiveField(13)
  List<String>? get team_G_second_half_1 {
    final value = _team_G_second_half_1;
    if (value == null) return null;
    if (_team_G_second_half_1 is EqualUnmodifiableListView)
      return _team_G_second_half_1;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _team_PG_first_half_1;
  @override
  @HiveField(14)
  List<String>? get team_PG_first_half_1 {
    final value = _team_PG_first_half_1;
    if (value == null) return null;
    if (_team_PG_first_half_1 is EqualUnmodifiableListView)
      return _team_PG_first_half_1;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _team_PG_second_half_1;
  @override
  @HiveField(15)
  List<String>? get team_PG_second_half_1 {
    final value = _team_PG_second_half_1;
    if (value == null) return null;
    if (_team_PG_second_half_1 is EqualUnmodifiableListView)
      return _team_PG_second_half_1;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _team_DG_first_half_1;
  @override
  @HiveField(16)
  List<String>? get team_DG_first_half_1 {
    final value = _team_DG_first_half_1;
    if (value == null) return null;
    if (_team_DG_first_half_1 is EqualUnmodifiableListView)
      return _team_DG_first_half_1;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _team_DG_second_half_1;
  @override
  @HiveField(17)
  List<String>? get team_DG_second_half_1 {
    final value = _team_DG_second_half_1;
    if (value == null) return null;
    if (_team_DG_second_half_1 is EqualUnmodifiableListView)
      return _team_DG_second_half_1;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _team_RESULT_first_half_1;
  @override
  @HiveField(18)
  List<String>? get team_RESULT_first_half_1 {
    final value = _team_RESULT_first_half_1;
    if (value == null) return null;
    if (_team_RESULT_first_half_1 is EqualUnmodifiableListView)
      return _team_RESULT_first_half_1;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _team_RESULT_second_half_1;
  @override
  @HiveField(19)
  List<String>? get team_RESULT_second_half_1 {
    final value = _team_RESULT_second_half_1;
    if (value == null) return null;
    if (_team_RESULT_second_half_1 is EqualUnmodifiableListView)
      return _team_RESULT_second_half_1;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _team_T_first_half_2;
  @override
  @HiveField(20)
  List<String>? get team_T_first_half_2 {
    final value = _team_T_first_half_2;
    if (value == null) return null;
    if (_team_T_first_half_2 is EqualUnmodifiableListView)
      return _team_T_first_half_2;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _team_T_second_half_2;
  @override
  @HiveField(21)
  List<String>? get team_T_second_half_2 {
    final value = _team_T_second_half_2;
    if (value == null) return null;
    if (_team_T_second_half_2 is EqualUnmodifiableListView)
      return _team_T_second_half_2;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _team_G_first_half_2;
  @override
  @HiveField(22)
  List<String>? get team_G_first_half_2 {
    final value = _team_G_first_half_2;
    if (value == null) return null;
    if (_team_G_first_half_2 is EqualUnmodifiableListView)
      return _team_G_first_half_2;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _team_G_second_half_2;
  @override
  @HiveField(23)
  List<String>? get team_G_second_half_2 {
    final value = _team_G_second_half_2;
    if (value == null) return null;
    if (_team_G_second_half_2 is EqualUnmodifiableListView)
      return _team_G_second_half_2;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _team_PG_first_half_2;
  @override
  @HiveField(24)
  List<String>? get team_PG_first_half_2 {
    final value = _team_PG_first_half_2;
    if (value == null) return null;
    if (_team_PG_first_half_2 is EqualUnmodifiableListView)
      return _team_PG_first_half_2;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _team_PG_second_half_2;
  @override
  @HiveField(25)
  List<String>? get team_PG_second_half_2 {
    final value = _team_PG_second_half_2;
    if (value == null) return null;
    if (_team_PG_second_half_2 is EqualUnmodifiableListView)
      return _team_PG_second_half_2;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _team_DG_first_half_2;
  @override
  @HiveField(26)
  List<String>? get team_DG_first_half_2 {
    final value = _team_DG_first_half_2;
    if (value == null) return null;
    if (_team_DG_first_half_2 is EqualUnmodifiableListView)
      return _team_DG_first_half_2;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _team_DG_second_half_2;
  @override
  @HiveField(27)
  List<String>? get team_DG_second_half_2 {
    final value = _team_DG_second_half_2;
    if (value == null) return null;
    if (_team_DG_second_half_2 is EqualUnmodifiableListView)
      return _team_DG_second_half_2;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _team_RESULT_first_half_2;
  @override
  @HiveField(28)
  List<String>? get team_RESULT_first_half_2 {
    final value = _team_RESULT_first_half_2;
    if (value == null) return null;
    if (_team_RESULT_first_half_2 is EqualUnmodifiableListView)
      return _team_RESULT_first_half_2;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _team_RESULT_second_half_2;
  @override
  @HiveField(29)
  List<String>? get team_RESULT_second_half_2 {
    final value = _team_RESULT_second_half_2;
    if (value == null) return null;
    if (_team_RESULT_second_half_2 is EqualUnmodifiableListView)
      return _team_RESULT_second_half_2;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _member_starting;
  @override
  @HiveField(30)
  List<String>? get member_starting {
    final value = _member_starting;
    if (value == null) return null;
    if (_member_starting is EqualUnmodifiableListView) return _member_starting;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _member_reserves;
  @override
  @HiveField(31)
  List<String>? get member_reserves {
    final value = _member_reserves;
    if (value == null) return null;
    if (_member_reserves is EqualUnmodifiableListView) return _member_reserves;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _photos;
  @override
  @HiveField(32)
  List<String>? get photos {
    final value = _photos;
    if (value == null) return null;
    if (_photos is EqualUnmodifiableListView) return _photos;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _game_serial;
  @override
  @HiveField(33)
  List<String>? get game_serial {
    final value = _game_serial;
    if (value == null) return null;
    if (_game_serial is EqualUnmodifiableListView) return _game_serial;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _member_captain;
  @override
  @HiveField(34)
  List<String>? get member_captain {
    final value = _member_captain;
    if (value == null) return null;
    if (_member_captain is EqualUnmodifiableListView) return _member_captain;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

//specific for player
  final List<String>? _profile_image_1;
//specific for player
  @override
  @HiveField(35)
  List<String>? get profile_image_1 {
    final value = _profile_image_1;
    if (value == null) return null;
    if (_profile_image_1 is EqualUnmodifiableListView) return _profile_image_1;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

//for profile picture
  final List<String>? _main_image;
//for profile picture
  @override
  @HiveField(36)
  List<String>? get main_image {
    final value = _main_image;
    if (value == null) return null;
    if (_main_image is EqualUnmodifiableListView) return _main_image;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _profile_image_2;
  @override
  @HiveField(37)
  List<String>? get profile_image_2 {
    final value = _profile_image_2;
    if (value == null) return null;
    if (_profile_image_2 is EqualUnmodifiableListView) return _profile_image_2;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _graph_image;
  @override
  @HiveField(38)
  List<String>? get graph_image {
    final value = _graph_image;
    if (value == null) return null;
    if (_graph_image is EqualUnmodifiableListView) return _graph_image;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _position_image;
  @override
  @HiveField(39)
  List<String>? get position_image {
    final value = _position_image;
    if (value == null) return null;
    if (_position_image is EqualUnmodifiableListView) return _position_image;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _data_position;
  @override
  @HiveField(40)
  List<String>? get data_position {
    final value = _data_position;
    if (value == null) return null;
    if (_data_position is EqualUnmodifiableListView) return _data_position;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _data_play_position;
  @override
  @HiveField(65)
  List<String>? get data_play_position {
    final value = _data_play_position;
    if (value == null) return null;
    if (_data_play_position is EqualUnmodifiableListView)
      return _data_play_position;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _data_number;
  @override
  @HiveField(41)
  List<String>? get data_number {
    final value = _data_number;
    if (value == null) return null;
    if (_data_number is EqualUnmodifiableListView) return _data_number;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _data_birthday;
  @override
  @HiveField(42)
  List<String>? get data_birthday {
    final value = _data_birthday;
    if (value == null) return null;
    if (_data_birthday is EqualUnmodifiableListView) return _data_birthday;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _data_height_weight;
  @override
  @HiveField(43)
  List<String>? get data_height_weight {
    final value = _data_height_weight;
    if (value == null) return null;
    if (_data_height_weight is EqualUnmodifiableListView)
      return _data_height_weight;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _data_birthplace;
  @override
  @HiveField(44)
  List<String>? get data_birthplace {
    final value = _data_birthplace;
    if (value == null) return null;
    if (_data_birthplace is EqualUnmodifiableListView) return _data_birthplace;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _data_school;
  @override
  @HiveField(45)
  List<String>? get data_school {
    final value = _data_school;
    if (value == null) return null;
    if (_data_school is EqualUnmodifiableListView) return _data_school;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _data_highschool;
  @override
  @HiveField(46)
  List<String>? get data_highschool {
    final value = _data_highschool;
    if (value == null) return null;
    if (_data_highschool is EqualUnmodifiableListView) return _data_highschool;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _data_university;
  @override
  @HiveField(47)
  List<String>? get data_university {
    final value = _data_university;
    if (value == null) return null;
    if (_data_university is EqualUnmodifiableListView) return _data_university;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _data_career;
  @override
  @HiveField(48)
  List<String>? get data_career {
    final value = _data_career;
    if (value == null) return null;
    if (_data_career is EqualUnmodifiableListView) return _data_career;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _data_belong;
  @override
  @HiveField(49)
  List<String>? get data_belong {
    final value = _data_belong;
    if (value == null) return null;
    if (_data_belong is EqualUnmodifiableListView) return _data_belong;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _data_award;
  @override
  @HiveField(50)
  List<String>? get data_award {
    final value = _data_award;
    if (value == null) return null;
    if (_data_award is EqualUnmodifiableListView) return _data_award;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _data_enrolledyears;
  @override
  @HiveField(51)
  List<String>? get data_enrolledyears {
    final value = _data_enrolledyears;
    if (value == null) return null;
    if (_data_enrolledyears is EqualUnmodifiableListView)
      return _data_enrolledyears;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _data_caps;
  @override
  @HiveField(52)
  List<String>? get data_caps {
    final value = _data_caps;
    if (value == null) return null;
    if (_data_caps is EqualUnmodifiableListView) return _data_caps;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _words_nickname;
  @override
  @HiveField(53)
  List<String>? get words_nickname {
    final value = _words_nickname;
    if (value == null) return null;
    if (_words_nickname is EqualUnmodifiableListView) return _words_nickname;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _words_dream_child_age;
  @override
  @HiveField(54)
  List<String>? get words_dream_child_age {
    final value = _words_dream_child_age;
    if (value == null) return null;
    if (_words_dream_child_age is EqualUnmodifiableListView)
      return _words_dream_child_age;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _words_opportunity;
  @override
  @HiveField(55)
  List<String>? get words_opportunity {
    final value = _words_opportunity;
    if (value == null) return null;
    if (_words_opportunity is EqualUnmodifiableListView)
      return _words_opportunity;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _words_playsseason;
  @override
  @HiveField(56)
  List<String>? get words_playsseason {
    final value = _words_playsseason;
    if (value == null) return null;
    if (_words_playsseason is EqualUnmodifiableListView)
      return _words_playsseason;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _words_goodplay;
  @override
  @HiveField(57)
  List<String>? get words_goodplay {
    final value = _words_goodplay;
    if (value == null) return null;
    if (_words_goodplay is EqualUnmodifiableListView) return _words_goodplay;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _words_wish;
  @override
  @HiveField(58)
  List<String>? get words_wish {
    final value = _words_wish;
    if (value == null) return null;
    if (_words_wish is EqualUnmodifiableListView) return _words_wish;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _words_myboom;
  @override
  @HiveField(59)
  List<String>? get words_myboom {
    final value = _words_myboom;
    if (value == null) return null;
    if (_words_myboom is EqualUnmodifiableListView) return _words_myboom;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _words_favoritebrand;
  @override
  @HiveField(60)
  List<String>? get words_favoritebrand {
    final value = _words_favoritebrand;
    if (value == null) return null;
    if (_words_favoritebrand is EqualUnmodifiableListView)
      return _words_favoritebrand;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _words_color;
  @override
  @HiveField(61)
  List<String>? get words_color {
    final value = _words_color;
    if (value == null) return null;
    if (_words_color is EqualUnmodifiableListView) return _words_color;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _words_shop;
  @override
  @HiveField(62)
  List<String>? get words_shop {
    final value = _words_shop;
    if (value == null) return null;
    if (_words_shop is EqualUnmodifiableListView) return _words_shop;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _words_gift;
  @override
  @HiveField(63)
  List<String>? get words_gift {
    final value = _words_gift;
    if (value == null) return null;
    if (_words_gift is EqualUnmodifiableListView) return _words_gift;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _words_favoritefood;
  @override
  @HiveField(64)
  List<String>? get words_favoritefood {
    final value = _words_favoritefood;
    if (value == null) return null;
    if (_words_favoritefood is EqualUnmodifiableListView)
      return _words_favoritefood;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _words_localfood;
  @override
  @HiveField(66)
  List<String>? get words_localfood {
    final value = _words_localfood;
    if (value == null) return null;
    if (_words_localfood is EqualUnmodifiableListView) return _words_localfood;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'CustomField(gameDate: $gameDate, gameTime: $gameTime, location: $location, team_1: $team_1, team_logo_1: $team_logo_1, team_2: $team_2, team_logo_2: $team_logo_2, game_result: $game_result, team_score_1: $team_score_1, team_score_2: $team_score_2, team_T_first_half_1: $team_T_first_half_1, team_T_second_half_1: $team_T_second_half_1, team_G_first_half_1: $team_G_first_half_1, team_G_second_half_1: $team_G_second_half_1, team_PG_first_half_1: $team_PG_first_half_1, team_PG_second_half_1: $team_PG_second_half_1, team_DG_first_half_1: $team_DG_first_half_1, team_DG_second_half_1: $team_DG_second_half_1, team_RESULT_first_half_1: $team_RESULT_first_half_1, team_RESULT_second_half_1: $team_RESULT_second_half_1, team_T_first_half_2: $team_T_first_half_2, team_T_second_half_2: $team_T_second_half_2, team_G_first_half_2: $team_G_first_half_2, team_G_second_half_2: $team_G_second_half_2, team_PG_first_half_2: $team_PG_first_half_2, team_PG_second_half_2: $team_PG_second_half_2, team_DG_first_half_2: $team_DG_first_half_2, team_DG_second_half_2: $team_DG_second_half_2, team_RESULT_first_half_2: $team_RESULT_first_half_2, team_RESULT_second_half_2: $team_RESULT_second_half_2, member_starting: $member_starting, member_reserves: $member_reserves, photos: $photos, game_serial: $game_serial, member_captain: $member_captain, profile_image_1: $profile_image_1, main_image: $main_image, profile_image_2: $profile_image_2, graph_image: $graph_image, position_image: $position_image, data_position: $data_position, data_play_position: $data_play_position, data_number: $data_number, data_birthday: $data_birthday, data_height_weight: $data_height_weight, data_birthplace: $data_birthplace, data_school: $data_school, data_highschool: $data_highschool, data_university: $data_university, data_career: $data_career, data_belong: $data_belong, data_award: $data_award, data_enrolledyears: $data_enrolledyears, data_caps: $data_caps, words_nickname: $words_nickname, words_dream_child_age: $words_dream_child_age, words_opportunity: $words_opportunity, words_playsseason: $words_playsseason, words_goodplay: $words_goodplay, words_wish: $words_wish, words_myboom: $words_myboom, words_favoritebrand: $words_favoritebrand, words_color: $words_color, words_shop: $words_shop, words_gift: $words_gift, words_favoritefood: $words_favoritefood, words_localfood: $words_localfood)';
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
                .equals(other._game_result, _game_result) &&
            const DeepCollectionEquality()
                .equals(other._team_score_1, _team_score_1) &&
            const DeepCollectionEquality()
                .equals(other._team_score_2, _team_score_2) &&
            const DeepCollectionEquality()
                .equals(other._team_T_first_half_1, _team_T_first_half_1) &&
            const DeepCollectionEquality()
                .equals(other._team_T_second_half_1, _team_T_second_half_1) &&
            const DeepCollectionEquality()
                .equals(other._team_G_first_half_1, _team_G_first_half_1) &&
            const DeepCollectionEquality()
                .equals(other._team_G_second_half_1, _team_G_second_half_1) &&
            const DeepCollectionEquality()
                .equals(other._team_PG_first_half_1, _team_PG_first_half_1) &&
            const DeepCollectionEquality()
                .equals(other._team_PG_second_half_1, _team_PG_second_half_1) &&
            const DeepCollectionEquality()
                .equals(other._team_DG_first_half_1, _team_DG_first_half_1) &&
            const DeepCollectionEquality()
                .equals(other._team_DG_second_half_1, _team_DG_second_half_1) &&
            const DeepCollectionEquality().equals(
                other._team_RESULT_first_half_1, _team_RESULT_first_half_1) &&
            const DeepCollectionEquality().equals(
                other._team_RESULT_second_half_1, _team_RESULT_second_half_1) &&
            const DeepCollectionEquality()
                .equals(other._team_T_first_half_2, _team_T_first_half_2) &&
            const DeepCollectionEquality()
                .equals(other._team_T_second_half_2, _team_T_second_half_2) &&
            const DeepCollectionEquality()
                .equals(other._team_G_first_half_2, _team_G_first_half_2) &&
            const DeepCollectionEquality()
                .equals(other._team_G_second_half_2, _team_G_second_half_2) &&
            const DeepCollectionEquality()
                .equals(other._team_PG_first_half_2, _team_PG_first_half_2) &&
            const DeepCollectionEquality()
                .equals(other._team_PG_second_half_2, _team_PG_second_half_2) &&
            const DeepCollectionEquality()
                .equals(other._team_DG_first_half_2, _team_DG_first_half_2) &&
            const DeepCollectionEquality()
                .equals(other._team_DG_second_half_2, _team_DG_second_half_2) &&
            const DeepCollectionEquality().equals(
                other._team_RESULT_first_half_2, _team_RESULT_first_half_2) &&
            const DeepCollectionEquality().equals(
                other._team_RESULT_second_half_2, _team_RESULT_second_half_2) &&
            const DeepCollectionEquality()
                .equals(other._member_starting, _member_starting) &&
            const DeepCollectionEquality()
                .equals(other._member_reserves, _member_reserves) &&
            const DeepCollectionEquality().equals(other._photos, _photos) &&
            const DeepCollectionEquality()
                .equals(other._game_serial, _game_serial) &&
            const DeepCollectionEquality()
                .equals(other._member_captain, _member_captain) &&
            const DeepCollectionEquality()
                .equals(other._profile_image_1, _profile_image_1) &&
            const DeepCollectionEquality()
                .equals(other._main_image, _main_image) &&
            const DeepCollectionEquality()
                .equals(other._profile_image_2, _profile_image_2) &&
            const DeepCollectionEquality()
                .equals(other._graph_image, _graph_image) &&
            const DeepCollectionEquality()
                .equals(other._position_image, _position_image) &&
            const DeepCollectionEquality()
                .equals(other._data_position, _data_position) &&
            const DeepCollectionEquality()
                .equals(other._data_play_position, _data_play_position) &&
            const DeepCollectionEquality()
                .equals(other._data_number, _data_number) &&
            const DeepCollectionEquality()
                .equals(other._data_birthday, _data_birthday) &&
            const DeepCollectionEquality()
                .equals(other._data_height_weight, _data_height_weight) &&
            const DeepCollectionEquality()
                .equals(other._data_birthplace, _data_birthplace) &&
            const DeepCollectionEquality()
                .equals(other._data_school, _data_school) &&
            const DeepCollectionEquality()
                .equals(other._data_highschool, _data_highschool) &&
            const DeepCollectionEquality().equals(other._data_university, _data_university) &&
            const DeepCollectionEquality().equals(other._data_career, _data_career) &&
            const DeepCollectionEquality().equals(other._data_belong, _data_belong) &&
            const DeepCollectionEquality().equals(other._data_award, _data_award) &&
            const DeepCollectionEquality().equals(other._data_enrolledyears, _data_enrolledyears) &&
            const DeepCollectionEquality().equals(other._data_caps, _data_caps) &&
            const DeepCollectionEquality().equals(other._words_nickname, _words_nickname) &&
            const DeepCollectionEquality().equals(other._words_dream_child_age, _words_dream_child_age) &&
            const DeepCollectionEquality().equals(other._words_opportunity, _words_opportunity) &&
            const DeepCollectionEquality().equals(other._words_playsseason, _words_playsseason) &&
            const DeepCollectionEquality().equals(other._words_goodplay, _words_goodplay) &&
            const DeepCollectionEquality().equals(other._words_wish, _words_wish) &&
            const DeepCollectionEquality().equals(other._words_myboom, _words_myboom) &&
            const DeepCollectionEquality().equals(other._words_favoritebrand, _words_favoritebrand) &&
            const DeepCollectionEquality().equals(other._words_color, _words_color) &&
            const DeepCollectionEquality().equals(other._words_shop, _words_shop) &&
            const DeepCollectionEquality().equals(other._words_gift, _words_gift) &&
            const DeepCollectionEquality().equals(other._words_favoritefood, _words_favoritefood) &&
            const DeepCollectionEquality().equals(other._words_localfood, _words_localfood));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        const DeepCollectionEquality().hash(_gameDate),
        const DeepCollectionEquality().hash(_gameTime),
        const DeepCollectionEquality().hash(_location),
        const DeepCollectionEquality().hash(_team_1),
        const DeepCollectionEquality().hash(_team_logo_1),
        const DeepCollectionEquality().hash(_team_2),
        const DeepCollectionEquality().hash(_team_logo_2),
        const DeepCollectionEquality().hash(_game_result),
        const DeepCollectionEquality().hash(_team_score_1),
        const DeepCollectionEquality().hash(_team_score_2),
        const DeepCollectionEquality().hash(_team_T_first_half_1),
        const DeepCollectionEquality().hash(_team_T_second_half_1),
        const DeepCollectionEquality().hash(_team_G_first_half_1),
        const DeepCollectionEquality().hash(_team_G_second_half_1),
        const DeepCollectionEquality().hash(_team_PG_first_half_1),
        const DeepCollectionEquality().hash(_team_PG_second_half_1),
        const DeepCollectionEquality().hash(_team_DG_first_half_1),
        const DeepCollectionEquality().hash(_team_DG_second_half_1),
        const DeepCollectionEquality().hash(_team_RESULT_first_half_1),
        const DeepCollectionEquality().hash(_team_RESULT_second_half_1),
        const DeepCollectionEquality().hash(_team_T_first_half_2),
        const DeepCollectionEquality().hash(_team_T_second_half_2),
        const DeepCollectionEquality().hash(_team_G_first_half_2),
        const DeepCollectionEquality().hash(_team_G_second_half_2),
        const DeepCollectionEquality().hash(_team_PG_first_half_2),
        const DeepCollectionEquality().hash(_team_PG_second_half_2),
        const DeepCollectionEquality().hash(_team_DG_first_half_2),
        const DeepCollectionEquality().hash(_team_DG_second_half_2),
        const DeepCollectionEquality().hash(_team_RESULT_first_half_2),
        const DeepCollectionEquality().hash(_team_RESULT_second_half_2),
        const DeepCollectionEquality().hash(_member_starting),
        const DeepCollectionEquality().hash(_member_reserves),
        const DeepCollectionEquality().hash(_photos),
        const DeepCollectionEquality().hash(_game_serial),
        const DeepCollectionEquality().hash(_member_captain),
        const DeepCollectionEquality().hash(_profile_image_1),
        const DeepCollectionEquality().hash(_main_image),
        const DeepCollectionEquality().hash(_profile_image_2),
        const DeepCollectionEquality().hash(_graph_image),
        const DeepCollectionEquality().hash(_position_image),
        const DeepCollectionEquality().hash(_data_position),
        const DeepCollectionEquality().hash(_data_play_position),
        const DeepCollectionEquality().hash(_data_number),
        const DeepCollectionEquality().hash(_data_birthday),
        const DeepCollectionEquality().hash(_data_height_weight),
        const DeepCollectionEquality().hash(_data_birthplace),
        const DeepCollectionEquality().hash(_data_school),
        const DeepCollectionEquality().hash(_data_highschool),
        const DeepCollectionEquality().hash(_data_university),
        const DeepCollectionEquality().hash(_data_career),
        const DeepCollectionEquality().hash(_data_belong),
        const DeepCollectionEquality().hash(_data_award),
        const DeepCollectionEquality().hash(_data_enrolledyears),
        const DeepCollectionEquality().hash(_data_caps),
        const DeepCollectionEquality().hash(_words_nickname),
        const DeepCollectionEquality().hash(_words_dream_child_age),
        const DeepCollectionEquality().hash(_words_opportunity),
        const DeepCollectionEquality().hash(_words_playsseason),
        const DeepCollectionEquality().hash(_words_goodplay),
        const DeepCollectionEquality().hash(_words_wish),
        const DeepCollectionEquality().hash(_words_myboom),
        const DeepCollectionEquality().hash(_words_favoritebrand),
        const DeepCollectionEquality().hash(_words_color),
        const DeepCollectionEquality().hash(_words_shop),
        const DeepCollectionEquality().hash(_words_gift),
        const DeepCollectionEquality().hash(_words_favoritefood),
        const DeepCollectionEquality().hash(_words_localfood)
      ]);

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
      {@HiveField(0)
      @JsonKey(name: 'game_date')
      required final List<String>? gameDate,
      @HiveField(1)
      @JsonKey(name: 'game_time')
      required final List<String>? gameTime,
      @HiveField(2) required final List<String>? location,
      @HiveField(3) required final List<String>? team_1,
      @HiveField(4) final List<String>? team_logo_1,
      @HiveField(5) required final List<String>? team_2,
      @HiveField(6) required final List<String>? team_logo_2,
      @HiveField(7) required final List<String>? game_result,
      @HiveField(8) required final List<String>? team_score_1,
      @HiveField(9) required final List<String>? team_score_2,
      @HiveField(10) required final List<String>? team_T_first_half_1,
      @HiveField(11) required final List<String>? team_T_second_half_1,
      @HiveField(12) required final List<String>? team_G_first_half_1,
      @HiveField(13) required final List<String>? team_G_second_half_1,
      @HiveField(14) required final List<String>? team_PG_first_half_1,
      @HiveField(15) required final List<String>? team_PG_second_half_1,
      @HiveField(16) required final List<String>? team_DG_first_half_1,
      @HiveField(17) required final List<String>? team_DG_second_half_1,
      @HiveField(18) required final List<String>? team_RESULT_first_half_1,
      @HiveField(19) required final List<String>? team_RESULT_second_half_1,
      @HiveField(20) required final List<String>? team_T_first_half_2,
      @HiveField(21) required final List<String>? team_T_second_half_2,
      @HiveField(22) required final List<String>? team_G_first_half_2,
      @HiveField(23) required final List<String>? team_G_second_half_2,
      @HiveField(24) required final List<String>? team_PG_first_half_2,
      @HiveField(25) required final List<String>? team_PG_second_half_2,
      @HiveField(26) required final List<String>? team_DG_first_half_2,
      @HiveField(27) required final List<String>? team_DG_second_half_2,
      @HiveField(28) required final List<String>? team_RESULT_first_half_2,
      @HiveField(29) required final List<String>? team_RESULT_second_half_2,
      @HiveField(30) required final List<String>? member_starting,
      @HiveField(31) required final List<String>? member_reserves,
      @HiveField(32) required final List<String>? photos,
      @HiveField(33) required final List<String>? game_serial,
      @HiveField(34) required final List<String>? member_captain,
      @HiveField(35) final List<String>? profile_image_1,
      @HiveField(36) final List<String>? main_image,
      @HiveField(37) final List<String>? profile_image_2,
      @HiveField(38) final List<String>? graph_image,
      @HiveField(39) final List<String>? position_image,
      @HiveField(40) final List<String>? data_position,
      @HiveField(65) final List<String>? data_play_position,
      @HiveField(41) final List<String>? data_number,
      @HiveField(42) final List<String>? data_birthday,
      @HiveField(43) final List<String>? data_height_weight,
      @HiveField(44) final List<String>? data_birthplace,
      @HiveField(45) final List<String>? data_school,
      @HiveField(46) final List<String>? data_highschool,
      @HiveField(47) final List<String>? data_university,
      @HiveField(48) final List<String>? data_career,
      @HiveField(49) final List<String>? data_belong,
      @HiveField(50) final List<String>? data_award,
      @HiveField(51) final List<String>? data_enrolledyears,
      @HiveField(52) final List<String>? data_caps,
      @HiveField(53) final List<String>? words_nickname,
      @HiveField(54) final List<String>? words_dream_child_age,
      @HiveField(55) final List<String>? words_opportunity,
      @HiveField(56) final List<String>? words_playsseason,
      @HiveField(57) final List<String>? words_goodplay,
      @HiveField(58) final List<String>? words_wish,
      @HiveField(59) final List<String>? words_myboom,
      @HiveField(60) final List<String>? words_favoritebrand,
      @HiveField(61) final List<String>? words_color,
      @HiveField(62) final List<String>? words_shop,
      @HiveField(63) final List<String>? words_gift,
      @HiveField(64) final List<String>? words_favoritefood,
      @HiveField(66) final List<String>? words_localfood}) = _$CustomFieldImpl;

  factory _CustomField.fromJson(Map<String, dynamic> json) =
      _$CustomFieldImpl.fromJson;

  @override
  @HiveField(0)
  @JsonKey(name: 'game_date')
  List<String>? get gameDate;
  @override
  @HiveField(1)
  @JsonKey(name: 'game_time')
  List<String>? get gameTime;
  @override
  @HiveField(2)
  List<String>? get location;
  @override
  @HiveField(3)
  List<String>? get team_1;
  @override
  @HiveField(4)
  List<String>? get team_logo_1;
  @override
  @HiveField(5)
  List<String>? get team_2;
  @override
  @HiveField(6)
  List<String>? get team_logo_2;
  @override
  @HiveField(7)
  List<String>? get game_result;
  @override
  @HiveField(8)
  List<String>? get team_score_1;
  @override
  @HiveField(9)
  List<String>? get team_score_2;
  @override
  @HiveField(10)
  List<String>? get team_T_first_half_1;
  @override
  @HiveField(11)
  List<String>? get team_T_second_half_1;
  @override
  @HiveField(12)
  List<String>? get team_G_first_half_1;
  @override
  @HiveField(13)
  List<String>? get team_G_second_half_1;
  @override
  @HiveField(14)
  List<String>? get team_PG_first_half_1;
  @override
  @HiveField(15)
  List<String>? get team_PG_second_half_1;
  @override
  @HiveField(16)
  List<String>? get team_DG_first_half_1;
  @override
  @HiveField(17)
  List<String>? get team_DG_second_half_1;
  @override
  @HiveField(18)
  List<String>? get team_RESULT_first_half_1;
  @override
  @HiveField(19)
  List<String>? get team_RESULT_second_half_1;
  @override
  @HiveField(20)
  List<String>? get team_T_first_half_2;
  @override
  @HiveField(21)
  List<String>? get team_T_second_half_2;
  @override
  @HiveField(22)
  List<String>? get team_G_first_half_2;
  @override
  @HiveField(23)
  List<String>? get team_G_second_half_2;
  @override
  @HiveField(24)
  List<String>? get team_PG_first_half_2;
  @override
  @HiveField(25)
  List<String>? get team_PG_second_half_2;
  @override
  @HiveField(26)
  List<String>? get team_DG_first_half_2;
  @override
  @HiveField(27)
  List<String>? get team_DG_second_half_2;
  @override
  @HiveField(28)
  List<String>? get team_RESULT_first_half_2;
  @override
  @HiveField(29)
  List<String>? get team_RESULT_second_half_2;
  @override
  @HiveField(30)
  List<String>? get member_starting;
  @override
  @HiveField(31)
  List<String>? get member_reserves;
  @override
  @HiveField(32)
  List<String>? get photos;
  @override
  @HiveField(33)
  List<String>? get game_serial;
  @override
  @HiveField(34)
  List<String>? get member_captain;
  @override //specific for player
  @HiveField(35)
  List<String>? get profile_image_1;
  @override //for profile picture
  @HiveField(36)
  List<String>? get main_image;
  @override
  @HiveField(37)
  List<String>? get profile_image_2;
  @override
  @HiveField(38)
  List<String>? get graph_image;
  @override
  @HiveField(39)
  List<String>? get position_image;
  @override
  @HiveField(40)
  List<String>? get data_position;
  @override
  @HiveField(65)
  List<String>? get data_play_position;
  @override
  @HiveField(41)
  List<String>? get data_number;
  @override
  @HiveField(42)
  List<String>? get data_birthday;
  @override
  @HiveField(43)
  List<String>? get data_height_weight;
  @override
  @HiveField(44)
  List<String>? get data_birthplace;
  @override
  @HiveField(45)
  List<String>? get data_school;
  @override
  @HiveField(46)
  List<String>? get data_highschool;
  @override
  @HiveField(47)
  List<String>? get data_university;
  @override
  @HiveField(48)
  List<String>? get data_career;
  @override
  @HiveField(49)
  List<String>? get data_belong;
  @override
  @HiveField(50)
  List<String>? get data_award;
  @override
  @HiveField(51)
  List<String>? get data_enrolledyears;
  @override
  @HiveField(52)
  List<String>? get data_caps;
  @override
  @HiveField(53)
  List<String>? get words_nickname;
  @override
  @HiveField(54)
  List<String>? get words_dream_child_age;
  @override
  @HiveField(55)
  List<String>? get words_opportunity;
  @override
  @HiveField(56)
  List<String>? get words_playsseason;
  @override
  @HiveField(57)
  List<String>? get words_goodplay;
  @override
  @HiveField(58)
  List<String>? get words_wish;
  @override
  @HiveField(59)
  List<String>? get words_myboom;
  @override
  @HiveField(60)
  List<String>? get words_favoritebrand;
  @override
  @HiveField(61)
  List<String>? get words_color;
  @override
  @HiveField(62)
  List<String>? get words_shop;
  @override
  @HiveField(63)
  List<String>? get words_gift;
  @override
  @HiveField(64)
  List<String>? get words_favoritefood;
  @override
  @HiveField(66)
  List<String>? get words_localfood;
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
