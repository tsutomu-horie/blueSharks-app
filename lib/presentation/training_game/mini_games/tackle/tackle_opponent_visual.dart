import 'package:flutter/material.dart';

/// タックル画面だけで、仲間の承認済み走行コマを表示します。
class TackleOpponentVisual extends StatefulWidget {
  const TackleOpponentVisual({this.running = false, super.key});

  final bool running;

  static const assetPathA =
      'assets/images/training_game/minigames/pass_run_mate_free_a.png';
  static const assetPathB =
      'assets/images/training_game/minigames/pass_run_mate_free_b.png';

  static String assetPathForFrame(int frame) =>
      frame.isEven ? assetPathA : assetPathB;

  // Contact geometry stays calibrated to the previous 562 x 891 opponent art.
  // These values describe its legacy reference box and are not the sprite size.
  static const imageHeight = 72 * (206 / 216) * (891 / 867);
  static const imageOffsetX = -(imageWidth - 58 * 562 / 891) / 2;
  static const imageOffsetY = -1 / 3;
  static const imageWidth = imageHeight * 562 / 891;

  // The approved sprite alpha bounds are 96px tall on a 112px canvas. Match
  // the previous opponent's 867/891 alpha height while retaining its 72px
  // visual footprint and keeping the two frame bounds centered together.
  static const spriteSize = imageHeight * (112 / 96) * (867 / 891);
  static const spriteOffsetX =
      imageOffsetX + (56 - ((54 + 56.5) / 2)) * spriteSize / 112;
  static const spriteOffsetY = imageOffsetY - .5 * spriteSize / 112;
  // The widest approved run frame is slightly wider than the previous art at
  // the exit edge. Keep the legacy silhouette boundary without shifting the
  // shared center or changing the contact reference box.
  static const spriteScaleX = .94;

  @override
  State<TackleOpponentVisual> createState() => _TackleOpponentVisualState();
}

class _TackleOpponentVisualState extends State<TackleOpponentVisual>
    with SingleTickerProviderStateMixin {
  late final AnimationController _runCycle;

  @override
  void initState() {
    super.initState();
    _runCycle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 216),
    );
    if (widget.running) _runCycle.repeat();
  }

  @override
  void didUpdateWidget(covariant TackleOpponentVisual oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.running == widget.running) return;
    if (widget.running) {
      _runCycle.repeat();
    } else {
      _runCycle.stop();
    }
  }

  @override
  void dispose() {
    _runCycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeSemantics(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Preserve inherited text metrics and AnimatedAlign coordinates.
            const Opacity(
              opacity: 0,
              child: Text('🏃', style: TextStyle(fontSize: 58)),
            ),
            Positioned.fill(
              child: OverflowBox(
                minWidth: TackleOpponentVisual.spriteSize,
                maxWidth: TackleOpponentVisual.spriteSize,
                minHeight: TackleOpponentVisual.spriteSize,
                maxHeight: TackleOpponentVisual.spriteSize,
                child: Transform.translate(
                  offset: const Offset(
                    TackleOpponentVisual.spriteOffsetX,
                    TackleOpponentVisual.spriteOffsetY,
                  ),
                  child: AnimatedBuilder(
                    animation: _runCycle,
                    builder: (context, _) {
                      final frame = _runCycle.value < .5 ? 0 : 1;
                      return Transform.scale(
                        scaleX: TackleOpponentVisual.spriteScaleX,
                        child: Image.asset(
                          TackleOpponentVisual.assetPathForFrame(frame),
                          key: const Key('tackle-opponent-running-frame'),
                          width: TackleOpponentVisual.spriteSize,
                          height: TackleOpponentVisual.spriteSize,
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                          filterQuality: FilterQuality.medium,
                          excludeFromSemantics: true,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
