// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'media.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Media _$MediaFromJson(Map<String, dynamic> json) {
  return _Media.fromJson(json);
}

/// @nodoc
mixin _$Media {
  int get id => throw _privateConstructorUsedError;
  String get date => throw _privateConstructorUsedError;
  String get modified => throw _privateConstructorUsedError;
  Guid get guid => throw _privateConstructorUsedError;
  String get slug => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  String get link => throw _privateConstructorUsedError;
  Title get title => throw _privateConstructorUsedError;
  String get source_url => throw _privateConstructorUsedError;
  MediaDetails get media_details => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MediaCopyWith<Media> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MediaCopyWith<$Res> {
  factory $MediaCopyWith(Media value, $Res Function(Media) then) =
      _$MediaCopyWithImpl<$Res, Media>;
  @useResult
  $Res call(
      {int id,
      String date,
      String modified,
      Guid guid,
      String slug,
      String status,
      String type,
      String link,
      Title title,
      String source_url,
      MediaDetails media_details});

  $GuidCopyWith<$Res> get guid;
  $TitleCopyWith<$Res> get title;
  $MediaDetailsCopyWith<$Res> get media_details;
}

/// @nodoc
class _$MediaCopyWithImpl<$Res, $Val extends Media>
    implements $MediaCopyWith<$Res> {
  _$MediaCopyWithImpl(this._value, this._then);

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
    Object? guid = null,
    Object? slug = null,
    Object? status = null,
    Object? type = null,
    Object? link = null,
    Object? title = null,
    Object? source_url = null,
    Object? media_details = null,
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
      guid: null == guid
          ? _value.guid
          : guid // ignore: cast_nullable_to_non_nullable
              as Guid,
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
      source_url: null == source_url
          ? _value.source_url
          : source_url // ignore: cast_nullable_to_non_nullable
              as String,
      media_details: null == media_details
          ? _value.media_details
          : media_details // ignore: cast_nullable_to_non_nullable
              as MediaDetails,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $GuidCopyWith<$Res> get guid {
    return $GuidCopyWith<$Res>(_value.guid, (value) {
      return _then(_value.copyWith(guid: value) as $Val);
    });
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
  $MediaDetailsCopyWith<$Res> get media_details {
    return $MediaDetailsCopyWith<$Res>(_value.media_details, (value) {
      return _then(_value.copyWith(media_details: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MediaImplCopyWith<$Res> implements $MediaCopyWith<$Res> {
  factory _$$MediaImplCopyWith(
          _$MediaImpl value, $Res Function(_$MediaImpl) then) =
      __$$MediaImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String date,
      String modified,
      Guid guid,
      String slug,
      String status,
      String type,
      String link,
      Title title,
      String source_url,
      MediaDetails media_details});

  @override
  $GuidCopyWith<$Res> get guid;
  @override
  $TitleCopyWith<$Res> get title;
  @override
  $MediaDetailsCopyWith<$Res> get media_details;
}

/// @nodoc
class __$$MediaImplCopyWithImpl<$Res>
    extends _$MediaCopyWithImpl<$Res, _$MediaImpl>
    implements _$$MediaImplCopyWith<$Res> {
  __$$MediaImplCopyWithImpl(
      _$MediaImpl _value, $Res Function(_$MediaImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? date = null,
    Object? modified = null,
    Object? guid = null,
    Object? slug = null,
    Object? status = null,
    Object? type = null,
    Object? link = null,
    Object? title = null,
    Object? source_url = null,
    Object? media_details = null,
  }) {
    return _then(_$MediaImpl(
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
      guid: null == guid
          ? _value.guid
          : guid // ignore: cast_nullable_to_non_nullable
              as Guid,
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
      source_url: null == source_url
          ? _value.source_url
          : source_url // ignore: cast_nullable_to_non_nullable
              as String,
      media_details: null == media_details
          ? _value.media_details
          : media_details // ignore: cast_nullable_to_non_nullable
              as MediaDetails,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MediaImpl implements _Media {
  _$MediaImpl(
      {required this.id,
      required this.date,
      required this.modified,
      required this.guid,
      required this.slug,
      required this.status,
      required this.type,
      required this.link,
      required this.title,
      required this.source_url,
      required this.media_details});

  factory _$MediaImpl.fromJson(Map<String, dynamic> json) =>
      _$$MediaImplFromJson(json);

  @override
  final int id;
  @override
  final String date;
  @override
  final String modified;
  @override
  final Guid guid;
  @override
  final String slug;
  @override
  final String status;
  @override
  final String type;
  @override
  final String link;
  @override
  final Title title;
  @override
  final String source_url;
  @override
  final MediaDetails media_details;

  @override
  String toString() {
    return 'Media(id: $id, date: $date, modified: $modified, guid: $guid, slug: $slug, status: $status, type: $type, link: $link, title: $title, source_url: $source_url, media_details: $media_details)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MediaImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.modified, modified) ||
                other.modified == modified) &&
            (identical(other.guid, guid) || other.guid == guid) &&
            (identical(other.slug, slug) || other.slug == slug) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.link, link) || other.link == link) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.source_url, source_url) ||
                other.source_url == source_url) &&
            (identical(other.media_details, media_details) ||
                other.media_details == media_details));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, date, modified, guid, slug,
      status, type, link, title, source_url, media_details);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MediaImplCopyWith<_$MediaImpl> get copyWith =>
      __$$MediaImplCopyWithImpl<_$MediaImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MediaImplToJson(
      this,
    );
  }
}

abstract class _Media implements Media {
  factory _Media(
      {required final int id,
      required final String date,
      required final String modified,
      required final Guid guid,
      required final String slug,
      required final String status,
      required final String type,
      required final String link,
      required final Title title,
      required final String source_url,
      required final MediaDetails media_details}) = _$MediaImpl;

  factory _Media.fromJson(Map<String, dynamic> json) = _$MediaImpl.fromJson;

  @override
  int get id;
  @override
  String get date;
  @override
  String get modified;
  @override
  Guid get guid;
  @override
  String get slug;
  @override
  String get status;
  @override
  String get type;
  @override
  String get link;
  @override
  Title get title;
  @override
  String get source_url;
  @override
  MediaDetails get media_details;
  @override
  @JsonKey(ignore: true)
  _$$MediaImplCopyWith<_$MediaImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Guid _$GuidFromJson(Map<String, dynamic> json) {
  return _Guid.fromJson(json);
}

/// @nodoc
mixin _$Guid {
  String get rendered => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $GuidCopyWith<Guid> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GuidCopyWith<$Res> {
  factory $GuidCopyWith(Guid value, $Res Function(Guid) then) =
      _$GuidCopyWithImpl<$Res, Guid>;
  @useResult
  $Res call({String rendered});
}

/// @nodoc
class _$GuidCopyWithImpl<$Res, $Val extends Guid>
    implements $GuidCopyWith<$Res> {
  _$GuidCopyWithImpl(this._value, this._then);

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
abstract class _$$GuidImplCopyWith<$Res> implements $GuidCopyWith<$Res> {
  factory _$$GuidImplCopyWith(
          _$GuidImpl value, $Res Function(_$GuidImpl) then) =
      __$$GuidImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String rendered});
}

/// @nodoc
class __$$GuidImplCopyWithImpl<$Res>
    extends _$GuidCopyWithImpl<$Res, _$GuidImpl>
    implements _$$GuidImplCopyWith<$Res> {
  __$$GuidImplCopyWithImpl(_$GuidImpl _value, $Res Function(_$GuidImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? rendered = null,
  }) {
    return _then(_$GuidImpl(
      rendered: null == rendered
          ? _value.rendered
          : rendered // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GuidImpl implements _Guid {
  _$GuidImpl({required this.rendered});

  factory _$GuidImpl.fromJson(Map<String, dynamic> json) =>
      _$$GuidImplFromJson(json);

  @override
  final String rendered;

  @override
  String toString() {
    return 'Guid(rendered: $rendered)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GuidImpl &&
            (identical(other.rendered, rendered) ||
                other.rendered == rendered));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, rendered);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$GuidImplCopyWith<_$GuidImpl> get copyWith =>
      __$$GuidImplCopyWithImpl<_$GuidImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GuidImplToJson(
      this,
    );
  }
}

abstract class _Guid implements Guid {
  factory _Guid({required final String rendered}) = _$GuidImpl;

  factory _Guid.fromJson(Map<String, dynamic> json) = _$GuidImpl.fromJson;

  @override
  String get rendered;
  @override
  @JsonKey(ignore: true)
  _$$GuidImplCopyWith<_$GuidImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Title _$TitleFromJson(Map<String, dynamic> json) {
  return _Title.fromJson(json);
}

/// @nodoc
mixin _$Title {
  String get rendered => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $TitleCopyWith<Title> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TitleCopyWith<$Res> {
  factory $TitleCopyWith(Title value, $Res Function(Title) then) =
      _$TitleCopyWithImpl<$Res, Title>;
  @useResult
  $Res call({String rendered});
}

/// @nodoc
class _$TitleCopyWithImpl<$Res, $Val extends Title>
    implements $TitleCopyWith<$Res> {
  _$TitleCopyWithImpl(this._value, this._then);

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
abstract class _$$TitleImplCopyWith<$Res> implements $TitleCopyWith<$Res> {
  factory _$$TitleImplCopyWith(
          _$TitleImpl value, $Res Function(_$TitleImpl) then) =
      __$$TitleImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String rendered});
}

/// @nodoc
class __$$TitleImplCopyWithImpl<$Res>
    extends _$TitleCopyWithImpl<$Res, _$TitleImpl>
    implements _$$TitleImplCopyWith<$Res> {
  __$$TitleImplCopyWithImpl(
      _$TitleImpl _value, $Res Function(_$TitleImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? rendered = null,
  }) {
    return _then(_$TitleImpl(
      rendered: null == rendered
          ? _value.rendered
          : rendered // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TitleImpl implements _Title {
  _$TitleImpl({required this.rendered});

  factory _$TitleImpl.fromJson(Map<String, dynamic> json) =>
      _$$TitleImplFromJson(json);

  @override
  final String rendered;

  @override
  String toString() {
    return 'Title(rendered: $rendered)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TitleImpl &&
            (identical(other.rendered, rendered) ||
                other.rendered == rendered));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, rendered);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TitleImplCopyWith<_$TitleImpl> get copyWith =>
      __$$TitleImplCopyWithImpl<_$TitleImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TitleImplToJson(
      this,
    );
  }
}

abstract class _Title implements Title {
  factory _Title({required final String rendered}) = _$TitleImpl;

  factory _Title.fromJson(Map<String, dynamic> json) = _$TitleImpl.fromJson;

  @override
  String get rendered;
  @override
  @JsonKey(ignore: true)
  _$$TitleImplCopyWith<_$TitleImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MediaDetails _$MediaDetailsFromJson(Map<String, dynamic> json) {
  return _MediaDetails.fromJson(json);
}

/// @nodoc
mixin _$MediaDetails {
  int get width => throw _privateConstructorUsedError;
  int get height => throw _privateConstructorUsedError;
  String get file => throw _privateConstructorUsedError;
  Sizes get sizes => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MediaDetailsCopyWith<MediaDetails> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MediaDetailsCopyWith<$Res> {
  factory $MediaDetailsCopyWith(
          MediaDetails value, $Res Function(MediaDetails) then) =
      _$MediaDetailsCopyWithImpl<$Res, MediaDetails>;
  @useResult
  $Res call({int width, int height, String file, Sizes sizes});

  $SizesCopyWith<$Res> get sizes;
}

/// @nodoc
class _$MediaDetailsCopyWithImpl<$Res, $Val extends MediaDetails>
    implements $MediaDetailsCopyWith<$Res> {
  _$MediaDetailsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? width = null,
    Object? height = null,
    Object? file = null,
    Object? sizes = null,
  }) {
    return _then(_value.copyWith(
      width: null == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as int,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as int,
      file: null == file
          ? _value.file
          : file // ignore: cast_nullable_to_non_nullable
              as String,
      sizes: null == sizes
          ? _value.sizes
          : sizes // ignore: cast_nullable_to_non_nullable
              as Sizes,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $SizesCopyWith<$Res> get sizes {
    return $SizesCopyWith<$Res>(_value.sizes, (value) {
      return _then(_value.copyWith(sizes: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MediaDetailsImplCopyWith<$Res>
    implements $MediaDetailsCopyWith<$Res> {
  factory _$$MediaDetailsImplCopyWith(
          _$MediaDetailsImpl value, $Res Function(_$MediaDetailsImpl) then) =
      __$$MediaDetailsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int width, int height, String file, Sizes sizes});

  @override
  $SizesCopyWith<$Res> get sizes;
}

/// @nodoc
class __$$MediaDetailsImplCopyWithImpl<$Res>
    extends _$MediaDetailsCopyWithImpl<$Res, _$MediaDetailsImpl>
    implements _$$MediaDetailsImplCopyWith<$Res> {
  __$$MediaDetailsImplCopyWithImpl(
      _$MediaDetailsImpl _value, $Res Function(_$MediaDetailsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? width = null,
    Object? height = null,
    Object? file = null,
    Object? sizes = null,
  }) {
    return _then(_$MediaDetailsImpl(
      width: null == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as int,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as int,
      file: null == file
          ? _value.file
          : file // ignore: cast_nullable_to_non_nullable
              as String,
      sizes: null == sizes
          ? _value.sizes
          : sizes // ignore: cast_nullable_to_non_nullable
              as Sizes,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MediaDetailsImpl implements _MediaDetails {
  _$MediaDetailsImpl(
      {required this.width,
      required this.height,
      required this.file,
      required this.sizes});

  factory _$MediaDetailsImpl.fromJson(Map<String, dynamic> json) =>
      _$$MediaDetailsImplFromJson(json);

  @override
  final int width;
  @override
  final int height;
  @override
  final String file;
  @override
  final Sizes sizes;

  @override
  String toString() {
    return 'MediaDetails(width: $width, height: $height, file: $file, sizes: $sizes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MediaDetailsImpl &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height) &&
            (identical(other.file, file) || other.file == file) &&
            (identical(other.sizes, sizes) || other.sizes == sizes));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, width, height, file, sizes);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MediaDetailsImplCopyWith<_$MediaDetailsImpl> get copyWith =>
      __$$MediaDetailsImplCopyWithImpl<_$MediaDetailsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MediaDetailsImplToJson(
      this,
    );
  }
}

abstract class _MediaDetails implements MediaDetails {
  factory _MediaDetails(
      {required final int width,
      required final int height,
      required final String file,
      required final Sizes sizes}) = _$MediaDetailsImpl;

  factory _MediaDetails.fromJson(Map<String, dynamic> json) =
      _$MediaDetailsImpl.fromJson;

  @override
  int get width;
  @override
  int get height;
  @override
  String get file;
  @override
  Sizes get sizes;
  @override
  @JsonKey(ignore: true)
  _$$MediaDetailsImplCopyWith<_$MediaDetailsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Sizes _$SizesFromJson(Map<String, dynamic> json) {
  return _Sizes.fromJson(json);
}

/// @nodoc
mixin _$Sizes {
  Thumbnail get thumbnail =>
      throw _privateConstructorUsedError; // Add thumbnail to get thumbnail size info
  Full get full => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SizesCopyWith<Sizes> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SizesCopyWith<$Res> {
  factory $SizesCopyWith(Sizes value, $Res Function(Sizes) then) =
      _$SizesCopyWithImpl<$Res, Sizes>;
  @useResult
  $Res call({Thumbnail thumbnail, Full full});

  $ThumbnailCopyWith<$Res> get thumbnail;
  $FullCopyWith<$Res> get full;
}

/// @nodoc
class _$SizesCopyWithImpl<$Res, $Val extends Sizes>
    implements $SizesCopyWith<$Res> {
  _$SizesCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? thumbnail = null,
    Object? full = null,
  }) {
    return _then(_value.copyWith(
      thumbnail: null == thumbnail
          ? _value.thumbnail
          : thumbnail // ignore: cast_nullable_to_non_nullable
              as Thumbnail,
      full: null == full
          ? _value.full
          : full // ignore: cast_nullable_to_non_nullable
              as Full,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $ThumbnailCopyWith<$Res> get thumbnail {
    return $ThumbnailCopyWith<$Res>(_value.thumbnail, (value) {
      return _then(_value.copyWith(thumbnail: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $FullCopyWith<$Res> get full {
    return $FullCopyWith<$Res>(_value.full, (value) {
      return _then(_value.copyWith(full: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$SizesImplCopyWith<$Res> implements $SizesCopyWith<$Res> {
  factory _$$SizesImplCopyWith(
          _$SizesImpl value, $Res Function(_$SizesImpl) then) =
      __$$SizesImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({Thumbnail thumbnail, Full full});

  @override
  $ThumbnailCopyWith<$Res> get thumbnail;
  @override
  $FullCopyWith<$Res> get full;
}

/// @nodoc
class __$$SizesImplCopyWithImpl<$Res>
    extends _$SizesCopyWithImpl<$Res, _$SizesImpl>
    implements _$$SizesImplCopyWith<$Res> {
  __$$SizesImplCopyWithImpl(
      _$SizesImpl _value, $Res Function(_$SizesImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? thumbnail = null,
    Object? full = null,
  }) {
    return _then(_$SizesImpl(
      thumbnail: null == thumbnail
          ? _value.thumbnail
          : thumbnail // ignore: cast_nullable_to_non_nullable
              as Thumbnail,
      full: null == full
          ? _value.full
          : full // ignore: cast_nullable_to_non_nullable
              as Full,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SizesImpl implements _Sizes {
  _$SizesImpl({required this.thumbnail, required this.full});

  factory _$SizesImpl.fromJson(Map<String, dynamic> json) =>
      _$$SizesImplFromJson(json);

  @override
  final Thumbnail thumbnail;
// Add thumbnail to get thumbnail size info
  @override
  final Full full;

  @override
  String toString() {
    return 'Sizes(thumbnail: $thumbnail, full: $full)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SizesImpl &&
            (identical(other.thumbnail, thumbnail) ||
                other.thumbnail == thumbnail) &&
            (identical(other.full, full) || other.full == full));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, thumbnail, full);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SizesImplCopyWith<_$SizesImpl> get copyWith =>
      __$$SizesImplCopyWithImpl<_$SizesImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SizesImplToJson(
      this,
    );
  }
}

abstract class _Sizes implements Sizes {
  factory _Sizes(
      {required final Thumbnail thumbnail,
      required final Full full}) = _$SizesImpl;

  factory _Sizes.fromJson(Map<String, dynamic> json) = _$SizesImpl.fromJson;

  @override
  Thumbnail get thumbnail;
  @override // Add thumbnail to get thumbnail size info
  Full get full;
  @override
  @JsonKey(ignore: true)
  _$$SizesImplCopyWith<_$SizesImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Thumbnail _$ThumbnailFromJson(Map<String, dynamic> json) {
  return _Thumbnail.fromJson(json);
}

/// @nodoc
mixin _$Thumbnail {
  String get file => throw _privateConstructorUsedError;
  int get width => throw _privateConstructorUsedError;
  int get height => throw _privateConstructorUsedError;
  String get source_url => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ThumbnailCopyWith<Thumbnail> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ThumbnailCopyWith<$Res> {
  factory $ThumbnailCopyWith(Thumbnail value, $Res Function(Thumbnail) then) =
      _$ThumbnailCopyWithImpl<$Res, Thumbnail>;
  @useResult
  $Res call({String file, int width, int height, String source_url});
}

/// @nodoc
class _$ThumbnailCopyWithImpl<$Res, $Val extends Thumbnail>
    implements $ThumbnailCopyWith<$Res> {
  _$ThumbnailCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? file = null,
    Object? width = null,
    Object? height = null,
    Object? source_url = null,
  }) {
    return _then(_value.copyWith(
      file: null == file
          ? _value.file
          : file // ignore: cast_nullable_to_non_nullable
              as String,
      width: null == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as int,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as int,
      source_url: null == source_url
          ? _value.source_url
          : source_url // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ThumbnailImplCopyWith<$Res>
    implements $ThumbnailCopyWith<$Res> {
  factory _$$ThumbnailImplCopyWith(
          _$ThumbnailImpl value, $Res Function(_$ThumbnailImpl) then) =
      __$$ThumbnailImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String file, int width, int height, String source_url});
}

/// @nodoc
class __$$ThumbnailImplCopyWithImpl<$Res>
    extends _$ThumbnailCopyWithImpl<$Res, _$ThumbnailImpl>
    implements _$$ThumbnailImplCopyWith<$Res> {
  __$$ThumbnailImplCopyWithImpl(
      _$ThumbnailImpl _value, $Res Function(_$ThumbnailImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? file = null,
    Object? width = null,
    Object? height = null,
    Object? source_url = null,
  }) {
    return _then(_$ThumbnailImpl(
      file: null == file
          ? _value.file
          : file // ignore: cast_nullable_to_non_nullable
              as String,
      width: null == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as int,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as int,
      source_url: null == source_url
          ? _value.source_url
          : source_url // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ThumbnailImpl implements _Thumbnail {
  _$ThumbnailImpl(
      {required this.file,
      required this.width,
      required this.height,
      required this.source_url});

  factory _$ThumbnailImpl.fromJson(Map<String, dynamic> json) =>
      _$$ThumbnailImplFromJson(json);

  @override
  final String file;
  @override
  final int width;
  @override
  final int height;
  @override
  final String source_url;

  @override
  String toString() {
    return 'Thumbnail(file: $file, width: $width, height: $height, source_url: $source_url)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ThumbnailImpl &&
            (identical(other.file, file) || other.file == file) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height) &&
            (identical(other.source_url, source_url) ||
                other.source_url == source_url));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, file, width, height, source_url);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ThumbnailImplCopyWith<_$ThumbnailImpl> get copyWith =>
      __$$ThumbnailImplCopyWithImpl<_$ThumbnailImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ThumbnailImplToJson(
      this,
    );
  }
}

abstract class _Thumbnail implements Thumbnail {
  factory _Thumbnail(
      {required final String file,
      required final int width,
      required final int height,
      required final String source_url}) = _$ThumbnailImpl;

  factory _Thumbnail.fromJson(Map<String, dynamic> json) =
      _$ThumbnailImpl.fromJson;

  @override
  String get file;
  @override
  int get width;
  @override
  int get height;
  @override
  String get source_url;
  @override
  @JsonKey(ignore: true)
  _$$ThumbnailImplCopyWith<_$ThumbnailImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Full _$FullFromJson(Map<String, dynamic> json) {
  return _Full.fromJson(json);
}

/// @nodoc
mixin _$Full {
  String get file => throw _privateConstructorUsedError;
  int get width => throw _privateConstructorUsedError;
  int get height => throw _privateConstructorUsedError;
  String get source_url => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $FullCopyWith<Full> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FullCopyWith<$Res> {
  factory $FullCopyWith(Full value, $Res Function(Full) then) =
      _$FullCopyWithImpl<$Res, Full>;
  @useResult
  $Res call({String file, int width, int height, String source_url});
}

/// @nodoc
class _$FullCopyWithImpl<$Res, $Val extends Full>
    implements $FullCopyWith<$Res> {
  _$FullCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? file = null,
    Object? width = null,
    Object? height = null,
    Object? source_url = null,
  }) {
    return _then(_value.copyWith(
      file: null == file
          ? _value.file
          : file // ignore: cast_nullable_to_non_nullable
              as String,
      width: null == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as int,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as int,
      source_url: null == source_url
          ? _value.source_url
          : source_url // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FullImplCopyWith<$Res> implements $FullCopyWith<$Res> {
  factory _$$FullImplCopyWith(
          _$FullImpl value, $Res Function(_$FullImpl) then) =
      __$$FullImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String file, int width, int height, String source_url});
}

/// @nodoc
class __$$FullImplCopyWithImpl<$Res>
    extends _$FullCopyWithImpl<$Res, _$FullImpl>
    implements _$$FullImplCopyWith<$Res> {
  __$$FullImplCopyWithImpl(_$FullImpl _value, $Res Function(_$FullImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? file = null,
    Object? width = null,
    Object? height = null,
    Object? source_url = null,
  }) {
    return _then(_$FullImpl(
      file: null == file
          ? _value.file
          : file // ignore: cast_nullable_to_non_nullable
              as String,
      width: null == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as int,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as int,
      source_url: null == source_url
          ? _value.source_url
          : source_url // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FullImpl implements _Full {
  _$FullImpl(
      {required this.file,
      required this.width,
      required this.height,
      required this.source_url});

  factory _$FullImpl.fromJson(Map<String, dynamic> json) =>
      _$$FullImplFromJson(json);

  @override
  final String file;
  @override
  final int width;
  @override
  final int height;
  @override
  final String source_url;

  @override
  String toString() {
    return 'Full(file: $file, width: $width, height: $height, source_url: $source_url)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FullImpl &&
            (identical(other.file, file) || other.file == file) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height) &&
            (identical(other.source_url, source_url) ||
                other.source_url == source_url));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, file, width, height, source_url);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$FullImplCopyWith<_$FullImpl> get copyWith =>
      __$$FullImplCopyWithImpl<_$FullImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FullImplToJson(
      this,
    );
  }
}

abstract class _Full implements Full {
  factory _Full(
      {required final String file,
      required final int width,
      required final int height,
      required final String source_url}) = _$FullImpl;

  factory _Full.fromJson(Map<String, dynamic> json) = _$FullImpl.fromJson;

  @override
  String get file;
  @override
  int get width;
  @override
  int get height;
  @override
  String get source_url;
  @override
  @JsonKey(ignore: true)
  _$$FullImplCopyWith<_$FullImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
