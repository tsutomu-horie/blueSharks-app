import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'match_result.freezed.dart';

part 'match_result.g.dart';

@HiveType(typeId: 0)
@Freezed()
class Category with _$Category {
  const factory Category({
    @HiveField(0)
    required int id,
    @HiveField(1)
    required int count,
    @HiveField(2)
    required String description,
    @HiveField(3)
    required String link,
    @HiveField(4)
    required String name,
    @HiveField(5)
    required String slug,
    @HiveField(6)
    required String taxonomy,
    @HiveField(7)
    required int parent,
  }) = _MatchResult;

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);
}

@Freezed()
class MatchResultBySeason with _$MatchResultBySeason {
  factory MatchResultBySeason({
    required int id,
    required String date,
    required String date_gmt,
    required String modified,
    required String modified_gmt,
    required String slug,
    required String status,
    required String type,
    required String link,
    required int author,
    required Rendered title,
    required int featured_media,
    required String comment_status,
    required String ping_status,
    required bool sticky,
    required String template,
    required String format,
    required List<int> categories,
    required List<dynamic> tags,
    required String? jetpack_featured_media_url,
    required bool? jetpack_sharing_enabled,
    required String? jetpack_shortlink,
    required CustomField custom_field,
    required Rendered content,
  }) = _MatchResultBySeason;

  factory MatchResultBySeason.fromJson(Map<String, dynamic> json) =>
      _$MatchResultBySeasonFromJson(json);
}

@freezed
@HiveType(typeId: 4)
class CustomField with _$CustomField {
  factory CustomField({
    @HiveField(0)
    @JsonKey(name: 'game_date') required List<String>? gameDate,
    @HiveField(1)
    @JsonKey(name: 'game_time') required List<String>? gameTime,
    @HiveField(2)
    required List<String>? location,
    @HiveField(3)
    required List<String>? team_1,
    @HiveField(4)
    List<String>? team_logo_1,
    @HiveField(5)
    required List<String>? team_2,
    @HiveField(6)
    required List<String>? team_logo_2,
    @HiveField(7)
    required List<String>? game_result,
    @HiveField(8)
    required List<String>? team_score_1,
    @HiveField(9)
    required List<String>? team_score_2,
    @HiveField(10)
    required List<String>? team_T_first_half_1,
    @HiveField(11)
    required List<String>? team_T_second_half_1,
    @HiveField(12)
    required List<String>? team_G_first_half_1,
    @HiveField(13)
    required List<String>? team_G_second_half_1,
    @HiveField(14)
    required List<String>? team_PG_first_half_1,
    @HiveField(15)
    required List<String>? team_PG_second_half_1,
    @HiveField(16)
    required List<String>? team_DG_first_half_1,
    @HiveField(17)
    required List<String>? team_DG_second_half_1,
    @HiveField(18)
    required List<String>? team_RESULT_first_half_1,
    @HiveField(19)
    required List<String>? team_RESULT_second_half_1,
    @HiveField(20)
    required List<String>? team_T_first_half_2,
    @HiveField(21)
    required List<String>? team_T_second_half_2,
    @HiveField(22)
    required List<String>? team_G_first_half_2,
    @HiveField(23)
    required List<String>? team_G_second_half_2,
    @HiveField(24)
    required List<String>? team_PG_first_half_2,
    @HiveField(25)
    required List<String>? team_PG_second_half_2,
    @HiveField(26)
    required List<String>? team_DG_first_half_2,
    @HiveField(27)
    required List<String>? team_DG_second_half_2,
    @HiveField(28)
    required List<String>? team_RESULT_first_half_2,
    @HiveField(29)
    required List<String>? team_RESULT_second_half_2,
    @HiveField(30)
    required List<String>? member_starting,
    @HiveField(31)
    required List<String>? member_reserves,
    @HiveField(32)
    required List<String>? photos,
    @HiveField(33)
    required List<String>? game_serial,
    @HiveField(34)
    required List<String>? member_captain,

    //specific for player
    @HiveField(35)
    List<String>? profile_image_1, //for profile picture
    @HiveField(36)
    List<String>? main_image,
    @HiveField(37)
    List<String>? profile_image_2,
    @HiveField(38)
    List<String>? graph_image,
    @HiveField(39)
    List<String>? position_image,

    @HiveField(40)
    List<String>? data_position,
    @HiveField(65)
    List<String>? data_play_position,
    @HiveField(41)
    List<String>? data_number,
    @HiveField(42)
    List<String>? data_birthday,
    @HiveField(43)
    List<String>? data_height_weight,
    @HiveField(44)
    List<String>? data_birthplace,
    @HiveField(45)
    List<String>? data_school,
    @HiveField(46)
    List<String>? data_highschool,
    @HiveField(47)
    List<String>? data_university,
    @HiveField(48)
    List<String>? data_career,
    @HiveField(49)
    List<String>? data_belong,
    @HiveField(50)
    List<String>? data_award,
    @HiveField(51)
    List<String>? data_enrolledyears,
    @HiveField(52)
    List<String>? data_caps,

    @HiveField(53)
    List<String>? words_nickname,
    @HiveField(54)
    List<String>? words_dream_child_age,
    @HiveField(55)
    List<String>? words_opportunity,
    @HiveField(56)
    List<String>? words_playsseason,
    @HiveField(57)
    List<String>? words_goodplay,
    @HiveField(58)
    List<String>? words_wish,
    @HiveField(59)
    List<String>? words_myboom,
    @HiveField(60)
    List<String>? words_favoritebrand,
    @HiveField(61)
    List<String>? words_color,
    @HiveField(62)
    List<String>? words_shop,
    @HiveField(63)
    List<String>? words_gift,
    @HiveField(64)
    List<String>? words_favoritefood,
    @HiveField(66)
    List<String>? words_localfood,
    @HiveField(67)
    List<String>? youtube_embed_src,
  }) = _CustomField;

  factory CustomField.fromJson(Map<String, dynamic> json) =>
      _$CustomFieldFromJson(json);
}

@freezed
class Rendered with _$Rendered {
  factory Rendered({
    required String rendered,
  }) = _Rendered;

  factory Rendered.fromJson(Map<String, dynamic> json) => _$RenderedFromJson(json);
}