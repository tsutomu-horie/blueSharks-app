// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PostImpl _$$PostImplFromJson(Map<String, dynamic> json) => _$PostImpl(
      id: (json['id'] as num).toInt(),
      date: json['date'] as String,
      slug: json['slug'] as String,
      link: json['link'] as String,
      title: PostTitle.fromJson(json['title'] as Map<String, dynamic>),
      content: PostContent.fromJson(json['content'] as Map<String, dynamic>),
      excerpt: PostExcerpt.fromJson(json['excerpt'] as Map<String, dynamic>),
      categories: (json['categories'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      featured_media: (json['featured_media'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$PostImplToJson(_$PostImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date,
      'slug': instance.slug,
      'link': instance.link,
      'title': instance.title,
      'content': instance.content,
      'excerpt': instance.excerpt,
      'categories': instance.categories,
      'featured_media': instance.featured_media,
    };

_$PostTitleImpl _$$PostTitleImplFromJson(Map<String, dynamic> json) =>
    _$PostTitleImpl(
      rendered: json['rendered'] as String,
    );

Map<String, dynamic> _$$PostTitleImplToJson(_$PostTitleImpl instance) =>
    <String, dynamic>{
      'rendered': instance.rendered,
    };

_$PostContentImpl _$$PostContentImplFromJson(Map<String, dynamic> json) =>
    _$PostContentImpl(
      rendered: json['rendered'] as String,
      protected: json['protected'] as bool,
    );

Map<String, dynamic> _$$PostContentImplToJson(_$PostContentImpl instance) =>
    <String, dynamic>{
      'rendered': instance.rendered,
      'protected': instance.protected,
    };

_$PostExcerptImpl _$$PostExcerptImplFromJson(Map<String, dynamic> json) =>
    _$PostExcerptImpl(
      rendered: json['rendered'] as String,
      protected: json['protected'] as bool,
    );

Map<String, dynamic> _$$PostExcerptImplToJson(_$PostExcerptImpl instance) =>
    <String, dynamic>{
      'rendered': instance.rendered,
      'protected': instance.protected,
    };
