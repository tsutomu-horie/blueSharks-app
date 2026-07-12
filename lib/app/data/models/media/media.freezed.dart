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

Album _$AlbumFromJson(Map<String, dynamic> json) {
  return _Album.fromJson(json);
}

/// @nodoc
mixin _$Album {
  int get id => throw _privateConstructorUsedError; // Add media_details field
  String? get name =>
      throw _privateConstructorUsedError; // Add media_details field
  String? get photo =>
      throw _privateConstructorUsedError; // Add media_details field
  String? get date => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AlbumCopyWith<Album> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AlbumCopyWith<$Res> {
  factory $AlbumCopyWith(Album value, $Res Function(Album) then) =
      _$AlbumCopyWithImpl<$Res, Album>;
  @useResult
  $Res call({int id, String? name, String? photo, String? date});
}

/// @nodoc
class _$AlbumCopyWithImpl<$Res, $Val extends Album>
    implements $AlbumCopyWith<$Res> {
  _$AlbumCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = freezed,
    Object? photo = freezed,
    Object? date = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      photo: freezed == photo
          ? _value.photo
          : photo // ignore: cast_nullable_to_non_nullable
              as String?,
      date: freezed == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AlbumImplCopyWith<$Res> implements $AlbumCopyWith<$Res> {
  factory _$$AlbumImplCopyWith(
          _$AlbumImpl value, $Res Function(_$AlbumImpl) then) =
      __$$AlbumImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int id, String? name, String? photo, String? date});
}

/// @nodoc
class __$$AlbumImplCopyWithImpl<$Res>
    extends _$AlbumCopyWithImpl<$Res, _$AlbumImpl>
    implements _$$AlbumImplCopyWith<$Res> {
  __$$AlbumImplCopyWithImpl(
      _$AlbumImpl _value, $Res Function(_$AlbumImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = freezed,
    Object? photo = freezed,
    Object? date = freezed,
  }) {
    return _then(_$AlbumImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      photo: freezed == photo
          ? _value.photo
          : photo // ignore: cast_nullable_to_non_nullable
              as String?,
      date: freezed == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AlbumImpl implements _Album {
  _$AlbumImpl({required this.id, this.name, this.photo, this.date});

  factory _$AlbumImpl.fromJson(Map<String, dynamic> json) =>
      _$$AlbumImplFromJson(json);

  @override
  final int id;
// Add media_details field
  @override
  final String? name;
// Add media_details field
  @override
  final String? photo;
// Add media_details field
  @override
  final String? date;

  @override
  String toString() {
    return 'Album(id: $id, name: $name, photo: $photo, date: $date)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AlbumImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.photo, photo) || other.photo == photo) &&
            (identical(other.date, date) || other.date == date));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, photo, date);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AlbumImplCopyWith<_$AlbumImpl> get copyWith =>
      __$$AlbumImplCopyWithImpl<_$AlbumImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AlbumImplToJson(
      this,
    );
  }
}

abstract class _Album implements Album {
  factory _Album(
      {required final int id,
      final String? name,
      final String? photo,
      final String? date}) = _$AlbumImpl;

  factory _Album.fromJson(Map<String, dynamic> json) = _$AlbumImpl.fromJson;

  @override
  int get id;
  @override // Add media_details field
  String? get name;
  @override // Add media_details field
  String? get photo;
  @override // Add media_details field
  String? get date;
  @override
  @JsonKey(ignore: true)
  _$$AlbumImplCopyWith<_$AlbumImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AlbumDetail _$AlbumDetailFromJson(Map<String, dynamic> json) {
  return _AlbumDetail.fromJson(json);
}

/// @nodoc
mixin _$AlbumDetail {
  Album get album =>
      throw _privateConstructorUsedError; // Add media_details field
  Album get galleries => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AlbumDetailCopyWith<AlbumDetail> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AlbumDetailCopyWith<$Res> {
  factory $AlbumDetailCopyWith(
          AlbumDetail value, $Res Function(AlbumDetail) then) =
      _$AlbumDetailCopyWithImpl<$Res, AlbumDetail>;
  @useResult
  $Res call({Album album, Album galleries});

  $AlbumCopyWith<$Res> get album;
  $AlbumCopyWith<$Res> get galleries;
}

/// @nodoc
class _$AlbumDetailCopyWithImpl<$Res, $Val extends AlbumDetail>
    implements $AlbumDetailCopyWith<$Res> {
  _$AlbumDetailCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? album = null,
    Object? galleries = null,
  }) {
    return _then(_value.copyWith(
      album: null == album
          ? _value.album
          : album // ignore: cast_nullable_to_non_nullable
              as Album,
      galleries: null == galleries
          ? _value.galleries
          : galleries // ignore: cast_nullable_to_non_nullable
              as Album,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $AlbumCopyWith<$Res> get album {
    return $AlbumCopyWith<$Res>(_value.album, (value) {
      return _then(_value.copyWith(album: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $AlbumCopyWith<$Res> get galleries {
    return $AlbumCopyWith<$Res>(_value.galleries, (value) {
      return _then(_value.copyWith(galleries: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$AlbumDetailImplCopyWith<$Res>
    implements $AlbumDetailCopyWith<$Res> {
  factory _$$AlbumDetailImplCopyWith(
          _$AlbumDetailImpl value, $Res Function(_$AlbumDetailImpl) then) =
      __$$AlbumDetailImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({Album album, Album galleries});

  @override
  $AlbumCopyWith<$Res> get album;
  @override
  $AlbumCopyWith<$Res> get galleries;
}

/// @nodoc
class __$$AlbumDetailImplCopyWithImpl<$Res>
    extends _$AlbumDetailCopyWithImpl<$Res, _$AlbumDetailImpl>
    implements _$$AlbumDetailImplCopyWith<$Res> {
  __$$AlbumDetailImplCopyWithImpl(
      _$AlbumDetailImpl _value, $Res Function(_$AlbumDetailImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? album = null,
    Object? galleries = null,
  }) {
    return _then(_$AlbumDetailImpl(
      album: null == album
          ? _value.album
          : album // ignore: cast_nullable_to_non_nullable
              as Album,
      galleries: null == galleries
          ? _value.galleries
          : galleries // ignore: cast_nullable_to_non_nullable
              as Album,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AlbumDetailImpl implements _AlbumDetail {
  _$AlbumDetailImpl({required this.album, required this.galleries});

  factory _$AlbumDetailImpl.fromJson(Map<String, dynamic> json) =>
      _$$AlbumDetailImplFromJson(json);

  @override
  final Album album;
// Add media_details field
  @override
  final Album galleries;

  @override
  String toString() {
    return 'AlbumDetail(album: $album, galleries: $galleries)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AlbumDetailImpl &&
            (identical(other.album, album) || other.album == album) &&
            (identical(other.galleries, galleries) ||
                other.galleries == galleries));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, album, galleries);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AlbumDetailImplCopyWith<_$AlbumDetailImpl> get copyWith =>
      __$$AlbumDetailImplCopyWithImpl<_$AlbumDetailImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AlbumDetailImplToJson(
      this,
    );
  }
}

abstract class _AlbumDetail implements AlbumDetail {
  factory _AlbumDetail(
      {required final Album album,
      required final Album galleries}) = _$AlbumDetailImpl;

  factory _AlbumDetail.fromJson(Map<String, dynamic> json) =
      _$AlbumDetailImpl.fromJson;

  @override
  Album get album;
  @override // Add media_details field
  Album get galleries;
  @override
  @JsonKey(ignore: true)
  _$$AlbumDetailImplCopyWith<_$AlbumDetailImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Media _$MediaFromJson(Map<String, dynamic> json) {
  return _Media.fromJson(json);
}

/// @nodoc
mixin _$Media {
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
  $Res call({MediaDetails media_details});

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
    Object? media_details = null,
  }) {
    return _then(_value.copyWith(
      media_details: null == media_details
          ? _value.media_details
          : media_details // ignore: cast_nullable_to_non_nullable
              as MediaDetails,
    ) as $Val);
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
  $Res call({MediaDetails media_details});

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
    Object? media_details = null,
  }) {
    return _then(_$MediaImpl(
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
  _$MediaImpl({required this.media_details});

  factory _$MediaImpl.fromJson(Map<String, dynamic> json) =>
      _$$MediaImplFromJson(json);

  @override
  final MediaDetails media_details;

  @override
  String toString() {
    return 'Media(media_details: $media_details)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MediaImpl &&
            (identical(other.media_details, media_details) ||
                other.media_details == media_details));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, media_details);

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
  factory _Media({required final MediaDetails media_details}) = _$MediaImpl;

  factory _Media.fromJson(Map<String, dynamic> json) = _$MediaImpl.fromJson;

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
  @HiveField(0)
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
  $Res call({@HiveField(0) String rendered});
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
  $Res call({@HiveField(0) String rendered});
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
  _$TitleImpl({@HiveField(0) required this.rendered});

  factory _$TitleImpl.fromJson(Map<String, dynamic> json) =>
      _$$TitleImplFromJson(json);

  @override
  @HiveField(0)
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
  factory _Title({@HiveField(0) required final String rendered}) = _$TitleImpl;

  factory _Title.fromJson(Map<String, dynamic> json) = _$TitleImpl.fromJson;

  @override
  @HiveField(0)
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

WallpaperCategory _$WallpaperCategoryFromJson(Map<String, dynamic> json) {
  return _WallpaperCategory.fromJson(json);
}

/// @nodoc
mixin _$WallpaperCategory {
  int get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  List<Wallpaper> get wallpapers => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $WallpaperCategoryCopyWith<WallpaperCategory> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WallpaperCategoryCopyWith<$Res> {
  factory $WallpaperCategoryCopyWith(
          WallpaperCategory value, $Res Function(WallpaperCategory) then) =
      _$WallpaperCategoryCopyWithImpl<$Res, WallpaperCategory>;
  @useResult
  $Res call({int id, String name, List<Wallpaper> wallpapers});
}

/// @nodoc
class _$WallpaperCategoryCopyWithImpl<$Res, $Val extends WallpaperCategory>
    implements $WallpaperCategoryCopyWith<$Res> {
  _$WallpaperCategoryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? wallpapers = null,
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
      wallpapers: null == wallpapers
          ? _value.wallpapers
          : wallpapers // ignore: cast_nullable_to_non_nullable
              as List<Wallpaper>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WallpaperCategoryImplCopyWith<$Res>
    implements $WallpaperCategoryCopyWith<$Res> {
  factory _$$WallpaperCategoryImplCopyWith(_$WallpaperCategoryImpl value,
          $Res Function(_$WallpaperCategoryImpl) then) =
      __$$WallpaperCategoryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int id, String name, List<Wallpaper> wallpapers});
}

/// @nodoc
class __$$WallpaperCategoryImplCopyWithImpl<$Res>
    extends _$WallpaperCategoryCopyWithImpl<$Res, _$WallpaperCategoryImpl>
    implements _$$WallpaperCategoryImplCopyWith<$Res> {
  __$$WallpaperCategoryImplCopyWithImpl(_$WallpaperCategoryImpl _value,
      $Res Function(_$WallpaperCategoryImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? wallpapers = null,
  }) {
    return _then(_$WallpaperCategoryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      wallpapers: null == wallpapers
          ? _value._wallpapers
          : wallpapers // ignore: cast_nullable_to_non_nullable
              as List<Wallpaper>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WallpaperCategoryImpl implements _WallpaperCategory {
  const _$WallpaperCategoryImpl(
      {required this.id,
      required this.name,
      required final List<Wallpaper> wallpapers})
      : _wallpapers = wallpapers;

  factory _$WallpaperCategoryImpl.fromJson(Map<String, dynamic> json) =>
      _$$WallpaperCategoryImplFromJson(json);

  @override
  final int id;
  @override
  final String name;
  final List<Wallpaper> _wallpapers;
  @override
  List<Wallpaper> get wallpapers {
    if (_wallpapers is EqualUnmodifiableListView) return _wallpapers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_wallpapers);
  }

  @override
  String toString() {
    return 'WallpaperCategory(id: $id, name: $name, wallpapers: $wallpapers)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WallpaperCategoryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            const DeepCollectionEquality()
                .equals(other._wallpapers, _wallpapers));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, name, const DeepCollectionEquality().hash(_wallpapers));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$WallpaperCategoryImplCopyWith<_$WallpaperCategoryImpl> get copyWith =>
      __$$WallpaperCategoryImplCopyWithImpl<_$WallpaperCategoryImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WallpaperCategoryImplToJson(
      this,
    );
  }
}

abstract class _WallpaperCategory implements WallpaperCategory {
  const factory _WallpaperCategory(
      {required final int id,
      required final String name,
      required final List<Wallpaper> wallpapers}) = _$WallpaperCategoryImpl;

  factory _WallpaperCategory.fromJson(Map<String, dynamic> json) =
      _$WallpaperCategoryImpl.fromJson;

  @override
  int get id;
  @override
  String get name;
  @override
  List<Wallpaper> get wallpapers;
  @override
  @JsonKey(ignore: true)
  _$$WallpaperCategoryImplCopyWith<_$WallpaperCategoryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Wallpaper _$WallpaperFromJson(Map<String, dynamic> json) {
  return _Wallpaper.fromJson(json);
}

/// @nodoc
mixin _$Wallpaper {
  int get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get kat_name => throw _privateConstructorUsedError;
  String get kan_name => throw _privateConstructorUsedError;
  String get category_name => throw _privateConstructorUsedError;
  String get photo => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $WallpaperCopyWith<Wallpaper> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WallpaperCopyWith<$Res> {
  factory $WallpaperCopyWith(Wallpaper value, $Res Function(Wallpaper) then) =
      _$WallpaperCopyWithImpl<$Res, Wallpaper>;
  @useResult
  $Res call(
      {int id,
      String name,
      String kat_name,
      String kan_name,
      String category_name,
      String photo});
}

/// @nodoc
class _$WallpaperCopyWithImpl<$Res, $Val extends Wallpaper>
    implements $WallpaperCopyWith<$Res> {
  _$WallpaperCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? kat_name = null,
    Object? kan_name = null,
    Object? category_name = null,
    Object? photo = null,
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
      kat_name: null == kat_name
          ? _value.kat_name
          : kat_name // ignore: cast_nullable_to_non_nullable
              as String,
      kan_name: null == kan_name
          ? _value.kan_name
          : kan_name // ignore: cast_nullable_to_non_nullable
              as String,
      category_name: null == category_name
          ? _value.category_name
          : category_name // ignore: cast_nullable_to_non_nullable
              as String,
      photo: null == photo
          ? _value.photo
          : photo // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WallpaperImplCopyWith<$Res>
    implements $WallpaperCopyWith<$Res> {
  factory _$$WallpaperImplCopyWith(
          _$WallpaperImpl value, $Res Function(_$WallpaperImpl) then) =
      __$$WallpaperImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String name,
      String kat_name,
      String kan_name,
      String category_name,
      String photo});
}

/// @nodoc
class __$$WallpaperImplCopyWithImpl<$Res>
    extends _$WallpaperCopyWithImpl<$Res, _$WallpaperImpl>
    implements _$$WallpaperImplCopyWith<$Res> {
  __$$WallpaperImplCopyWithImpl(
      _$WallpaperImpl _value, $Res Function(_$WallpaperImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? kat_name = null,
    Object? kan_name = null,
    Object? category_name = null,
    Object? photo = null,
  }) {
    return _then(_$WallpaperImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      kat_name: null == kat_name
          ? _value.kat_name
          : kat_name // ignore: cast_nullable_to_non_nullable
              as String,
      kan_name: null == kan_name
          ? _value.kan_name
          : kan_name // ignore: cast_nullable_to_non_nullable
              as String,
      category_name: null == category_name
          ? _value.category_name
          : category_name // ignore: cast_nullable_to_non_nullable
              as String,
      photo: null == photo
          ? _value.photo
          : photo // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WallpaperImpl implements _Wallpaper {
  const _$WallpaperImpl(
      {required this.id,
      required this.name,
      required this.kat_name,
      required this.kan_name,
      required this.category_name,
      required this.photo});

  factory _$WallpaperImpl.fromJson(Map<String, dynamic> json) =>
      _$$WallpaperImplFromJson(json);

  @override
  final int id;
  @override
  final String name;
  @override
  final String kat_name;
  @override
  final String kan_name;
  @override
  final String category_name;
  @override
  final String photo;

  @override
  String toString() {
    return 'Wallpaper(id: $id, name: $name, kat_name: $kat_name, kan_name: $kan_name, category_name: $category_name, photo: $photo)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WallpaperImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.kat_name, kat_name) ||
                other.kat_name == kat_name) &&
            (identical(other.kan_name, kan_name) ||
                other.kan_name == kan_name) &&
            (identical(other.category_name, category_name) ||
                other.category_name == category_name) &&
            (identical(other.photo, photo) || other.photo == photo));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, name, kat_name, kan_name, category_name, photo);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$WallpaperImplCopyWith<_$WallpaperImpl> get copyWith =>
      __$$WallpaperImplCopyWithImpl<_$WallpaperImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WallpaperImplToJson(
      this,
    );
  }
}

abstract class _Wallpaper implements Wallpaper {
  const factory _Wallpaper(
      {required final int id,
      required final String name,
      required final String kat_name,
      required final String kan_name,
      required final String category_name,
      required final String photo}) = _$WallpaperImpl;

  factory _Wallpaper.fromJson(Map<String, dynamic> json) =
      _$WallpaperImpl.fromJson;

  @override
  int get id;
  @override
  String get name;
  @override
  String get kat_name;
  @override
  String get kan_name;
  @override
  String get category_name;
  @override
  String get photo;
  @override
  @JsonKey(ignore: true)
  _$$WallpaperImplCopyWith<_$WallpaperImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CustomBanner _$CustomBannerFromJson(Map<String, dynamic> json) {
  return _CustomBanner.fromJson(json);
}

/// @nodoc
mixin _$CustomBanner {
  int get id => throw _privateConstructorUsedError;
  String get url => throw _privateConstructorUsedError;
  String get photo => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CustomBannerCopyWith<CustomBanner> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CustomBannerCopyWith<$Res> {
  factory $CustomBannerCopyWith(
          CustomBanner value, $Res Function(CustomBanner) then) =
      _$CustomBannerCopyWithImpl<$Res, CustomBanner>;
  @useResult
  $Res call({int id, String url, String photo});
}

/// @nodoc
class _$CustomBannerCopyWithImpl<$Res, $Val extends CustomBanner>
    implements $CustomBannerCopyWith<$Res> {
  _$CustomBannerCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? url = null,
    Object? photo = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      url: null == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      photo: null == photo
          ? _value.photo
          : photo // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CustomBannerImplCopyWith<$Res>
    implements $CustomBannerCopyWith<$Res> {
  factory _$$CustomBannerImplCopyWith(
          _$CustomBannerImpl value, $Res Function(_$CustomBannerImpl) then) =
      __$$CustomBannerImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int id, String url, String photo});
}

/// @nodoc
class __$$CustomBannerImplCopyWithImpl<$Res>
    extends _$CustomBannerCopyWithImpl<$Res, _$CustomBannerImpl>
    implements _$$CustomBannerImplCopyWith<$Res> {
  __$$CustomBannerImplCopyWithImpl(
      _$CustomBannerImpl _value, $Res Function(_$CustomBannerImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? url = null,
    Object? photo = null,
  }) {
    return _then(_$CustomBannerImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      url: null == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      photo: null == photo
          ? _value.photo
          : photo // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CustomBannerImpl implements _CustomBanner {
  const _$CustomBannerImpl(
      {required this.id, required this.url, required this.photo});

  factory _$CustomBannerImpl.fromJson(Map<String, dynamic> json) =>
      _$$CustomBannerImplFromJson(json);

  @override
  final int id;
  @override
  final String url;
  @override
  final String photo;

  @override
  String toString() {
    return 'CustomBanner(id: $id, url: $url, photo: $photo)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CustomBannerImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.photo, photo) || other.photo == photo));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, url, photo);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CustomBannerImplCopyWith<_$CustomBannerImpl> get copyWith =>
      __$$CustomBannerImplCopyWithImpl<_$CustomBannerImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CustomBannerImplToJson(
      this,
    );
  }
}

abstract class _CustomBanner implements CustomBanner {
  const factory _CustomBanner(
      {required final int id,
      required final String url,
      required final String photo}) = _$CustomBannerImpl;

  factory _CustomBanner.fromJson(Map<String, dynamic> json) =
      _$CustomBannerImpl.fromJson;

  @override
  int get id;
  @override
  String get url;
  @override
  String get photo;
  @override
  @JsonKey(ignore: true)
  _$$CustomBannerImplCopyWith<_$CustomBannerImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
