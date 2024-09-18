// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MatchResultImpl _$$MatchResultImplFromJson(Map<String, dynamic> json) =>
    _$MatchResultImpl(
      id: (json['id'] as num).toInt(),
      count: (json['count'] as num).toInt(),
      description: json['description'] as String,
      link: json['link'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      taxonomy: json['taxonomy'] as String,
      parent: (json['parent'] as num).toInt(),
    );

Map<String, dynamic> _$$MatchResultImplToJson(_$MatchResultImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'count': instance.count,
      'description': instance.description,
      'link': instance.link,
      'name': instance.name,
      'slug': instance.slug,
      'taxonomy': instance.taxonomy,
      'parent': instance.parent,
    };

_$MatchResultBySeasonImpl _$$MatchResultBySeasonImplFromJson(
        Map<String, dynamic> json) =>
    _$MatchResultBySeasonImpl(
      id: (json['id'] as num).toInt(),
      date: json['date'] as String,
      date_gmt: json['date_gmt'] as String,
      modified: json['modified'] as String,
      modified_gmt: json['modified_gmt'] as String,
      slug: json['slug'] as String,
      status: json['status'] as String,
      type: json['type'] as String,
      link: json['link'] as String,
      author: (json['author'] as num).toInt(),
      title: Rendered.fromJson(json['title'] as Map<String, dynamic>),
      featured_media: (json['featured_media'] as num).toInt(),
      comment_status: json['comment_status'] as String,
      ping_status: json['ping_status'] as String,
      sticky: json['sticky'] as bool,
      template: json['template'] as String,
      format: json['format'] as String,
      categories: (json['categories'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      tags: json['tags'] as List<dynamic>,
      jetpack_featured_media_url: json['jetpack_featured_media_url'] as String?,
      jetpack_sharing_enabled: json['jetpack_sharing_enabled'] as bool?,
      jetpack_shortlink: json['jetpack_shortlink'] as String?,
      custom_field:
          CustomField.fromJson(json['custom_field'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$MatchResultBySeasonImplToJson(
        _$MatchResultBySeasonImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date,
      'date_gmt': instance.date_gmt,
      'modified': instance.modified,
      'modified_gmt': instance.modified_gmt,
      'slug': instance.slug,
      'status': instance.status,
      'type': instance.type,
      'link': instance.link,
      'author': instance.author,
      'title': instance.title,
      'featured_media': instance.featured_media,
      'comment_status': instance.comment_status,
      'ping_status': instance.ping_status,
      'sticky': instance.sticky,
      'template': instance.template,
      'format': instance.format,
      'categories': instance.categories,
      'tags': instance.tags,
      'jetpack_featured_media_url': instance.jetpack_featured_media_url,
      'jetpack_sharing_enabled': instance.jetpack_sharing_enabled,
      'jetpack_shortlink': instance.jetpack_shortlink,
      'custom_field': instance.custom_field,
    };

_$CustomFieldImpl _$$CustomFieldImplFromJson(Map<String, dynamic> json) =>
    _$CustomFieldImpl(
      gameDate:
          (json['game_date'] as List<dynamic>).map((e) => e as String).toList(),
      gameTime:
          (json['game_time'] as List<dynamic>).map((e) => e as String).toList(),
      location:
          (json['location'] as List<dynamic>).map((e) => e as String).toList(),
      team_1:
          (json['team_1'] as List<dynamic>).map((e) => e as String).toList(),
      team_logo_1: (json['team_logo_1'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      team_2:
          (json['team_2'] as List<dynamic>).map((e) => e as String).toList(),
      team_logo_2: (json['team_logo_2'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$$CustomFieldImplToJson(_$CustomFieldImpl instance) =>
    <String, dynamic>{
      'game_date': instance.gameDate,
      'game_time': instance.gameTime,
      'location': instance.location,
      'team_1': instance.team_1,
      'team_logo_1': instance.team_logo_1,
      'team_2': instance.team_2,
      'team_logo_2': instance.team_logo_2,
    };

_$RenderedImpl _$$RenderedImplFromJson(Map<String, dynamic> json) =>
    _$RenderedImpl(
      rendered: json['rendered'] as String,
    );

Map<String, dynamic> _$$RenderedImplToJson(_$RenderedImpl instance) =>
    <String, dynamic>{
      'rendered': instance.rendered,
    };
