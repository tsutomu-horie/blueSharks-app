import 'package:flutter/material.dart';
import 'package:koto_blue_sharks/app/data/models/home/website_match.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';
import 'package:url_launcher/url_launcher.dart';

class WebsiteMatchesSection extends StatelessWidget {
  const WebsiteMatchesSection(
      {super.key, required this.schedule, required this.now});
  final WebsiteSchedule? schedule;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final data = schedule;
    if (data == null) return const SizedBox.shrink();
    final matches = data.upcoming(now);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(padding: const EdgeInsets.all(16), child: Text(data.season)),
      if (matches.isEmpty)
        const Padding(
            padding: EdgeInsets.all(16), child: Text('表示できる今後の試合はありません。')),
      if (matches.isNotEmpty)
        LayoutBuilder(builder: (context, constraints) {
          // Four complete cards fit in the phone viewport; the remaining
          // published matches remain reachable by horizontal scrolling.
          final width = (constraints.maxWidth - 32 - 8 * 3) / 4;
          return SingleChildScrollView(
              key: const ValueKey('website-matches-list'),
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                for (var index = 0; index < matches.length; index++)
                  Padding(
                      padding: EdgeInsets.only(
                          right: index == matches.length - 1 ? 0 : 8),
                      child: SizedBox(
                          key: ValueKey('website-match-card-$index'),
                          width: width,
                          child: Card(
                              margin: EdgeInsets.zero,
                              color: BrandColor.main,
                              child: Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: DefaultTextStyle.merge(
                                    style: const TextStyle(
                                        fontSize: 10, color: Colors.white),
                                    child: _card(context, matches[index], index,
                                        width - 12),
                                  ))))),
              ]));
        }),
      Padding(
          padding: const EdgeInsets.all(16),
          child: OutlinedButton(
              key: const ValueKey('website-matches-view-all'),
              onPressed: () => _open(context, data.url),
              child: const Text('VIEW ALL'))),
    ]);
  }

  Widget _card(BuildContext context, WebsiteMatch match, int index,
          double innerWidth) =>
      Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(match.league),
            const SizedBox(height: 8),
            Text(
                '${match.dateLabel}${match.day.isEmpty ? '' : ' ${match.day}'}',
                style:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            if (match.timeLabel.isNotEmpty) Text(match.timeLabel),
            if (match.hostLabel != null) Text(match.hostLabel!),
            if (match.venue.isNotEmpty)
              match.venueUrl == null
                  ? Text(match.venue)
                  : TextButton(
                      key: ValueKey('website-match-venue-$index'),
                      style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          minimumSize: const Size(0, 44)),
                      onPressed: () => _open(context, match.venueUrl!),
                      child: Text(match.venue)),
            const SizedBox(height: 8),
            SizedBox(
                height: 44,
                child: Image.network(match.opponentLogo.toString(),
                    fit: BoxFit.contain,
                    semanticLabel: match.opponentName,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.sports_rugby, color: Colors.white))),
            Text(match.opponentName,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (var action = 0; action < match.actions.length; action++)
                SizedBox(
                    width: innerWidth,
                    child: OutlinedButton(
                        key: ValueKey('website-match-action-$index-$action'),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: BrandColor.main,
                            backgroundColor: Colors.white,
                            disabledForegroundColor: Colors.white38,
                            disabledBackgroundColor: Colors.white10,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 2, vertical: 6),
                            textStyle: const TextStyle(fontSize: 9),
                            minimumSize: const Size(0, 44),
                            tapTargetSize: MaterialTapTargetSize.padded),
                        onPressed: match.actions[action].url == null
                            ? null
                            : () => _open(context, match.actions[action].url!),
                        child: Text(match.actions[action].label,
                            textAlign: TextAlign.center))),
            ]),
          ]);

  Future<void> _open(BuildContext context, Uri url) async {
    try {
      if (await launchUrl(url, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // Keep the card and its action states available for another attempt.
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('試合関連ページを開けませんでした。')));
    }
  }
}
