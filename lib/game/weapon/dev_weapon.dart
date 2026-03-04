import 'dart:ui';

import 'package:flame/components.dart';
import 'package:nexus_survivor/game/weapon/base_weapon.dart';

/// [DevWeapon] is a concrete [BaseWeapon] used during development.
///
/// It renders as a small coloured rectangle (no sprite assets required)
/// and performs no real attack logic — [onFire] is a no-op. Attach it
/// to a [DevCharacter] to visualise the aim direction on screen.
class DevWeapon extends BaseWeapon {
  /// Creates a [DevWeapon] with an optional custom [orbitRadius].
  DevWeapon({super.orbitRadius = 24});

  //#region BaseWeapon contract

  @override
  void onFire() {
    // No-op in the dev implementation.
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
