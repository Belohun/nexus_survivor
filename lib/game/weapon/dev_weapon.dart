import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:nexus_survivor/game/weapon/base_weapon.dart';
import 'package:nexus_survivor/game/weapon/effect/dev_bullet.dart';

/// [DevWeapon] is a concrete [BaseWeapon] used during development.
///
/// It renders as a small coloured rectangle (no sprite assets required)
/// and fires a [DevBullet] in the current aim direction when [onFire]
/// is called. Attach it to a [DevCharacter] to visualise the aim
/// direction on screen.
class DevWeapon extends BaseWeapon {
  /// Creates a [DevWeapon] with an optional custom [orbitRadius].
  DevWeapon({super.orbitRadius = 24});

  //#region BaseWeapon contract

  @override
  void onFire() {
    final direction = Vector2(cos(aimAngle), sin(aimAngle));
    final bullet = DevBullet(
      spawnPosition: worldPosition,
      direction: direction,
    );
    spawnEffect(bullet);
  }

  //#endregion

  //#region Lifecycle

  @override
  Future<void> onLoad() async {
    final sprite = await _createPlaceholderSprite();
    final spriteComponent = SpriteComponent(
      sprite: sprite,
      size: Vector2(24, 8),
    );
    await add(spriteComponent);

    size = Vector2(24, 8);
    anchor = Anchor.center;

    await super.onLoad();
  }

  //#endregion

  //#region Private helpers

  /// Creates a 24×8 orange rectangle sprite for visual debugging.
  Future<Sprite> _createPlaceholderSprite() async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 24, 8),
      Paint()..color = const Color(0xFFFF9800),
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(24, 8);
    picture.dispose();
    return Sprite(image);
  }

  //#endregion
}
