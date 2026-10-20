import 'package:html/parser.dart' as html;

/// A video actually linked from the public home page's video section.
class WebsiteVideo {
  const WebsiteVideo({
    required this.url,
    required this.thumbnailUrl,
    required this.title,
  });

  final Uri url;
  final Uri thumbnailUrl;
  final String title;

  static List<WebsiteVideo> parseHomepage(String source, Uri homepage) {
    final document = html.parse(source);
    final seenIds = <String>{};
    final videos = <WebsiteVideo>[];
    // Observed on blue-sharks.donati.jp on 2026-10-16. Do not scrape
    // navigation/SNS links or infer a feed from unrelated YouTube links.
    for (final card in document.querySelectorAll('.top-movie a.video-card')) {
      final href = card.attributes['href'];
      final image = card.querySelector('img');
      final src = image?.attributes['src'];
      if (href == null || src == null) continue;
      final url = _resolveHttps(homepage, href);
      final thumbnail = _resolveHttps(homepage, src);
      final title = image?.attributes['alt']?.trim() ?? '';
      if (url == null || thumbnail == null || title.isEmpty) continue;
      final id = _youtubeId(url);
      if (id == null || !seenIds.add(id)) continue;
      videos.add(WebsiteVideo(url: url, thumbnailUrl: thumbnail, title: title));
    }
    return List.unmodifiable(videos);
  }

  static Uri? _resolveHttps(Uri base, String value) {
    final parsed = Uri.tryParse(value.trim());
    if (parsed == null || value.trim().isEmpty) return null;
    final uri = base.resolveUri(parsed);
    if (uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.port != 443) {
      return null;
    }
    return uri;
  }

  static String? _youtubeId(Uri uri) {
    final String? id;
    if (uri.host == 'youtu.be' && uri.pathSegments.length == 1) {
      id = uri.pathSegments.single;
    } else if ((uri.host == 'youtube.com' || uri.host == 'www.youtube.com') &&
        uri.path == '/watch') {
      id = uri.queryParameters['v'];
    } else {
      return null;
    }
    return id != null && RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(id)
        ? id
        : null;
  }
}
