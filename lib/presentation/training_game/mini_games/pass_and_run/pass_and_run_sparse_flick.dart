import 'package:flutter/gestures.dart';
import 'dart:ui' show Rect;

import 'pass_and_run_logic.dart';

/// 終了速度を推定できない少数サンプルの入力だけを補完します。
class PassRunSparseFlick {
  final Set<int> _pointers = {};
  PointerDownEvent? _down;
  PointerMoveEvent? _lastMove;
  PointerUpEvent? _up;
  int _moves = 0;
  bool _startedInsideField = false;
  bool _startedWhenReady = false;
  bool _blocked = false;
  bool _stationaryMove = false;

  void down(PointerDownEvent event,
      {required Rect? fieldBounds, required bool ready}) {
    if (_pointers.isEmpty) {
      _down = event;
      // コート内で始めた操作は、指が外へ出てもリリースまで追跡する。
      _startedInsideField = fieldBounds?.contains(event.position) ?? false;
      _startedWhenReady = ready;
      _lastMove = null;
      _up = null;
      _moves = 0;
      _blocked = false;
      _stationaryMove = false;
    } else {
      _blocked = true;
    }
    _pointers.add(event.pointer);
  }

  void move(PointerMoveEvent event) {
    if (event.pointer != _down?.pointer) return;
    _stationaryMove =
        event.position == (_lastMove?.position ?? _down!.position);
    _lastMove = event;
    _moves++;
  }

  void up(PointerUpEvent event) {
    _pointers.remove(event.pointer);
    if (event.pointer == _down?.pointer) {
      _up = event;
    }
  }

  void cancel(PointerCancelEvent event) {
    _pointers.remove(event.pointer);
    _blocked = true;
  }

  bool get blocked => _blocked || !_startedWhenReady || !_startedInsideField;

  void block() => _blocked = true;

  PassFlick resolve(PassFlick original) {
    final down = _down, move = _lastMove, up = _up;
    // raw move数はSDKの有効サンプル数ではない。SDKはdown等を含む履歴を
    // 時間窓・連続性で絞り込むため、1～2moveは保守的な補完対象の上限。
    if (!_startedInsideField ||
        original.speed != 0 ||
        _blocked ||
        _stationaryMove ||
        down == null ||
        move == null ||
        up == null ||
        _moves < 1 ||
        _moves > 2) {
      return original;
    }
    final elapsed = up.timeStamp - down.timeStamp;
    final idle = up.timeStamp - move.timeStamp;
    // Flutterの速度推定範囲100ms以内に限定し、離す直前まで動いた入力のみ。
    // 16msは60Hzの1フレーム以内。停止後のリリースは補完しない。
    if (elapsed <= Duration.zero ||
        elapsed > const Duration(milliseconds: 100) ||
        idle < Duration.zero ||
        idle > const Duration(milliseconds: 16)) {
      return original;
    }
    final delta = move.position - down.position;
    final seconds = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    return PassFlick(
      deltaX: original.deltaX,
      deltaY: original.deltaY,
      velocityX: delta.dx / seconds,
      velocityY: delta.dy / seconds,
    );
  }
}
