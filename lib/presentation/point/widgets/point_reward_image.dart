import 'package:flutter/material.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';

class PointRewardImage extends StatelessWidget {
  const PointRewardImage({super.key, required this.url, this.iconSize = 24});

  final String? url;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    Widget fallback() => Center(
          child:
              Icon(Icons.card_giftcard, size: iconSize, color: BrandColor.main),
        );

    if (url == null || url!.isEmpty) return fallback();
    return Image.network(
      url!,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => fallback(),
    );
  }
}
