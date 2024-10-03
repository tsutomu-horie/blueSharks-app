import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'media.freezed.dart';
part 'media.g.dart';

@freezed
class Media with _$Media {
  factory Media({
    required MediaDetails media_details, // Add media_details field
  }) = _Media;

  factory Media.fromJson(Map<String, dynamic> json) => _$MediaFromJson(json);
}

@freezed
class Guid with _$Guid {
  factory Guid({
    required String rendered,
  }) = _Guid;

  factory Guid.fromJson(Map<String, dynamic> json) => _$GuidFromJson(json);
}

@freezed
@HiveType(typeId: 3)
class Title with _$Title {
  factory Title({
    @HiveField(0)
    required String rendered,
  }) = _Title;

  factory Title.fromJson(Map<String, dynamic> json) => _$TitleFromJson(json);
}

// Add the MediaDetails class to handle the sizes including thumbnails
@freezed
class MediaDetails with _$MediaDetails {
  factory MediaDetails({
    required int width,
    required int height,
    required String file,
    required Sizes sizes, // Add sizes to get thumbnail info
  }) = _MediaDetails;

  factory MediaDetails.fromJson(Map<String, dynamic> json) =>
      _$MediaDetailsFromJson(json);
}

@freezed
class Sizes with _$Sizes {
  factory Sizes({
    required Thumbnail thumbnail, // Add thumbnail to get thumbnail size info
    required Full full, // Add full size to get the full image info
  }) = _Sizes;

  factory Sizes.fromJson(Map<String, dynamic> json) => _$SizesFromJson(json);
}

@freezed
class Thumbnail with _$Thumbnail {
  factory Thumbnail({
    required String file,
    required int width,
    required int height,
    required String source_url, // URL to the thumbnail image
  }) = _Thumbnail;

  factory Thumbnail.fromJson(Map<String, dynamic> json) =>
      _$ThumbnailFromJson(json);
}

@freezed
class Full with _$Full {
  factory Full({
    required String file,
    required int width,
    required int height,
    required String source_url, // URL to the full image
  }) = _Full;

  factory Full.fromJson(Map<String, dynamic> json) => _$FullFromJson(json);
}
