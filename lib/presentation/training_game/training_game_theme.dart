import 'package:flutter/material.dart';

/// 育成ゲームの日本語UIに、アプリホームと同じ書体を適用します。
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
      textTheme: baseTheme.textTheme.apply(fontFamily: 'LINESeedJP'),
      primaryTextTheme:
          baseTheme.primaryTextTheme.apply(fontFamily: 'LINESeedJP'),
    );

    return Theme(
      data: gameTheme,
      child: DefaultTextStyle.merge(
        style: const TextStyle(fontFamily: 'LINESeedJP'),
        child: child,
      ),
    );
  }
}
