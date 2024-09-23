// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'post.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Post _$PostFromJson(Map<String, dynamic> json) {
  return _Post.fromJson(json);
}

/// @nodoc
mixin _$Post {
  int get id => throw _privateConstructorUsedError;
  String get date => throw _privateConstructorUsedError;
  String get slug => throw _privateConstructorUsedError;
  String get link => throw _privateConstructorUsedError;
  PostTitle get title => throw _privateConstructorUsedError;
  PostContent get content => throw _privateConstructorUsedError;
  PostExcerpt get excerpt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PostCopyWith<Post> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PostCopyWith<$Res> {
  factory $PostCopyWith(Post value, $Res Function(Post) then) =
      _$PostCopyWithImpl<$Res, Post>;
  @useResult
  $Res call(
      {int id,
      String date,
      String slug,
      String link,
      PostTitle title,
      PostContent content,
      PostExcerpt excerpt});

  $PostTitleCopyWith<$Res> get title;
  $PostContentCopyWith<$Res> get content;
  $PostExcerptCopyWith<$Res> get excerpt;
}

/// @nodoc
class _$PostCopyWithImpl<$Res, $Val extends Post>
    implements $PostCopyWith<$Res> {
  _$PostCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? date = null,
    Object? slug = null,
    Object? link = null,
    Object? title = null,
    Object? content = null,
    Object? excerpt = null,
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
      slug: null == slug
          ? _value.slug
          : slug // ignore: cast_nullable_to_non_nullable
              as String,
      link: null == link
          ? _value.link
          : link // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as PostTitle,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as PostContent,
      excerpt: null == excerpt
          ? _value.excerpt
          : excerpt // ignore: cast_nullable_to_non_nullable
              as PostExcerpt,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $PostTitleCopyWith<$Res> get title {
    return $PostTitleCopyWith<$Res>(_value.title, (value) {
      return _then(_value.copyWith(title: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $PostContentCopyWith<$Res> get content {
    return $PostContentCopyWith<$Res>(_value.content, (value) {
      return _then(_value.copyWith(content: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $PostExcerptCopyWith<$Res> get excerpt {
    return $PostExcerptCopyWith<$Res>(_value.excerpt, (value) {
      return _then(_value.copyWith(excerpt: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PostImplCopyWith<$Res> implements $PostCopyWith<$Res> {
  factory _$$PostImplCopyWith(
          _$PostImpl value, $Res Function(_$PostImpl) then) =
      __$$PostImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String date,
      String slug,
      String link,
      PostTitle title,
      PostContent content,
      PostExcerpt excerpt});

  @override
  $PostTitleCopyWith<$Res> get title;
  @override
  $PostContentCopyWith<$Res> get content;
  @override
  $PostExcerptCopyWith<$Res> get excerpt;
}

/// @nodoc
class __$$PostImplCopyWithImpl<$Res>
    extends _$PostCopyWithImpl<$Res, _$PostImpl>
    implements _$$PostImplCopyWith<$Res> {
  __$$PostImplCopyWithImpl(_$PostImpl _value, $Res Function(_$PostImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? date = null,
    Object? slug = null,
    Object? link = null,
    Object? title = null,
    Object? content = null,
    Object? excerpt = null,
  }) {
    return _then(_$PostImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as String,
      slug: null == slug
          ? _value.slug
          : slug // ignore: cast_nullable_to_non_nullable
              as String,
      link: null == link
          ? _value.link
          : link // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as PostTitle,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as PostContent,
      excerpt: null == excerpt
          ? _value.excerpt
          : excerpt // ignore: cast_nullable_to_non_nullable
              as PostExcerpt,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PostImpl implements _Post {
  _$PostImpl(
      {required this.id,
      required this.date,
      required this.slug,
      required this.link,
      required this.title,
      required this.content,
      required this.excerpt});

  factory _$PostImpl.fromJson(Map<String, dynamic> json) =>
      _$$PostImplFromJson(json);

  @override
  final int id;
  @override
  final String date;
  @override
  final String slug;
  @override
  final String link;
  @override
  final PostTitle title;
  @override
  final PostContent content;
  @override
  final PostExcerpt excerpt;

  @override
  String toString() {
    return 'Post(id: $id, date: $date, slug: $slug, link: $link, title: $title, content: $content, excerpt: $excerpt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PostImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.slug, slug) || other.slug == slug) &&
            (identical(other.link, link) || other.link == link) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.excerpt, excerpt) || other.excerpt == excerpt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, date, slug, link, title, content, excerpt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PostImplCopyWith<_$PostImpl> get copyWith =>
      __$$PostImplCopyWithImpl<_$PostImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PostImplToJson(
      this,
    );
  }
}

abstract class _Post implements Post {
  factory _Post(
      {required final int id,
      required final String date,
      required final String slug,
      required final String link,
      required final PostTitle title,
      required final PostContent content,
      required final PostExcerpt excerpt}) = _$PostImpl;

  factory _Post.fromJson(Map<String, dynamic> json) = _$PostImpl.fromJson;

  @override
  int get id;
  @override
  String get date;
  @override
  String get slug;
  @override
  String get link;
  @override
  PostTitle get title;
  @override
  PostContent get content;
  @override
  PostExcerpt get excerpt;
  @override
  @JsonKey(ignore: true)
  _$$PostImplCopyWith<_$PostImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PostTitle _$PostTitleFromJson(Map<String, dynamic> json) {
  return _PostTitle.fromJson(json);
}

/// @nodoc
mixin _$PostTitle {
  String get rendered => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PostTitleCopyWith<PostTitle> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PostTitleCopyWith<$Res> {
  factory $PostTitleCopyWith(PostTitle value, $Res Function(PostTitle) then) =
      _$PostTitleCopyWithImpl<$Res, PostTitle>;
  @useResult
  $Res call({String rendered});
}

/// @nodoc
class _$PostTitleCopyWithImpl<$Res, $Val extends PostTitle>
    implements $PostTitleCopyWith<$Res> {
  _$PostTitleCopyWithImpl(this._value, this._then);

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
abstract class _$$PostTitleImplCopyWith<$Res>
    implements $PostTitleCopyWith<$Res> {
  factory _$$PostTitleImplCopyWith(
          _$PostTitleImpl value, $Res Function(_$PostTitleImpl) then) =
      __$$PostTitleImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String rendered});
}

/// @nodoc
class __$$PostTitleImplCopyWithImpl<$Res>
    extends _$PostTitleCopyWithImpl<$Res, _$PostTitleImpl>
    implements _$$PostTitleImplCopyWith<$Res> {
  __$$PostTitleImplCopyWithImpl(
      _$PostTitleImpl _value, $Res Function(_$PostTitleImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? rendered = null,
  }) {
    return _then(_$PostTitleImpl(
      rendered: null == rendered
          ? _value.rendered
          : rendered // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PostTitleImpl implements _PostTitle {
  _$PostTitleImpl({required this.rendered});

  factory _$PostTitleImpl.fromJson(Map<String, dynamic> json) =>
      _$$PostTitleImplFromJson(json);

  @override
  final String rendered;

  @override
  String toString() {
    return 'PostTitle(rendered: $rendered)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PostTitleImpl &&
            (identical(other.rendered, rendered) ||
                other.rendered == rendered));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, rendered);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PostTitleImplCopyWith<_$PostTitleImpl> get copyWith =>
      __$$PostTitleImplCopyWithImpl<_$PostTitleImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PostTitleImplToJson(
      this,
    );
  }
}

abstract class _PostTitle implements PostTitle {
  factory _PostTitle({required final String rendered}) = _$PostTitleImpl;

  factory _PostTitle.fromJson(Map<String, dynamic> json) =
      _$PostTitleImpl.fromJson;

  @override
  String get rendered;
  @override
  @JsonKey(ignore: true)
  _$$PostTitleImplCopyWith<_$PostTitleImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PostContent _$PostContentFromJson(Map<String, dynamic> json) {
  return _PostContent.fromJson(json);
}

/// @nodoc
mixin _$PostContent {
  String get rendered => throw _privateConstructorUsedError;
  bool get protected => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PostContentCopyWith<PostContent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PostContentCopyWith<$Res> {
  factory $PostContentCopyWith(
          PostContent value, $Res Function(PostContent) then) =
      _$PostContentCopyWithImpl<$Res, PostContent>;
  @useResult
  $Res call({String rendered, bool protected});
}

/// @nodoc
class _$PostContentCopyWithImpl<$Res, $Val extends PostContent>
    implements $PostContentCopyWith<$Res> {
  _$PostContentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? rendered = null,
    Object? protected = null,
  }) {
    return _then(_value.copyWith(
      rendered: null == rendered
          ? _value.rendered
          : rendered // ignore: cast_nullable_to_non_nullable
              as String,
      protected: null == protected
          ? _value.protected
          : protected // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PostContentImplCopyWith<$Res>
    implements $PostContentCopyWith<$Res> {
  factory _$$PostContentImplCopyWith(
          _$PostContentImpl value, $Res Function(_$PostContentImpl) then) =
      __$$PostContentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String rendered, bool protected});
}

/// @nodoc
class __$$PostContentImplCopyWithImpl<$Res>
    extends _$PostContentCopyWithImpl<$Res, _$PostContentImpl>
    implements _$$PostContentImplCopyWith<$Res> {
  __$$PostContentImplCopyWithImpl(
      _$PostContentImpl _value, $Res Function(_$PostContentImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? rendered = null,
    Object? protected = null,
  }) {
    return _then(_$PostContentImpl(
      rendered: null == rendered
          ? _value.rendered
          : rendered // ignore: cast_nullable_to_non_nullable
              as String,
      protected: null == protected
          ? _value.protected
          : protected // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PostContentImpl implements _PostContent {
  _$PostContentImpl({required this.rendered, required this.protected});

  factory _$PostContentImpl.fromJson(Map<String, dynamic> json) =>
      _$$PostContentImplFromJson(json);

  @override
  final String rendered;
  @override
  final bool protected;

  @override
  String toString() {
    return 'PostContent(rendered: $rendered, protected: $protected)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PostContentImpl &&
            (identical(other.rendered, rendered) ||
                other.rendered == rendered) &&
            (identical(other.protected, protected) ||
                other.protected == protected));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, rendered, protected);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PostContentImplCopyWith<_$PostContentImpl> get copyWith =>
      __$$PostContentImplCopyWithImpl<_$PostContentImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PostContentImplToJson(
      this,
    );
  }
}

abstract class _PostContent implements PostContent {
  factory _PostContent(
      {required final String rendered,
      required final bool protected}) = _$PostContentImpl;

  factory _PostContent.fromJson(Map<String, dynamic> json) =
      _$PostContentImpl.fromJson;

  @override
  String get rendered;
  @override
  bool get protected;
  @override
  @JsonKey(ignore: true)
  _$$PostContentImplCopyWith<_$PostContentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PostExcerpt _$PostExcerptFromJson(Map<String, dynamic> json) {
  return _PostExcerpt.fromJson(json);
}

/// @nodoc
mixin _$PostExcerpt {
  String get rendered => throw _privateConstructorUsedError;
  bool get protected => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PostExcerptCopyWith<PostExcerpt> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PostExcerptCopyWith<$Res> {
  factory $PostExcerptCopyWith(
          PostExcerpt value, $Res Function(PostExcerpt) then) =
      _$PostExcerptCopyWithImpl<$Res, PostExcerpt>;
  @useResult
  $Res call({String rendered, bool protected});
}

/// @nodoc
class _$PostExcerptCopyWithImpl<$Res, $Val extends PostExcerpt>
    implements $PostExcerptCopyWith<$Res> {
  _$PostExcerptCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? rendered = null,
    Object? protected = null,
  }) {
    return _then(_value.copyWith(
      rendered: null == rendered
          ? _value.rendered
          : rendered // ignore: cast_nullable_to_non_nullable
              as String,
      protected: null == protected
          ? _value.protected
          : protected // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PostExcerptImplCopyWith<$Res>
    implements $PostExcerptCopyWith<$Res> {
  factory _$$PostExcerptImplCopyWith(
          _$PostExcerptImpl value, $Res Function(_$PostExcerptImpl) then) =
      __$$PostExcerptImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String rendered, bool protected});
}

/// @nodoc
class __$$PostExcerptImplCopyWithImpl<$Res>
    extends _$PostExcerptCopyWithImpl<$Res, _$PostExcerptImpl>
    implements _$$PostExcerptImplCopyWith<$Res> {
  __$$PostExcerptImplCopyWithImpl(
      _$PostExcerptImpl _value, $Res Function(_$PostExcerptImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? rendered = null,
    Object? protected = null,
  }) {
    return _then(_$PostExcerptImpl(
      rendered: null == rendered
          ? _value.rendered
          : rendered // ignore: cast_nullable_to_non_nullable
              as String,
      protected: null == protected
          ? _value.protected
          : protected // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PostExcerptImpl implements _PostExcerpt {
  _$PostExcerptImpl({required this.rendered, required this.protected});

  factory _$PostExcerptImpl.fromJson(Map<String, dynamic> json) =>
      _$$PostExcerptImplFromJson(json);

  @override
  final String rendered;
  @override
  final bool protected;

  @override
  String toString() {
    return 'PostExcerpt(rendered: $rendered, protected: $protected)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PostExcerptImpl &&
            (identical(other.rendered, rendered) ||
                other.rendered == rendered) &&
            (identical(other.protected, protected) ||
                other.protected == protected));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, rendered, protected);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PostExcerptImplCopyWith<_$PostExcerptImpl> get copyWith =>
      __$$PostExcerptImplCopyWithImpl<_$PostExcerptImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PostExcerptImplToJson(
      this,
    );
  }
}

abstract class _PostExcerpt implements PostExcerpt {
  factory _PostExcerpt(
      {required final String rendered,
      required final bool protected}) = _$PostExcerptImpl;

  factory _PostExcerpt.fromJson(Map<String, dynamic> json) =
      _$PostExcerptImpl.fromJson;

  @override
  String get rendered;
  @override
  bool get protected;
  @override
  @JsonKey(ignore: true)
  _$$PostExcerptImplCopyWith<_$PostExcerptImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
