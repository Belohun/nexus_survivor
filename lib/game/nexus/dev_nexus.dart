import 'dart:ui';

import 'package:flame/components.dart';
import 'package:nexus_survivor/game/nexus/base_nexus_component.dart';
import 'package:nexus_survivor/game/nexus/nexus_stats.dart';

/// [DevNexus] is a concrete [BaseNexusComponent] used during development.
///
/// It renders as a simple coloured diamond (no sprite assets required)
/// with an HP bar above it. Spawns at the centre of the world by
/// default.
class DevNexus extends BaseNexusComponent {
  /// Creates a [DevNexus] at the given [initialPosition].
  ///
  /// Uses [devStats] when provided; otherwise falls back to sensible
  /// defaults.
  DevNexus({Vector2? initialPosition, NexusStats? devStats})
    : _devStats = devStats ?? NexusStats(maxHp: 500, defense: 5),
      _initialPosition = initialPosition ?? Vector2.zero();

  final NexusStats _devStats;
  final Vector2 _initialPosition;

  //#region BaseNexusComponent contract

  @override
  NexusStats get baseStats => _devStats;

  @override
  void onDestroyed() {
    // In a real implementation this would trigger game-over.
    // For now just log to the console.
  }

  //#endregion

  //#region Lifecycle

  @override
  Future<void> onLoad() async {
    size = Vector2(64, 64);
    // Centre the component on the given position.
    position = _initialPosition.clone() - size / 2;
    anchor = Anchor.topLeft;

    await super.onLoad();
  }

  //#endregion

  //#region Rendering

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final w = size.x;
    final h = size.y;

    // Draw a diamond shape for the nexus body.
    final path = Path()
      ..moveTo(w / 2, 0)
      ..lineTo(w, h / 2)
      ..lineTo(w / 2, h)
      ..lineTo(0, h / 2)
      ..close();

    canvas.drawPath(path, _bodyPaint);
    canvas.drawPath(path, _outlinePaint);

    // Draw an inner diamond highlight.
    final inset = 8.0;
    final innerPath = Path()
      ..moveTo(w / 2, inset)
      ..lineTo(w - inset, h / 2)
      ..lineTo(w / 2, h - inset)
      ..lineTo(inset, h / 2)
      ..close();
    canvas.drawPath(innerPath, _innerPaint);

    // Draw HP bar above the nexus.
    _renderHpBar(canvas, w);
  }

  void _renderHpBar(Canvas canvas, double width) {
    final barWidth = width;
    final barHeight = 6.0;
    final barY = -12.0;

    // Background (dark).
    canvas.drawRect(
      Rect.fromLTWH(0, barY, barWidth, barHeight),
      _hpBarBackgroundPaint,
    );

    // Foreground (green → red based on HP fraction).
    final fraction = stats.hpFraction;
    final filledWidth = barWidth * fraction;
    final color = Color.lerp(
      const Color(0xFFFF0000),
      const Color(0xFF00FF00),
      fraction,
    )!;

    canvas.drawRect(
      Rect.fromLTWH(0, barY, filledWidth, barHeight),
      Paint()..color = color,
    );
  }

  //#endregion

  //#region Paint objects

  static final Paint _bodyPaint = Paint()..color = const Color(0xFF7B1FA2);

  static final Paint _outlinePaint = Paint()
    ..color = const Color(0xFFCE93D8)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  static final Paint _innerPaint = Paint()..color = const Color(0xFFAB47BC);

  static final Paint _hpBarBackgroundPaint = Paint()
    ..color = const Color(0xFF333333);

  //#endregion
}
