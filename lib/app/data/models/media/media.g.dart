// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MediaImpl _$$MediaImplFromJson(Map<String, dynamic> json) => _$MediaImpl(
      id: (json['id'] as num).toInt(),
      date: json['date'] as String,
      modified: json['modified'] as String,
      guid: Guid.fromJson(json['guid'] as Map<String, dynamic>),
      slug: json['slug'] as String,
      status: json['status'] as String,
      type: json['type'] as String,
      link: json['link'] as String,
      title: Title.fromJson(json['title'] as Map<String, dynamic>),
      source_url: json['source_url'] as String,
      media_details:
          MediaDetails.fromJson(json['media_details'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$MediaImplToJson(_$MediaImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date,
      'modified': instance.modified,
      'guid': instance.guid,
      'slug': instance.slug,
      'status': instance.status,
      'type': instance.type,
      'link': instance.link,
      'title': instance.title,
      'source_url': instance.source_url,
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
