import 'package:freezed_annotation/freezed_annotation.dart';

part 'match_result.freezed.dart';

part 'match_result.g.dart';

@Freezed()
class MatchResult with _$MatchResult {
  factory MatchResult({
    required int id,
    required int count,
    required String description,
    required String link,
    required String name,
    required String slug,
    required String taxonomy,
    required int parent,
  }) = _MatchResult;

  factory MatchResult.fromJson(Map<String, dynamic> json) =>
      _$MatchResultFromJson(json);
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
  }) = _MatchResultBySeason;

  factory MatchResultBySeason.fromJson(Map<String, dynamic> json) =>
      _$MatchResultBySeasonFromJson(json);
}

@freezed
class CustomField with _$CustomField {
  factory CustomField({
    @JsonKey(name: 'game_date') required List<String> gameDate,
    @JsonKey(name: 'game_time') required List<String> gameTime,
    required List<String> location,
    required List<String> team_1,
    List<String>? team_logo_1,
    required List<String> team_2,
    required List<String> team_logo_2,
    required List<String>? game_result,
    // Add other fields as needed
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