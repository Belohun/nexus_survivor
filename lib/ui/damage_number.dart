import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

/// [DamageNumber] is a floating text that shows the damage dealt to an
/// enemy.
///
/// It spawns at the given [worldPosition], drifts upward with a slight
/// random horizontal offset, fades out, and removes itself after
/// [lifetime] seconds.
class DamageNumber extends PositionComponent {
  /// Creates a [DamageNumber] displaying [value] at [worldPosition].
  DamageNumber({
    required this.value,
    required Vector2 worldPosition,
    this.lifetime = 0.8,
    this.isCrit = false,
  }) {
    position.setFrom(worldPosition);
  }

  /// The damage value to display.
  final double value;

  /// Total lifetime in seconds before automatic removal.
  final double lifetime;

  /// Whether this damage was a critical hit (renders larger and
  /// in a different colour).
  final bool isCrit;

  double _elapsed = 0;
  late final double _driftX;

  static final Random _rng = Random();

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    anchor = Anchor.center;
    // Random horizontal drift between -15 and +15 pixels.
    _driftX = (_rng.nextDouble() - 0.5) * 30;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;

    if (_elapsed >= lifetime) {
      removeFromParent();
      return;
    }

    // Float upward and drift horizontally.
    position.y -= 40 * dt;
    position.x += _driftX * dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final progress = (_elapsed / lifetime).clamp(0.0, 1.0);
    final alpha = ((1.0 - progress) * 255).toInt().clamp(0, 255);

    final fontSize = isCrit ? 20.0 : 14.0;
    final color = isCrit
        ? Color.fromARGB(alpha, 255, 215, 0)
        : Color.fromARGB(alpha, 255, 255, 255);

    final paragraphBuilder =
        ParagraphBuilder(
            ParagraphStyle(textAlign: TextAlign.center, fontSize: fontSize),
          )
          ..pushStyle(
            TextStyle(
              color: color,
              fontWeight: isCrit ? FontWeight.bold : FontWeight.normal,
            ),
          )
          ..addText(value.toInt().toString());

    final paragraph = paragraphBuilder.build()
      ..layout(const ParagraphConstraints(width: 60));

    canvas.drawParagraph(paragraph, const Offset(-30, -10));
  }
}
