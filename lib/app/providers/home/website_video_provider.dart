import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/models/home/website_banner.dart';
import 'package:koto_blue_sharks/app/data/models/home/website_match.dart';
import 'package:koto_blue_sharks/app/data/models/home/website_player.dart';
import 'package:koto_blue_sharks/app/data/models/home/website_standings.dart';
import 'package:koto_blue_sharks/app/data/models/home/website_goods.dart';
import 'package:koto_blue_sharks/app/data/models/home/website_video.dart';
import 'package:koto_blue_sharks/utils/constant.dart';

class WebsiteVideoProvider extends GetConnect {
  WebsiteVideoProvider({Future<String> Function(Uri)? loadHomepage})
      : _loadHomepage = loadHomepage {
    // Validated rankings/schedule pages must not redirect out of their boundary.
    // Keep the existing homepage redirect behavior.
    httpClient.addRequestModifier<dynamic>((request) {
      return (request.url.path == '/rankings/' ||
              request.url.path == '/schedule-and-result/')
          ? request.copyWith(followRedirects: false)
          : request;
    });
  }

  final Future<String> Function(Uri)? _loadHomepage;

  Uri get homepage => Uri.parse(Constants.baseUrl).resolve('/');

  Future<List<WebsiteVideo>> fetchVideos() async =>
      (await fetchContent()).videos;

  /// Read once for the homepage sections so refresh cannot mix snapshots.
  Future<
      ({
        List<WebsiteVideo> videos,
        List<WebsiteGoods> goods,
        WebsiteStandings? standings,
        WebsitePlayers? players,
        Uri? scheduleUrl,
        List<WebsiteBanner> banners
      })> fetchContent() async {
    final source = await _fetchHtml(homepage);
    return (
      videos: WebsiteVideo.parseHomepage(source, homepage),
      goods: WebsiteGoods.parseHomepage(source, homepage),
      standings: WebsiteStandings.parseHomepage(source, homepage),
      players: WebsitePlayers.parseHomepage(source, homepage),
      scheduleUrl: WebsiteSchedule.parseHomepageUrl(source, homepage),
      banners: WebsiteBanner.parseHomepage(source, homepage),
    );
  }

  Future<WebsiteRankingsTable> fetchRankings(Uri url) async {
    if (!WebsiteStandings.isRankingsUrl(url, homepage)) {
      throw const WebsiteVideoRequestException();
    }
    final table =
        WebsiteRankingsTable.parse(await _fetchHtml(url), pageUrl: url);
    if (table == null) throw const WebsiteVideoRequestException();
    return table;
  }

  Future<WebsiteSchedule> fetchSchedule(Uri url) async {
    if (!WebsiteSchedule.isScheduleUrl(url, homepage)) {
      throw const WebsiteVideoRequestException();
    }
    final schedule = WebsiteSchedule.parse(await _fetchHtml(url), url);
    if (schedule == null) throw const WebsiteVideoRequestException();
    return schedule;
  }

  Future<String> _fetchHtml(Uri url) async {
    final String source;
    final loader = _loadHomepage;
    if (loader != null) {
      source = await loader(url);
    } else {
      httpClient.timeout = const Duration(seconds: 15);
      final response = await get<String>(
        url.toString(),
        decoder: (body) => body is String ? body : '',
      );
      if (response.hasError || response.body == null) {
        throw const WebsiteVideoRequestException();
      }
      source = response.body!;
    }
    if (source.length > 2 * 1024 * 1024) {
      throw const WebsiteVideoRequestException();
    }
    return source;
  }
}

class WebsiteVideoRequestException implements Exception {
  const WebsiteVideoRequestException();
}
