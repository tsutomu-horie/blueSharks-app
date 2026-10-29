import 'package:flutter/material.dart';

/// 育成ゲームの日本語UIをLINESeedJPのBoldで統一します。
class TrainingGameTheme extends StatelessWidget {
  const TrainingGameTheme({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);
    final gameTheme = baseTheme.copyWith(
      textTheme: _boldTextTheme(baseTheme.textTheme),
      primaryTextTheme: _boldTextTheme(baseTheme.primaryTextTheme),
    );

    return Theme(
      data: gameTheme,
      child: DefaultTextStyle.merge(
        style: const TextStyle(
          fontFamily: 'LINESeedJP',
          fontWeight: FontWeight.w700,
        ),
        child: child,
      ),
    );
  }

  static TextTheme _boldTextTheme(TextTheme base) => base
      .merge(const TextTheme(
        displayLarge: TextStyle(fontWeight: FontWeight.w700),
        displayMedium: TextStyle(fontWeight: FontWeight.w700),
        displaySmall: TextStyle(fontWeight: FontWeight.w700),
        headlineLarge: TextStyle(fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(fontWeight: FontWeight.w700),
        headlineSmall: TextStyle(fontWeight: FontWeight.w700),
        titleLarge: TextStyle(fontWeight: FontWeight.w700),
        titleMedium: TextStyle(fontWeight: FontWeight.w700),
        titleSmall: TextStyle(fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(fontWeight: FontWeight.w700),
        bodyMedium: TextStyle(fontWeight: FontWeight.w700),
        bodySmall: TextStyle(fontWeight: FontWeight.w700),
        labelLarge: TextStyle(fontWeight: FontWeight.w700),
        labelMedium: TextStyle(fontWeight: FontWeight.w700),
        labelSmall: TextStyle(fontWeight: FontWeight.w700),
      ))
      .apply(fontFamily: 'LINESeedJP');
}
