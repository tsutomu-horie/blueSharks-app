class GameGuideMedia {
  const GameGuideMedia({
    required this.postId,
    required this.sourceUrl,
    required this.label,
    this.thumbnailUrl,
    this.width,
    this.height,
  });

  final int postId;
  final String sourceUrl;
  final String label;
  final String? thumbnailUrl;
  final int? width;
  final int? height;

  String get displayUrl => thumbnailUrl ?? sourceUrl;

  int get keyVisualScore {
    final normalizedLabel = label.toLowerCase();
    var score = 0;

    if (width != null && height != null && height! >= 500) {
      final aspectRatio = width! / height!;
      if (aspectRatio >= 0.82 && aspectRatio <= 0.90) {
        score += 100;
      }
    }

    if (normalizedLabel.contains('428_500') ||
        normalizedLabel.contains('500_428')) {
      score += 60;
    }
    if (normalizedLabel.contains('mainvisual')) {
      score += 30;
    }
    if (normalizedLabel.contains('kv_sp') ||
        normalizedLabel.contains('_sp') ||
        normalizedLabel.contains('-sp')) {
      score += 20;
    }
    if (normalizedLabel.contains('kv_pc') ||
        normalizedLabel.contains('_pc') ||
        normalizedLabel.contains('-pc')) {
      score -= 100;
    }

    return score;
  }

  static GameGuideMedia? fromJsonOrNull(Map<String, dynamic> json) {
    final postId = _int(json['post']);
    final sourceUrl = _string(json['source_url']);
    if (postId == null ||
        postId <= 0 ||
        sourceUrl == null ||
        sourceUrl.isEmpty) {
      return null;
    }

    final mediaDetails = _map(json['media_details']);
    final thumbnail = _map(_map(mediaDetails['sizes'])['thumbnail']);
    final title = _map(json['title']);

    return GameGuideMedia(
      postId: postId,
      sourceUrl: sourceUrl,
      thumbnailUrl: _nonEmptyString(thumbnail['source_url']),
      width: _int(mediaDetails['width']),
      height: _int(mediaDetails['height']),
      label: [
        _string(title['rendered']),
        _string(json['slug']),
        sourceUrl,
      ].whereType<String>().join(' '),
    );
  }

  static Map<String, dynamic> _map(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return const <String, dynamic>{};
  }

  static String? _nonEmptyString(dynamic value) {
    final result = _string(value);
    return result == null || result.isEmpty ? null : result;
  }

  static String? _string(dynamic value) => value?.toString();

  static int? _int(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }
}

String? selectGameGuideThumbnail(Iterable<GameGuideMedia> mediaItems) {
  GameGuideMedia? selected;
  for (final media in mediaItems) {
    if (media.keyVisualScore < 100) continue;
    if (selected == null || media.keyVisualScore > selected.keyVisualScore) {
      selected = media;
    }
  }
  return selected?.displayUrl;
}
