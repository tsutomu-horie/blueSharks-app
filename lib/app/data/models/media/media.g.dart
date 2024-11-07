// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TitleAdapter extends TypeAdapter<Title> {
  @override
  final int typeId = 3;

  @override
  Title read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Title(
      rendered: fields[0] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Title obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.rendered);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TitleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AlbumImpl _$$AlbumImplFromJson(Map<String, dynamic> json) => _$AlbumImpl(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String?,
      photo: json['photo'] as String?,
      date: json['date'] as String?,
    );

Map<String, dynamic> _$$AlbumImplToJson(_$AlbumImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'photo': instance.photo,
      'date': instance.date,
    };

_$AlbumDetailImpl _$$AlbumDetailImplFromJson(Map<String, dynamic> json) =>
    _$AlbumDetailImpl(
      album: Album.fromJson(json['album'] as Map<String, dynamic>),
      galleries: Album.fromJson(json['galleries'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$AlbumDetailImplToJson(_$AlbumDetailImpl instance) =>
    <String, dynamic>{
      'album': instance.album,
      'galleries': instance.galleries,
    };

_$MediaImpl _$$MediaImplFromJson(Map<String, dynamic> json) => _$MediaImpl(
      media_details:
          MediaDetails.fromJson(json['media_details'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$MediaImplToJson(_$MediaImpl instance) =>
    <String, dynamic>{
      'media_details': instance.media_details,
    };

_$GuidImpl _$$GuidImplFromJson(Map<String, dynamic> json) => _$GuidImpl(
      rendered: json['rendered'] as String,
    );

Map<String, dynamic> _$$GuidImplToJson(_$GuidImpl instance) =>
    <String, dynamic>{
      'rendered': instance.rendered,
    };

_$TitleImpl _$$TitleImplFromJson(Map<String, dynamic> json) => _$TitleImpl(
      rendered: json['rendered'] as String,
    );

Map<String, dynamic> _$$TitleImplToJson(_$TitleImpl instance) =>
    <String, dynamic>{
      'rendered': instance.rendered,
    };

_$MediaDetailsImpl _$$MediaDetailsImplFromJson(Map<String, dynamic> json) =>
    _$MediaDetailsImpl(
      width: (json['width'] as num).toInt(),
      height: (json['height'] as num).toInt(),
      file: json['file'] as String,
      sizes: Sizes.fromJson(json['sizes'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$MediaDetailsImplToJson(_$MediaDetailsImpl instance) =>
    <String, dynamic>{
      'width': instance.width,
      'height': instance.height,
      'file': instance.file,
      'sizes': instance.sizes,
    };

_$SizesImpl _$$SizesImplFromJson(Map<String, dynamic> json) => _$SizesImpl(
      thumbnail: Thumbnail.fromJson(json['thumbnail'] as Map<String, dynamic>),
      full: Full.fromJson(json['full'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$SizesImplToJson(_$SizesImpl instance) =>
    <String, dynamic>{
      'thumbnail': instance.thumbnail,
      'full': instance.full,
    };

_$ThumbnailImpl _$$ThumbnailImplFromJson(Map<String, dynamic> json) =>
    _$ThumbnailImpl(
      file: json['file'] as String,
      width: (json['width'] as num).toInt(),
      height: (json['height'] as num).toInt(),
      source_url: json['source_url'] as String,
    );

Map<String, dynamic> _$$ThumbnailImplToJson(_$ThumbnailImpl instance) =>
    <String, dynamic>{
      'file': instance.file,
      'width': instance.width,
      'height': instance.height,
      'source_url': instance.source_url,
    };

_$FullImpl _$$FullImplFromJson(Map<String, dynamic> json) => _$FullImpl(
      file: json['file'] as String,
      width: (json['width'] as num).toInt(),
      height: (json['height'] as num).toInt(),
      source_url: json['source_url'] as String,
    );

Map<String, dynamic> _$$FullImplToJson(_$FullImpl instance) =>
    <String, dynamic>{
      'file': instance.file,
      'width': instance.width,
      'height': instance.height,
      'source_url': instance.source_url,
    };

_$WallpaperCategoryImpl _$$WallpaperCategoryImplFromJson(
        Map<String, dynamic> json) =>
    _$WallpaperCategoryImpl(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      wallpapers: (json['wallpapers'] as List<dynamic>)
          .map((e) => Wallpaper.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$WallpaperCategoryImplToJson(
        _$WallpaperCategoryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'wallpapers': instance.wallpapers,
    };

_$WallpaperImpl _$$WallpaperImplFromJson(Map<String, dynamic> json) =>
    _$WallpaperImpl(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      kat_name: json['kat_name'] as String,
      kan_name: json['kan_name'] as String,
      category_name: json['category_name'] as String,
      photo: json['photo'] as String,
    );

Map<String, dynamic> _$$WallpaperImplToJson(_$WallpaperImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'kat_name': instance.kat_name,
      'kan_name': instance.kan_name,
      'category_name': instance.category_name,
      'photo': instance.photo,
    };
