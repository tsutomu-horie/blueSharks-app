// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_result.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CategoryAdapter extends TypeAdapter<Category> {
  @override
  final int typeId = 0;

  @override
  Category read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Category(
      id: fields[0] as int,
      count: fields[1] as int,
      description: fields[2] as String,
      link: fields[3] as String,
      name: fields[4] as String,
      slug: fields[5] as String,
      taxonomy: fields[6] as String,
      parent: fields[7] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Category obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.count)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.link)
      ..writeByte(4)
      ..write(obj.name)
      ..writeByte(5)
      ..write(obj.slug)
      ..writeByte(6)
      ..write(obj.taxonomy)
      ..writeByte(7)
      ..write(obj.parent);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CustomFieldAdapter extends TypeAdapter<CustomField> {
  @override
  final int typeId = 4;

  @override
  CustomField read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CustomField(
      gameDate: (fields[0] as List?)?.cast<String>(),
      gameTime: (fields[1] as List?)?.cast<String>(),
      location: (fields[2] as List?)?.cast<String>(),
      team_1: (fields[3] as List?)?.cast<String>(),
      team_logo_1: (fields[4] as List?)?.cast<String>(),
      team_2: (fields[5] as List?)?.cast<String>(),
      team_logo_2: (fields[6] as List?)?.cast<String>(),
      game_result: (fields[7] as List?)?.cast<String>(),
      team_score_1: (fields[8] as List?)?.cast<String>(),
      team_score_2: (fields[9] as List?)?.cast<String>(),
      team_T_first_half_1: (fields[10] as List?)?.cast<String>(),
      team_T_second_half_1: (fields[11] as List?)?.cast<String>(),
      team_G_first_half_1: (fields[12] as List?)?.cast<String>(),
      team_G_second_half_1: (fields[13] as List?)?.cast<String>(),
      team_PG_first_half_1: (fields[14] as List?)?.cast<String>(),
      team_PG_second_half_1: (fields[15] as List?)?.cast<String>(),
      team_DG_first_half_1: (fields[16] as List?)?.cast<String>(),
      team_DG_second_half_1: (fields[17] as List?)?.cast<String>(),
      team_RESULT_first_half_1: (fields[18] as List?)?.cast<String>(),
      team_RESULT_second_half_1: (fields[19] as List?)?.cast<String>(),
      team_T_first_half_2: (fields[20] as List?)?.cast<String>(),
      team_T_second_half_2: (fields[21] as List?)?.cast<String>(),
      team_G_first_half_2: (fields[22] as List?)?.cast<String>(),
      team_G_second_half_2: (fields[23] as List?)?.cast<String>(),
      team_PG_first_half_2: (fields[24] as List?)?.cast<String>(),
      team_PG_second_half_2: (fields[25] as List?)?.cast<String>(),
      team_DG_first_half_2: (fields[26] as List?)?.cast<String>(),
      team_DG_second_half_2: (fields[27] as List?)?.cast<String>(),
      team_RESULT_first_half_2: (fields[28] as List?)?.cast<String>(),
      team_RESULT_second_half_2: (fields[29] as List?)?.cast<String>(),
      member_starting: (fields[30] as List?)?.cast<String>(),
      member_reserves: (fields[31] as List?)?.cast<String>(),
      photos: (fields[32] as List?)?.cast<String>(),
      game_serial: (fields[33] as List?)?.cast<String>(),
      member_captain: (fields[34] as List?)?.cast<String>(),
      profile_image_1: (fields[35] as List?)?.cast<String>(),
      main_image: (fields[36] as List?)?.cast<String>(),
      profile_image_2: (fields[37] as List?)?.cast<String>(),
      graph_image: (fields[38] as List?)?.cast<String>(),
      position_image: (fields[39] as List?)?.cast<String>(),
      data_position: (fields[40] as List?)?.cast<String>(),
      data_play_position: (fields[65] as List?)?.cast<String>(),
      data_number: (fields[41] as List?)?.cast<String>(),
      data_birthday: (fields[42] as List?)?.cast<String>(),
      data_height_weight: (fields[43] as List?)?.cast<String>(),
      data_birthplace: (fields[44] as List?)?.cast<String>(),
      data_school: (fields[45] as List?)?.cast<String>(),
      data_highschool: (fields[46] as List?)?.cast<String>(),
      data_university: (fields[47] as List?)?.cast<String>(),
      data_career: (fields[48] as List?)?.cast<String>(),
      data_belong: (fields[49] as List?)?.cast<String>(),
      data_award: (fields[50] as List?)?.cast<String>(),
      data_enrolledyears: (fields[51] as List?)?.cast<String>(),
      data_caps: (fields[52] as List?)?.cast<String>(),
      words_nickname: (fields[53] as List?)?.cast<String>(),
      words_dream_child_age: (fields[54] as List?)?.cast<String>(),
      words_opportunity: (fields[55] as List?)?.cast<String>(),
      words_playsseason: (fields[56] as List?)?.cast<String>(),
      words_goodplay: (fields[57] as List?)?.cast<String>(),
      words_wish: (fields[58] as List?)?.cast<String>(),
      words_myboom: (fields[59] as List?)?.cast<String>(),
      words_favoritebrand: (fields[60] as List?)?.cast<String>(),
      words_color: (fields[61] as List?)?.cast<String>(),
      words_shop: (fields[62] as List?)?.cast<String>(),
      words_gift: (fields[63] as List?)?.cast<String>(),
      words_favoritefood: (fields[64] as List?)?.cast<String>(),
      words_localfood: (fields[66] as List?)?.cast<String>(),
      youtube_embed_src: (fields[67] as List?)?.cast<String>(),
      editLock: (fields[68] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, CustomField obj) {
    writer
      ..writeByte(69)
      ..writeByte(0)
      ..write(obj.gameDate)
      ..writeByte(1)
      ..write(obj.gameTime)
      ..writeByte(2)
      ..write(obj.location)
      ..writeByte(3)
      ..write(obj.team_1)
      ..writeByte(4)
      ..write(obj.team_logo_1)
      ..writeByte(5)
      ..write(obj.team_2)
      ..writeByte(6)
      ..write(obj.team_logo_2)
      ..writeByte(7)
      ..write(obj.game_result)
      ..writeByte(8)
      ..write(obj.team_score_1)
      ..writeByte(9)
      ..write(obj.team_score_2)
      ..writeByte(10)
      ..write(obj.team_T_first_half_1)
      ..writeByte(11)
      ..write(obj.team_T_second_half_1)
      ..writeByte(12)
      ..write(obj.team_G_first_half_1)
      ..writeByte(13)
      ..write(obj.team_G_second_half_1)
      ..writeByte(14)
      ..write(obj.team_PG_first_half_1)
      ..writeByte(15)
      ..write(obj.team_PG_second_half_1)
      ..writeByte(16)
      ..write(obj.team_DG_first_half_1)
      ..writeByte(17)
      ..write(obj.team_DG_second_half_1)
      ..writeByte(18)
      ..write(obj.team_RESULT_first_half_1)
      ..writeByte(19)
      ..write(obj.team_RESULT_second_half_1)
      ..writeByte(20)
      ..write(obj.team_T_first_half_2)
      ..writeByte(21)
      ..write(obj.team_T_second_half_2)
      ..writeByte(22)
      ..write(obj.team_G_first_half_2)
      ..writeByte(23)
      ..write(obj.team_G_second_half_2)
      ..writeByte(24)
      ..write(obj.team_PG_first_half_2)
      ..writeByte(25)
      ..write(obj.team_PG_second_half_2)
      ..writeByte(26)
      ..write(obj.team_DG_first_half_2)
      ..writeByte(27)
      ..write(obj.team_DG_second_half_2)
      ..writeByte(28)
      ..write(obj.team_RESULT_first_half_2)
      ..writeByte(29)
      ..write(obj.team_RESULT_second_half_2)
      ..writeByte(30)
      ..write(obj.member_starting)
      ..writeByte(31)
      ..write(obj.member_reserves)
      ..writeByte(32)
      ..write(obj.photos)
      ..writeByte(33)
      ..write(obj.game_serial)
      ..writeByte(34)
      ..write(obj.member_captain)
      ..writeByte(35)
      ..write(obj.profile_image_1)
      ..writeByte(36)
      ..write(obj.main_image)
      ..writeByte(37)
      ..write(obj.profile_image_2)
      ..writeByte(38)
      ..write(obj.graph_image)
      ..writeByte(39)
      ..write(obj.position_image)
      ..writeByte(40)
      ..write(obj.data_position)
      ..writeByte(65)
      ..write(obj.data_play_position)
      ..writeByte(41)
      ..write(obj.data_number)
      ..writeByte(42)
      ..write(obj.data_birthday)
      ..writeByte(43)
      ..write(obj.data_height_weight)
      ..writeByte(44)
      ..write(obj.data_birthplace)
      ..writeByte(45)
      ..write(obj.data_school)
      ..writeByte(46)
      ..write(obj.data_highschool)
      ..writeByte(47)
      ..write(obj.data_university)
      ..writeByte(48)
      ..write(obj.data_career)
      ..writeByte(49)
      ..write(obj.data_belong)
      ..writeByte(50)
      ..write(obj.data_award)
      ..writeByte(51)
      ..write(obj.data_enrolledyears)
      ..writeByte(52)
      ..write(obj.data_caps)
      ..writeByte(53)
      ..write(obj.words_nickname)
      ..writeByte(54)
      ..write(obj.words_dream_child_age)
      ..writeByte(55)
      ..write(obj.words_opportunity)
      ..writeByte(56)
      ..write(obj.words_playsseason)
      ..writeByte(57)
      ..write(obj.words_goodplay)
      ..writeByte(58)
      ..write(obj.words_wish)
      ..writeByte(59)
      ..write(obj.words_myboom)
      ..writeByte(60)
      ..write(obj.words_favoritebrand)
      ..writeByte(61)
      ..write(obj.words_color)
      ..writeByte(62)
      ..write(obj.words_shop)
      ..writeByte(63)
      ..write(obj.words_gift)
      ..writeByte(64)
      ..write(obj.words_favoritefood)
      ..writeByte(66)
      ..write(obj.words_localfood)
      ..writeByte(67)
      ..write(obj.youtube_embed_src)
      ..writeByte(68)
      ..write(obj.editLock);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomFieldAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

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
      content: Rendered.fromJson(json['content'] as Map<String, dynamic>),
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
      'content': instance.content,
    };

_$CustomFieldImpl _$$CustomFieldImplFromJson(Map<String, dynamic> json) =>
    _$CustomFieldImpl(
      gameDate: (json['game_date'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      gameTime: (json['game_time'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      location: (json['location'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      team_1:
          (json['team_1'] as List<dynamic>?)?.map((e) => e as String).toList(),
      team_logo_1: (json['team_logo_1'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      team_2:
          (json['team_2'] as List<dynamic>?)?.map((e) => e as String).toList(),
      team_logo_2: (json['team_logo_2'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      game_result: (json['game_result'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      team_score_1: (json['team_score_1'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      team_score_2: (json['team_score_2'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      team_T_first_half_1: (json['team_T_first_half_1'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      team_T_second_half_1: (json['team_T_second_half_1'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      team_G_first_half_1: (json['team_G_first_half_1'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      team_G_second_half_1: (json['team_G_second_half_1'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      team_PG_first_half_1: (json['team_PG_first_half_1'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      team_PG_second_half_1: (json['team_PG_second_half_1'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      team_DG_first_half_1: (json['team_DG_first_half_1'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      team_DG_second_half_1: (json['team_DG_second_half_1'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      team_RESULT_first_half_1:
          (json['team_RESULT_first_half_1'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
      team_RESULT_second_half_1:
          (json['team_RESULT_second_half_1'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
      team_T_first_half_2: (json['team_T_first_half_2'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      team_T_second_half_2: (json['team_T_second_half_2'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      team_G_first_half_2: (json['team_G_first_half_2'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      team_G_second_half_2: (json['team_G_second_half_2'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      team_PG_first_half_2: (json['team_PG_first_half_2'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      team_PG_second_half_2: (json['team_PG_second_half_2'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      team_DG_first_half_2: (json['team_DG_first_half_2'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      team_DG_second_half_2: (json['team_DG_second_half_2'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      team_RESULT_first_half_2:
          (json['team_RESULT_first_half_2'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
      team_RESULT_second_half_2:
          (json['team_RESULT_second_half_2'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
      member_starting: (json['member_starting'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      member_reserves: (json['member_reserves'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      photos:
          (json['photos'] as List<dynamic>?)?.map((e) => e as String).toList(),
      game_serial: (json['game_serial'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      member_captain: (json['member_captain'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      profile_image_1: (json['profile_image_1'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      main_image: (json['main_image'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      profile_image_2: (json['profile_image_2'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      graph_image: (json['graph_image'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      position_image: (json['position_image'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      data_position: (json['data_position'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      data_play_position: (json['data_play_position'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      data_number: (json['data_number'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      data_birthday: (json['data_birthday'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      data_height_weight: (json['data_height_weight'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      data_birthplace: (json['data_birthplace'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      data_school: (json['data_school'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      data_highschool: (json['data_highschool'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      data_university: (json['data_university'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      data_career: (json['data_career'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      data_belong: (json['data_belong'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      data_award: (json['data_award'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      data_enrolledyears: (json['data_enrolledyears'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      data_caps: (json['data_caps'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      words_nickname: (json['words_nickname'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      words_dream_child_age: (json['words_dream_child_age'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      words_opportunity: (json['words_opportunity'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      words_playsseason: (json['words_playsseason'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      words_goodplay: (json['words_goodplay'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      words_wish: (json['words_wish'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      words_myboom: (json['words_myboom'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      words_favoritebrand: (json['words_favoritebrand'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      words_color: (json['words_color'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      words_shop: (json['words_shop'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      words_gift: (json['words_gift'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      words_favoritefood: (json['words_favoritefood'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      words_localfood: (json['words_localfood'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      youtube_embed_src: (json['youtube_embed_src'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      editLock: (json['_edit_lock'] as List<dynamic>?)
          ?.map((e) => e as String)
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
      'game_result': instance.game_result,
      'team_score_1': instance.team_score_1,
      'team_score_2': instance.team_score_2,
      'team_T_first_half_1': instance.team_T_first_half_1,
      'team_T_second_half_1': instance.team_T_second_half_1,
      'team_G_first_half_1': instance.team_G_first_half_1,
      'team_G_second_half_1': instance.team_G_second_half_1,
      'team_PG_first_half_1': instance.team_PG_first_half_1,
      'team_PG_second_half_1': instance.team_PG_second_half_1,
      'team_DG_first_half_1': instance.team_DG_first_half_1,
      'team_DG_second_half_1': instance.team_DG_second_half_1,
      'team_RESULT_first_half_1': instance.team_RESULT_first_half_1,
      'team_RESULT_second_half_1': instance.team_RESULT_second_half_1,
      'team_T_first_half_2': instance.team_T_first_half_2,
      'team_T_second_half_2': instance.team_T_second_half_2,
      'team_G_first_half_2': instance.team_G_first_half_2,
      'team_G_second_half_2': instance.team_G_second_half_2,
      'team_PG_first_half_2': instance.team_PG_first_half_2,
      'team_PG_second_half_2': instance.team_PG_second_half_2,
      'team_DG_first_half_2': instance.team_DG_first_half_2,
      'team_DG_second_half_2': instance.team_DG_second_half_2,
      'team_RESULT_first_half_2': instance.team_RESULT_first_half_2,
      'team_RESULT_second_half_2': instance.team_RESULT_second_half_2,
      'member_starting': instance.member_starting,
      'member_reserves': instance.member_reserves,
      'photos': instance.photos,
      'game_serial': instance.game_serial,
      'member_captain': instance.member_captain,
      'profile_image_1': instance.profile_image_1,
      'main_image': instance.main_image,
      'profile_image_2': instance.profile_image_2,
      'graph_image': instance.graph_image,
      'position_image': instance.position_image,
      'data_position': instance.data_position,
      'data_play_position': instance.data_play_position,
      'data_number': instance.data_number,
      'data_birthday': instance.data_birthday,
      'data_height_weight': instance.data_height_weight,
      'data_birthplace': instance.data_birthplace,
      'data_school': instance.data_school,
      'data_highschool': instance.data_highschool,
      'data_university': instance.data_university,
      'data_career': instance.data_career,
      'data_belong': instance.data_belong,
      'data_award': instance.data_award,
      'data_enrolledyears': instance.data_enrolledyears,
      'data_caps': instance.data_caps,
      'words_nickname': instance.words_nickname,
      'words_dream_child_age': instance.words_dream_child_age,
      'words_opportunity': instance.words_opportunity,
      'words_playsseason': instance.words_playsseason,
      'words_goodplay': instance.words_goodplay,
      'words_wish': instance.words_wish,
      'words_myboom': instance.words_myboom,
      'words_favoritebrand': instance.words_favoritebrand,
      'words_color': instance.words_color,
      'words_shop': instance.words_shop,
      'words_gift': instance.words_gift,
      'words_favoritefood': instance.words_favoritefood,
      'words_localfood': instance.words_localfood,
      'youtube_embed_src': instance.youtube_embed_src,
      '_edit_lock': instance.editLock,
    };

_$RenderedImpl _$$RenderedImplFromJson(Map<String, dynamic> json) =>
    _$RenderedImpl(
      rendered: json['rendered'] as String,
    );

Map<String, dynamic> _$$RenderedImplToJson(_$RenderedImpl instance) =>
    <String, dynamic>{
      'rendered': instance.rendered,
    };
