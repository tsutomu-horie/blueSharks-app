import 'package:flutter/material.dart';

import 'tackle_opponent_visual.dart';
import 'tackle_player_visual.dart';

class TackleContactTargets {
  const TackleContactTargets(this.playerAlignment, this.opponentAlignment);
  final Alignment playerAlignment;
  final Alignment opponentAlignment;
}

// Visible near-arm root reference, not a certified anatomical joint.
const tackleDownShoulderSourceY = 355.0;
const tackleDownShoulderGap = 3.0;
const tackleDownPlayerLift = (TackleOpponentVisual.imageHeight / 891) *
        (650 - tackleDownShoulderSourceY) -
    tackleDownShoulderGap;

/// Isolated display candidate: up fixed; down arm3px below B shoulder reference.
TackleContactTargets? tackleContactTargets({
  required Size field,
  required Size player,
  required Size opponent,
  required bool downward,
}) {
  if (!field.width.isFinite ||
      !field.height.isFinite ||
      field.width <= player.width ||
      field.height <= player.height ||
      field.width <= opponent.width ||
      field.height <= opponent.height) {
    return null;
  }
  final basePlayer = Alignment(-.82, downward ? .36 : -.36);
  Offset center(Alignment a, Size child) => Offset(
        field.width / 2 + a.x * (field.width - child.width) / 2,
        field.height / 2 + a.y * (field.height - child.height) / 2,
      );
  Alignment alignment(Offset c, Size child) => Alignment(
        (2 * c.dx - field.width) / (field.width - child.width),
        (2 * c.dy - field.height) / (field.height - child.height),
      );
  final playerCenter = center(basePlayer, player);
  const normalScale = 72 / 1251;
  const normalWidth = 72 * TacklePlayerVisual.attackAspectRatio;
  const normalX = (.5 - TacklePlayerVisual.attackFootAnchorX) * normalWidth;
  final arm = playerCenter +
      Offset(
        normalX - normalWidth / 2 + 607 * normalScale,
        -36 + (downward ? 1251 - 455 : 455) * normalScale,
      );
  const bScale = TackleOpponentVisual.imageHeight / 891;
  final opponentCenter = arm -
      const Offset(178 * bScale, 650 * bScale) +
      const Offset(
        TackleOpponentVisual.imageWidth / 2 - TackleOpponentVisual.imageOffsetX,
        TackleOpponentVisual.imageHeight / 2 -
            TackleOpponentVisual.imageOffsetY,
      );
  return TackleContactTargets(
    alignment(
      playerCenter + Offset(0, downward ? -tackleDownPlayerLift : 0),
      player,
    ),
    alignment(opponentCenter, opponent),
  );
}

/// Invert the fixed v3 contact relation around a future, outcome-independent B.
TackleContactTargets tackleInterceptTargets({
  required Size field,
  required Size player,
  required Size opponent,
  required TackleContactTargets reference,
  required Alignment future,
}) {
  Offset center(Alignment a, Size size) => Offset(
        field.width / 2 + a.x * (field.width - size.width) / 2,
        field.height / 2 + a.y * (field.height - size.height) / 2,
      );
  final delta =
      center(future, opponent) - center(reference.opponentAlignment, opponent);
  final target = center(reference.playerAlignment, player) + delta;
  return TackleContactTargets(
    Alignment(
      (2 * target.dx - field.width) / (field.width - player.width),
      (2 * target.dy - field.height) / (field.height - player.height),
    ),
    future,
  );
}
