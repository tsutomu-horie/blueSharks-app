import 'package:html/parser.dart' as html;

/// Regular landscape images and links published in the site's TOP slider.
class WebsiteBanner {
  const WebsiteBanner(
      {required this.url,
      required this.imageUrl,
      required this.width,
      required this.height,
      required this.alt});
  final Uri url;
  final Uri imageUrl;
  final int width;
  final int height;
  final String alt;
  double get aspectRatio => width / height;

  static List<WebsiteBanner> parseHomepage(String source, Uri homepage) {
    final document = html.parse(source);
    final banners = <WebsiteBanner>[];
    final seen = <String>{};
    for (final card in document
        .querySelectorAll('.mainV--top .swiper-slide a.mainV__link')) {
      // Use the regular landscape img, not the portrait <source> variant:
      // the PDF requests a short horizontal strip inside the app.
      final image = card.querySelector('img.mainV__image');
      final url = _https(homepage, card.attributes['href']);
      final src = _https(homepage, image?.attributes['src']);
      final width = int.tryParse(image?.attributes['width'] ?? '');
      final height = int.tryParse(image?.attributes['height'] ?? '');
      if (url == null ||
          url.host != homepage.host ||
          src == null ||
          src.host != homepage.host ||
          width == null ||
          height == null ||
          width <= 0 ||
          height <= 0) {
        continue;
      }
      if (!seen.add('$url|$src')) continue;
      banners.add(WebsiteBanner(
          url: url,
          imageUrl: src,
          width: width,
          height: height,
          alt: image?.attributes['alt']?.trim() ?? ''));
    }
    return List.unmodifiable(banners);
  }

  static Uri? _https(Uri base, String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final relative = Uri.tryParse(value.trim());
    if (relative == null) return null;
    final uri = base.resolveUri(relative);
    return uri.scheme == 'https' &&
            uri.host.isNotEmpty &&
            uri.port == 443 &&
            uri.userInfo.isEmpty
        ? uri
        : null;
  }
}
