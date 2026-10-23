import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 背景に埋もれず、画面の表示領域を変えずに同期中であることを示します。
class TrainingSyncIndicator extends StatefulWidget {
  const TrainingSyncIndicator({super.key});

  @override
  State<TrainingSyncIndicator> createState() => _TrainingSyncIndicatorState();
}

class _TrainingSyncIndicatorState extends State<TrainingSyncIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotation = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  );
  late final Animation<double> _turns =
      Tween<double>(begin: 0, end: -1).animate(_rotation);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _rotation.stop();
    } else if (!_rotation.isAnimating) {
      _rotation.repeat();
    }
  }

  @override
  void dispose() {
    _rotation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '育成状態を同期中',
      liveRegion: true,
      child: RepaintBoundary(
        child: Container(
          width: 24.w,
          height: 24.w,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xffcbd5e1)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: RotationTransition(
            turns: _turns,
            child: Icon(Icons.sync, size: 18.w, color: const Color(0xff456477)),
          ),
        ),
      ),
    );
  }
}
