import 'dart:ui';

import 'package:flame/components.dart';
import 'package:nexus_survivor/game/weapon/base_weapon.dart';
import 'package:nexus_survivor/game/weapon/effect/dev_sword_swing_effect.dart';

/// [DevSwordWeapon] is a melee [BaseWeapon] used during development.
///
/// It renders as a silver/grey rectangle placeholder and spawns a
/// [DevSwordSwingEffect] arc when [onFire] is called. Attach it to a
/// melee-oriented character to visualise sword swings on screen.
class DevSwordWeapon extends BaseWeapon {
  /// Creates a [DevSwordWeapon] with optional custom [orbitRadius] and [baseCooldown].
  DevSwordWeapon({super.orbitRadius = 20, super.baseCooldown = 1.0});

  //#region BaseWeapon contract

  @override
  void onFire() {
    final effect = DevSwordSwingEffect(
      spawnPosition: worldPosition,
      startAngle: aimAngle,
    );
    spawnEffect(effect);
  }

  //#endregion

  //#region Lifecycle

  @override
  Future<void> onLoad() async {
    final sprite = await _createPlaceholderSprite();
    final spriteComponent = SpriteComponent(
      sprite: sprite,
      size: Vector2(28, 6),
    );
    await add(spriteComponent);

    size = Vector2(28, 6);
    anchor = Anchor.center;

    await super.onLoad();
  }

  //#endregion

  //#region Private helpers

  /// Creates a 28×6 silver rectangle sprite for visual debugging.
  Future<Sprite> _createPlaceholderSprite() async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 28, 6),
      Paint()..color = const Color(0xFFB0BEC5),
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(28, 6);
    picture.dispose();
    return Sprite(image);
  }

  //#endregion
}
