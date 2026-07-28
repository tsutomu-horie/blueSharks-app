class GameGuidePost {
  const GameGuidePost({
    required this.id,
    required this.title,
    required this.publishedAt,
    required this.detailUrl,
    this.thumbnailUrl,
    this.season,
    this.location,
    this.status,
  });

  final int id;
  final String title;
  final DateTime? publishedAt;
  final String detailUrl;
  final String? thumbnailUrl;

  // WordPress側の正式な絞り込みフィールドが未確定のため、
  // 仮実装では acf または直下に同名項目がある場合のみ利用する。
  final String? season;
  final String? location;
  final String? status;

  GameGuidePost withThumbnail(String thumbnailUrl) {
    return GameGuidePost(
      id: id,
      title: title,
      publishedAt: publishedAt,
      detailUrl: detailUrl,
      thumbnailUrl: thumbnailUrl,
      season: season,
      location: location,
      status: status,
    );
  }

  factory GameGuidePost.fromJson(Map<String, dynamic> json) {
    final title = _nestedString(json, ['title', 'rendered']);
    final detailUrl = _string(json['link']);
    if (title == null ||
        title.isEmpty ||
        detailUrl == null ||
        detailUrl.isEmpty) {
      throw const FormatException('Required game guide fields are missing.');
    }

    final acf = json['acf'] is Map
        ? Map<String, dynamic>.from(json['acf'] as Map)
        : const <String, dynamic>{};

    return GameGuidePost(
      id: _int(json['id']) ?? 0,
      title: _stripHtml(title),
      publishedAt: DateTime.tryParse(_string(json['date']) ?? ''),
      detailUrl: detailUrl,
      thumbnailUrl: _featuredImageUrl(json),
      season: _firstString(acf['season'], json['season']),
      location: _firstString(acf['location'], json['location']),
      status: _firstString(
        acf['game_status'] ?? acf['status'],
        json['game_status'] ?? json['status'],
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'publishedAt': publishedAt?.toIso8601String(),
        'detailUrl': detailUrl,
        'thumbnailUrl': thumbnailUrl,
        'season': season,
        'location': location,
        'status': status,
      };

  factory GameGuidePost.fromCacheJson(Map<String, dynamic> json) {
    return GameGuidePost(
      id: _int(json['id']) ?? 0,
      title: _string(json['title']) ?? '',
      publishedAt: DateTime.tryParse(_string(json['publishedAt']) ?? ''),
      detailUrl: _string(json['detailUrl']) ?? '',
      thumbnailUrl: _string(json['thumbnailUrl']),
      season: _string(json['season']),
      location: _string(json['location']),
      status: _string(json['status']),
    );
  }

  static String? _featuredImageUrl(Map<String, dynamic> json) {
    final embedded = json['_embedded'];
    if (embedded is Map) {
      final media = embedded['wp:featuredmedia'];
      if (media is List && media.isNotEmpty && media.first is Map) {
        final source = _string((media.first as Map)['source_url']);
        if (source != null && source.isNotEmpty) {
          return source;
        }
      }
    }

    return _firstString(
      json['thumbnail_url'],
      json['featured_image_url'],
    );
  }

  static String? _nestedString(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    dynamic value = json;
    for (final key in keys) {
      if (value is! Map || !value.containsKey(key)) {
        return null;
      }
      value = value[key];
    }
    return _string(value);
  }

  static String? _firstString(dynamic first, dynamic second) {
    final firstValue = _string(first);
    if (firstValue != null && firstValue.isNotEmpty) {
      return firstValue;
    }
    final secondValue = _string(second);
    return secondValue == null || secondValue.isEmpty ? null : secondValue;
  }

  static String? _string(dynamic value) {
    if (value == null) return null;
    if (value is List && value.isNotEmpty) return _string(value.first);
    return value.toString();
  }

  static int? _int(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  static String _stripHtml(String value) {
    return value
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#8211;', '–')
        .replaceAll('&#8212;', '—')
        .replaceAll('&#8230;', '…')
        .trim();
  }
}
