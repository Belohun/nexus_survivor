import 'dart:math';

import 'package:flame/components.dart';
import 'package:nexus_survivor/game/weapon/effect/base_weapon_effect.dart';

/// [BaseWeapon] is the abstract foundation for every weapon that can be
/// attached to a character.
///
/// The weapon orbits its parent component at a fixed [orbitRadius],
/// rotating to face the current [aimAngle]. Subclasses must override
/// [onFire] to implement concrete attack behaviour (spawning
/// projectiles, melee hit detection, etc.).
///
/// Add a [BaseWeapon] as a child of a character component. It will
/// reposition and rotate itself each frame based on the aim direction.
abstract class BaseWeapon extends PositionComponent {
  /// Creates a [BaseWeapon] with the given [orbitRadius].
  ///
  /// [orbitRadius] must be non-negative.
  BaseWeapon({this.orbitRadius = 24})
    : assert(
        orbitRadius >= 0,
        'orbitRadius must be non-negative: $orbitRadius',
      );

  /// Distance from the parent's center at which the weapon orbits.
  final double orbitRadius;

  /// Current aim angle in radians (0 = right, π/2 = down in screen
  /// coordinates).
  double aimAngle = 0;

  /// Whether the weapon is currently being aimed (action joystick
  /// dragged or arrow keys held).
  bool isAiming = false;

  //#region Public API

  /// Sets the aim direction from a normalised [direction] vector.
  ///
  /// The vector is converted to radians via [atan2]. A zero-length
  /// vector is ignored so the last valid aim is preserved.
  void setAimDirection(Vector2 direction) {
    if (direction.isZero()) return;
    aimAngle = atan2(direction.y, direction.x);
  }

  /// Called when the player releases the action joystick or presses
  /// the attack key.
  ///
  /// Subclasses implement this to perform the actual attack.
  void onFire();

  /// Spawns a [BaseWeaponEffect] into the game world.
  ///
  /// The effect is added as a child of the weapon's top-level ancestor
  /// (typically the [World]) so it lives independently of the weapon
  /// and character hierarchy. Does nothing when the weapon is not
  /// mounted.
  void spawnEffect(BaseWeaponEffect effect) {
    final world = findGame()?.world;
    if (world is Component) {
      (world as Component).add(effect);
    }
  }

  /// Returns the world-space position of this weapon's tip.
  ///
  /// Useful for subclasses to determine where to spawn projectiles or
  /// other effects.
  Vector2 get worldPosition {
    return absolutePosition;
  }

  //#endregion

  //#region Lifecycle

  @override
  void update(double dt) {
    super.update(dt);

    // Position the weapon on the orbit around the parent's anchor.
    final parentSize = (parent as PositionComponent?)?.size ?? Vector2.zero();
    final center = parentSize / 2;

    position.x = center.x + cos(aimAngle) * orbitRadius;
    position.y = center.y + sin(aimAngle) * orbitRadius;

    // Rotate the sprite to face the aim direction.
    angle = aimAngle;

    // Flip vertically when aiming left so the weapon doesn't appear
    // upside-down.
    final aimingLeft = aimAngle.abs() > pi / 2;
    if (aimingLeft && !isFlippedVertically) {
      flipVertically();
    } else if (!aimingLeft && isFlippedVertically) {
      flipVertically();
    }
  }

  //#endregion
}
