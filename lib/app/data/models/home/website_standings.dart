import 'package:html/parser.dart' as html;
import 'package:html/dom.dart' as dom;

class WebsiteStandings {
  const WebsiteStandings(
      {required this.title,
      required this.headers,
      required this.values,
      required this.rankingsUrl,
      this.bannerImageUrl,
      this.bannerAspectRatio,
      this.bannerLabel = 'RANK 公式戦の順位表'});
  final String title;
  final List<String> headers;
  final List<String> values;
  final Uri rankingsUrl;
  final Uri? bannerImageUrl;
  final double? bannerAspectRatio;
  final String bannerLabel;

  static WebsiteStandings? parseHomepage(String source, Uri homepage) {
    final doc = html.parse(source);
    final section = doc.querySelector('.top-game__standings');
    final title = section?.querySelector('h3')?.text.trim() ?? '';
    final headers = section
            ?.querySelectorAll('thead th')
            .map((e) => e.text.trim())
            .toList() ??
        [];
    final values = section
            ?.querySelectorAll('tbody tr')
            .firstOrNull
            ?.querySelectorAll('td')
            .map((e) => e.text.trim())
            .toList() ??
        [];
    final href =
        section?.querySelector('a.top-game__banner')?.attributes['href'];
    final uri = href == null ? null : Uri.tryParse(href);
    final url = uri == null ? null : homepage.resolveUri(uri);
    if (title.isEmpty ||
        headers.isEmpty ||
        headers.any((s) => s.isEmpty) ||
        headers.length != values.length ||
        values.any((s) => s.isEmpty) ||
        url == null ||
        !isRankingsUrl(url, homepage)) {
      return null;
    }
    final image =
        section?.querySelector('a.top-game__banner img.top-game__image');
    final rawSrc = image?.attributes['src']?.trim();
    final src = rawSrc == null || rawSrc.isEmpty ? null : Uri.tryParse(rawSrc);
    final imageUrl = src == null ? null : homepage.resolveUri(src);
    final width = int.tryParse(image?.attributes['width'] ?? '');
    final height = int.tryParse(image?.attributes['height'] ?? '');
    final validImage = imageUrl != null &&
        imageUrl.scheme == 'https' &&
        imageUrl.host == homepage.host &&
        imageUrl.userInfo.isEmpty &&
        imageUrl.port == 443 &&
        width != null &&
        width > 0 &&
        height != null &&
        height > 0;
    final label =
        image?.attributes['alt']?.replaceAll(RegExp(r'\s+'), ' ').trim() ?? '';
    return WebsiteStandings(
        title: title,
        headers: List.unmodifiable(headers),
        values: List.unmodifiable(values),
        rankingsUrl: url,
        bannerImageUrl: validImage ? imageUrl : null,
        bannerAspectRatio: validImage ? width / height : null,
        bannerLabel: label.isEmpty ? 'RANK 公式戦の順位表' : label);
  }

  /// Normalize only the year ranges actually published in TOP/detail titles.
  static String? seasonKey(String title) {
    final match = RegExp(r'\b(20[0-9]{2})\s*[-–]\s*(20[0-9]{2}|[0-9]{2})\b')
        .firstMatch(title);
    if (match == null) return null;
    final start = match.group(1)!;
    final end = match.group(2)!;
    return '$start-${end.length == 2 ? start.substring(0, 2) + end : end}';
  }

  static bool isRankingsUrl(Uri url, Uri homepage) =>
      url.scheme == 'https' &&
      url.host == homepage.host &&
      url.port == 443 &&
      url.userInfo.isEmpty &&
      url.path == '/rankings/';
}

class WebsiteRankingsTable {
  const WebsiteRankingsTable(
      {required this.title,
      required this.headers,
      required this.rows,
      this.teamLogoUrls = const []});
  final String title;
  final List<String> headers;
  final List<List<String>> rows;

  /// Aligned with [rows]; a missing/invalid logo never removes a team's results.
  final List<Uri?> teamLogoUrls;

  static WebsiteRankingsTable? parse(String source, {Uri? pageUrl}) {
    final doc = html.parse(source);
    final section = doc.querySelector('main .rankings');
    final title = section
            ?.querySelector('.rankings__heading')
            ?.text
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim() ??
        '';
    final table = section?.querySelector('.rankings__table');
    final headers = table
            ?.querySelectorAll('thead th')
            .map((e) => e.text.trim())
            .toList() ??
        [];
    final rows = <List<String>>[];
    final logos = <Uri?>[];
    for (final tr
        in table?.querySelectorAll('tbody tr') ?? const <dom.Element>[]) {
      final cells = tr
          .querySelectorAll('th, td')
          .map((e) => e.text.replaceAll(RegExp(r'\s+'), ' ').trim())
          .toList();
      // A missing team/cell makes the table incomplete; never present the
      // remaining rows as a complete ranking.
      if (cells.length != headers.length || cells.any((s) => s.isEmpty)) {
        return null;
      }
      rows.add(List.unmodifiable(cells));
      final src = tr.querySelector('img.rankings__logo')?.attributes['src'];
      final relative = src == null ? null : Uri.tryParse(src.trim());
      final logo =
          relative == null ? null : pageUrl?.resolveUri(relative) ?? relative;
      logos.add(logo != null &&
              logo.scheme == 'https' &&
              logo.host.isNotEmpty &&
              logo.userInfo.isEmpty &&
              logo.port == 443
          ? logo
          : null);
    }
    if (title.isEmpty ||
        headers.isEmpty ||
        headers.any((s) => s.isEmpty) ||
        rows.isEmpty) {
      return null;
    }
    return WebsiteRankingsTable(
        title: title,
        headers: List.unmodifiable(headers),
        rows: List.unmodifiable(rows),
        teamLogoUrls: List.unmodifiable(logos));
  }
}
