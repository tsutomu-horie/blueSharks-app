import 'package:flutter/material.dart';

import '../training_home_controls.dart';
import 'mini_game_selection_frame.dart';

const miniGameBackground = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xff002b6d), Color(0xff006cb0)],
);

/// ゲームの操作・進行に依存しない共通のボタン表示です。
class MiniGameButtonTheme extends StatelessWidget {
  const MiniGameButtonTheme(
      {super.key, required this.child, this.light = false});
  final Widget child;
  final bool light;

  @override
  Widget build(BuildContext context) => ElevatedButtonTheme(
        data: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: light ? Colors.white : TrainingHomeStyle.navy,
            foregroundColor: light ? TrainingHomeStyle.navy : Colors.white,
            minimumSize: const Size(120, 48),
            elevation: 0,
            shape: const BeveledRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(8))),
          ),
        ),
        child: child,
      );
}

/// フィールドを隠しすぎず、開始・一時停止・結果を共通の枠で表示します。
class MiniGameOverlayPanel extends StatelessWidget {
  const MiniGameOverlayPanel(
      {super.key, required this.child, this.dark = false});
  final Widget child;
  final bool dark;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: TrainingHomeStyle.navy.withValues(alpha: .45),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: MiniGameSelectionFrame(
                surface: dark
                    ? MiniGameSelectionSurface.window
                    : MiniGameSelectionSurface.card,
                padding: const EdgeInsets.all(18),
                child: DefaultTextStyle.merge(
                  style: TextStyle(
                      color: dark ? Colors.white : TrainingHomeStyle.navy),
                  child: MiniGameButtonTheme(light: dark, child: child),
                ),
              ),
            ),
          ),
        ),
      );
}

Widget miniGamePauseControl({
  required bool paused,
  required VoidCallback onPressed,
}) =>
    Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Center(
        child: MiniGameSelectionFrame(
          surface: MiniGameSelectionSurface.close,
          child: SizedBox(
            width: 44,
            height: 44,
            child: IconButton(
              onPressed: onPressed,
              tooltip: paused ? '再開' : '一時停止',
              icon: Icon(paused ? Icons.play_arrow : Icons.pause,
                  color: TrainingHomeStyle.navy),
            ),
          ),
        ),
      ),
    );
