import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'mini_games/mini_game_selection_frame.dart';
import 'training_home_controls.dart';
import 'training_home_decoration.dart';

/// お世話・進化・育成完了で使う共通ヘッダーです。
AppBar trainingPresentationAppBar({
  required Widget title,
  required IconData icon,
  bool primary = true,
  bool automaticallyImplyLeading = false,
  double toolbarHeight = 64,
  List<Widget>? actions,
}) =>
    AppBar(
      primary: primary,
      backgroundColor: TrainingHomeStyle.navy,
      foregroundColor: Colors.white,
      elevation: 0,
      toolbarHeight: toolbarHeight,
      automaticallyImplyLeading: automaticallyImplyLeading,
      actions: actions,
      flexibleSpace: const TrainingHomeRibbon(),
      title: Row(children: [
        Icon(icon, size: 24, color: Colors.white),
        const SizedBox(width: 12),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: DefaultTextStyle.merge(
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              child: title,
            ),
          ),
        ),
      ]),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(3),
        child: Container(height: 3, color: const Color(0xff39bdf5)),
      ),
    );

/// 画像と下部パネルの配置を共通化します。進行・演出は呼び出し元で管理します。
class TrainingPresentationBody extends StatelessWidget {
  static const characterHeight = 217.0;

  const TrainingPresentationBody({
    super.key,
    required this.illustration,
    required this.panel,
    this.illustrationAspectRatio,
    this.clipIllustration = false,
    this.illustrationSurface = MiniGameSelectionSurface.card,
  });

  final Widget illustration;
  final Widget panel;
  final double? illustrationAspectRatio;
  final bool clipIllustration;
  final MiniGameSelectionSurface illustrationSurface;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xff002b6d), Color(0xff006cb0)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(builder: (context, constraints) {
            final padding = 12.w.clamp(10.0, 20.0);
            final height = math.max(160.0, constraints.maxHeight * .66);
            final availableWidth = constraints.maxWidth - padding * 2;
            final width = illustrationAspectRatio == null
                ? availableWidth
                : math.min(availableWidth, height * illustrationAspectRatio!);
            final remaining =
                math.max(0.0, constraints.maxHeight - padding * 2 - height);
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: EdgeInsets.all(padding),
                  child: Column(children: [
                    SizedBox(
                      height: height,
                      width: double.infinity,
                      child: Center(
                        child: SizedBox(
                          width: width,
                          height: height,
                          child: MiniGameSelectionFrame(
                            surface: illustrationSurface,
                            clipContent: clipIllustration,
                            child: Center(child: illustration),
                          ),
                        ),
                      ),
                    ),
                    ConstrainedBox(
                      constraints: BoxConstraints(minHeight: remaining),
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        child: Center(child: panel),
                      ),
                    ),
                  ]),
                ),
              ),
            );
          }),
        ),
      );
}
