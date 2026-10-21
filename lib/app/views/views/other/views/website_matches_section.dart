import 'package:flutter/material.dart';
import 'package:koto_blue_sharks/app/data/models/home/website_match.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:koto_blue_sharks/presentation/home/widgets/renewal_home_design.dart';

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
      if (matches.isEmpty)
        const Padding(
            padding: EdgeInsets.all(16), child: Text('表示できる今後の試合はありません。')),
      if (matches.isNotEmpty)
        LayoutBuilder(builder: (context, constraints) {
          final width = (constraints.maxWidth * .86).clamp(280.0, 420.0);
          return SingleChildScrollView(
              key: const ValueKey('website-matches-list'),
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                for (var index = 0; index < matches.length; index++)
                  Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: SizedBox(
                          width: width,
                          child: Container(
                              decoration: BoxDecoration(
                                  color: RenewalHomeDesign.navy,
                                  borderRadius: BorderRadius.circular(12),
                                  image: const DecorationImage(
                                      image: AssetImage(
                                          'assets/images/renewal/match_background.jpg'),
                                      fit: BoxFit.cover,
                                      colorFilter: ColorFilter.mode(
                                          RenewalHomeDesign.navy,
                                          BlendMode.multiply))),
                              padding: const EdgeInsets.all(24),
                              child: DefaultTextStyle(
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'LINESeedJP',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700),
                                  child: _card(context, matches[index], index,
                                      width - 48))))),
              ]));
        }),
      Padding(
          padding: const EdgeInsets.all(16),
          child: RenewalViewAllButton(
              key: const ValueKey('website-matches-view-all'),
              onPressed: () => _open(context, data.url))),
    ]);
  }

  Widget _card(BuildContext context, WebsiteMatch match, int index,
          double innerWidth) =>
      Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(match.league, style: const TextStyle(fontSize: 11)),
            const SizedBox(height: 10),
            Wrap(
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: 6,
                children: [
                  Text(match.dateLabel,
                      style: const TextStyle(
                          fontSize: 28,
                          height: 1.1,
                          fontWeight: FontWeight.w900)),
                  Text(match.day.toUpperCase(),
                      style: const TextStyle(fontSize: 13)),
                ]),
            if (match.timeLabel.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(match.timeLabel, style: const TextStyle(fontSize: 15)),
            ],
            const SizedBox(height: 10),
            Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (match.hostLabel != null)
                    Container(
                        color: RenewalHomeDesign.cyan,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 3),
                        child: Text(match.hostLabel!,
                            style: const TextStyle(fontSize: 10))),
                  if (match.venue.isNotEmpty)
                    match.venueUrl == null
                        ? Text(match.venue)
                        : TextButton(
                            key: ValueKey('website-match-venue-$index'),
                            style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 32),
                                tapTargetSize: MaterialTapTargetSize.padded,
                                textStyle: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w700)),
                            onPressed: () => _open(context, match.venueUrl!),
                            child: Text(match.venue)),
                ]),
            const SizedBox(height: 16),
            Row(children: [
              SizedBox(
                  width: 64,
                  height: 64,
                  child: Image.network(match.opponentLogo.toString(),
                      fit: BoxFit.contain,
                      semanticLabel: match.opponentName,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.sports_rugby, color: Colors.white))),
              const SizedBox(width: 16),
              Expanded(
                  child: Text(match.opponentName,
                      style: const TextStyle(
                          fontSize: 16,
                          height: 1.4,
                          fontWeight: FontWeight.w800))),
            ]),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final action in [0, 1, 3, 2])
                SizedBox(
                    width: (innerWidth - 8) / 2,
                    child: OutlinedButton(
                        key: ValueKey('website-match-action-$index-$action'),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: RenewalHomeDesign.navy,
                            backgroundColor: Colors.white,
                            disabledForegroundColor: const Color(0xff7294bf),
                            disabledBackgroundColor: const Color(0xff001c47),
                            minimumSize: const Size(0, 44),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 6),
                            shape: const RoundedRectangleBorder(),
                            side: BorderSide.none,
                            textStyle: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w700)),
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
