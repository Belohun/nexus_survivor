import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:nexus_survivor/game/nexus_survivor.dart';
import 'package:nexus_survivor/game/ui/pause/pause_overlay.dart';

/// [PauseButton] is a HUD component that pauses the game when tapped.
///
/// Add this to `camera.viewport` so it renders as a fixed overlay in
/// the top-right corner of the screen.
class PauseButton extends PositionComponent
    with TapCallbacks, HasGameReference<NexusSurvivor> {
  /// Creates a [PauseButton].
  PauseButton();

  static const double _buttonSize = 44;
  static const double _margin = 16;
  static const double _iconBarWidth = 16;
  static const double _iconBarHeight = 3;
  static const double _iconBarGap = 5;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2.all(_buttonSize);
    anchor = Anchor.topRight;
    // Positioned in the top-right; x is updated in onGameResize.
    position = Vector2(game.size.x - _margin, _margin);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    position = Vector2(size.x - _margin, _margin);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw circular background.
    final center = Offset(size.x / 2, size.y / 2);
    canvas.drawCircle(
      center,
      _buttonSize / 2,
      Paint()..color = const Color(0xAA16213E),
    );

    // Draw two vertical pause bars.
    final barPaint = Paint()..color = const Color(0xFFE0E0FF);
    final barX = size.x / 2 - _iconBarGap / 2 - _iconBarWidth / 2;
    final barY = (size.y - 14) / 2;

    // Left bar.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barX, barY, _iconBarHeight, 14),
        const Radius.circular(1),
      ),
      barPaint,
    );

    // Right bar.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          barX + _iconBarGap + _iconBarHeight,
          barY,
          _iconBarHeight,
          14,
        ),
        const Radius.circular(1),
      ),
      barPaint,
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    game.overlays.add(pauseOverlayKey);
    game.pauseEngine();
  }
}
