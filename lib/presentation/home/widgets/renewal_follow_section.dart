import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'renewal_home_design.dart';

class RenewalFollowSection extends StatelessWidget {
  const RenewalFollowSection({super.key});

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
      child: AspectRatio(
          aspectRatio: 993 / 527,
          child: Stack(children: [
            Positioned.fill(
                child: Image.asset('assets/images/renewal/follow.png',
                    fit: BoxFit.contain, semanticLabel: 'FOLLOW US!!')),
            Positioned(
                left: 128,
                right: 0,
                top: 66,
                bottom: 0,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _link(
                          context,
                          'X',
                          SvgPicture.asset('assets/vectors/ic_x_twitter.svg',
                              width: 26,
                              height: 30,
                              colorFilter: const ColorFilter.mode(
                                  RenewalHomeDesign.navy, BlendMode.srcIn)),
                          'https://x.com/Bluesharks_2020'),
                      _link(
                          context,
                          'Instagram',
                          const Icon(IconsaxPlusLinear.instagram,
                              color: RenewalHomeDesign.navy, size: 30),
                          'https://www.instagram.com/shimz.bluesharks/'),
                      _link(
                          context,
                          'YouTube',
                          SvgPicture.asset('assets/images/renewal/youtube.svg',
                              width: 60,
                              height: 30,
                              colorFilter: const ColorFilter.mode(
                                  RenewalHomeDesign.navy, BlendMode.srcIn)),
                          'https://www.youtube.com/@KotoBlueSharks'),
                    ])),
          ])));

  Widget _link(BuildContext context, String label, Widget icon, String url) =>
      Expanded(
          child: IconButton(
              tooltip: label,
              icon: icon,
              onPressed: () async {
                try {
                  if (await launchUrl(Uri.parse(url),
                      mode: LaunchMode.externalApplication)) {
                    return;
                  }
                } catch (_) {
                  // Keep the other links available when an external app is unavailable.
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('SNSを開けませんでした。')));
                }
              }));
}
