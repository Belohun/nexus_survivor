import 'dart:ui';

import 'package:flame/components.dart';
import 'package:nexus_survivor/game/weapon/effect/base_weapon_effect.dart';

/// [DevBullet] is a concrete [BaseWeaponEffect] used during development.
///
/// It renders as a small yellow circle that travels in a straight line
/// at a fixed speed and removes itself after exceeding [maxDistance].
/// No sprite assets are required.
class DevBullet extends BaseWeaponEffect {
  /// Creates a [DevBullet] fired from [spawnPosition] in [direction].
  ///
  /// [maxDistance] must be positive.
  DevBullet({
    required super.spawnPosition,
    required super.direction,
    super.speed = 400,
    super.damage = 10,
    this.maxDistance = 300,
  }) : assert(maxDistance > 0, 'maxDistance must be positive: $maxDistance');

  /// Maximum distance in pixels the bullet travels before removal.
  final double maxDistance;

  double _distanceTravelled = 0;

  @override
  bool get isFinished => _distanceTravelled >= maxDistance;

  //#region Lifecycle

  @override
  Future<void> onLoad() async {
    final sprite = await _createPlaceholderSprite();
    final spriteComponent = SpriteComponent(
      sprite: sprite,
      size: Vector2.all(8),
    );
    await add(spriteComponent);

    size = Vector2.all(8);
    anchor = Anchor.center;

    await super.onLoad();
  }

  //#endregion

  //#region BaseWeaponEffect contract

  @override
  void onEffectUpdate(double dt) {
    final displacement = direction * speed * dt;
    position.add(displacement);
    _distanceTravelled += displacement.length;
  }

  //#endregion

  //#region Private helpers

  /// Creates an 8×8 yellow circle sprite for visual debugging.
  Future<Sprite> _createPlaceholderSprite() async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawCircle(
      const Offset(4, 4),
      4,
      Paint()..color = const Color(0xFFFFEB3B),
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(8, 8);
    picture.dispose();
    return Sprite(image);
  }

  //#endregion
}
