import 'package:freezed_annotation/freezed_annotation.dart';

part 'post.freezed.dart';
part 'post.g.dart';

@freezed
class Post with _$Post {
  factory Post({
    required int id,
    required String date,
    required String slug,
    required String link,
    required PostTitle title,
    required PostContent content,
    required PostExcerpt excerpt,
    required List<int> categories,
  }) = _Post;

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
}

@freezed
class PostTitle with _$PostTitle {
  factory PostTitle({
    required String rendered,
  }) = _PostTitle;

  factory PostTitle.fromJson(Map<String, dynamic> json) =>
      _$PostTitleFromJson(json);
}

@freezed
class PostContent with _$PostContent {
  factory PostContent({
    required String rendered,
    required bool protected,
  }) = _PostContent;

  factory PostContent.fromJson(Map<String, dynamic> json) =>
      _$PostContentFromJson(json);
}

@freezed
class PostExcerpt with _$PostExcerpt {
  factory PostExcerpt({
    required String rendered,
    required bool protected,
  }) = _PostExcerpt;

  factory PostExcerpt.fromJson(Map<String, dynamic> json) =>
      _$PostExcerptFromJson(json);
}
