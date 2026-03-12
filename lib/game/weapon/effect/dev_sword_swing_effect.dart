import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:nexus_survivor/game/weapon/effect/base_weapon_effect.dart';

/// [DevSwordSwingEffect] is a melee arc effect spawned by [DevSwordWeapon].
///
/// The effect stays at the spawn position and rotates through a 120°
/// arc over [swingDuration] seconds, dealing damage to every enemy it
/// overlaps (piercing). It renders as a semi-transparent wedge drawn
/// with [PictureRecorder].
class DevSwordSwingEffect extends BaseWeaponEffect {
  /// Creates a [DevSwordSwingEffect] centred at [spawnPosition] and
  /// swinging from [startAngle].
  ///
  /// [swingDuration] must be positive.
  DevSwordSwingEffect({
    required super.spawnPosition,
    required double startAngle,
    super.damage = 15,
    this.swingDuration = 0.25,
    this.swingArc = 2 * pi / 3,
    this.radius = 48,
  }) : assert(
         swingDuration > 0,
         'swingDuration must be positive: $swingDuration',
       ),
       _startAngle = startAngle - (2 * pi / 3) / 2,
       super(
         direction: Vector2(cos(startAngle), sin(startAngle)),
         speed: 0,
         piercing: true,
       );

  /// Total time in seconds the swing lasts.
  final double swingDuration;

  /// Total arc in radians the swing covers.
  final double swingArc;

  /// Reach of the swing in pixels.
  final double radius;

  final double _startAngle;
  double _elapsed = 0;

  @override
  bool get isFinished => _elapsed >= swingDuration;

  //#region Lifecycle

  @override
  Future<void> onLoad() async {
    final sprite = await _createSwingSprite();
    final spriteComponent = SpriteComponent(
      sprite: sprite,
      size: Vector2.all(radius * 2),
    );
    await add(spriteComponent);

    size = Vector2.all(radius * 2);
    anchor = Anchor.center;

    await super.onLoad();
  }

  //#endregion

  //#region BaseWeaponEffect contract

  @override
  void onEffectUpdate(double dt) {
    _elapsed += dt;

    // Rotate the effect through the swing arc over time.
    final progress = (_elapsed / swingDuration).clamp(0.0, 1.0);
    angle = _startAngle + swingArc * progress;
  }

  //#endregion

  //#region Private helpers

  /// Creates a wedge-shaped sprite for the swing arc.
  Future<Sprite> _createSwingSprite() async {
    final side = (radius * 2).toInt();
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);

    final paint = Paint()..color = const Color(0x99FF5722);
    final center = Offset(radius, radius);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -swingArc / 2,
      swingArc,
      true,
      paint,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(side, side);
    picture.dispose();
    return Sprite(image);
  }

  //#endregion
}
