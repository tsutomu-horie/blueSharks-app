import 'package:flutter/material.dart';

import '../../../utils/app_environment.dart';

/// ビルド方式に依存せず、接続先に対応する識別表示を出します。
class EnvironmentBadge extends StatelessWidget {
  const EnvironmentBadge({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (AppEnvironment.usesProductionServices) return child;
    return Banner(
      message: AppEnvironment.badgeLabel,
      location: BannerLocation.topEnd,
      textDirection: TextDirection.ltr,
      layoutDirection: TextDirection.ltr,
      child: child,
    );
  }
}
