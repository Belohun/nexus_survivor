import 'dart:math';

import 'package:flame/components.dart';
import 'package:nexus_survivor/game/weapon/cooldown_modifier.dart';
import 'package:nexus_survivor/game/weapon/effect/base_weapon_effect.dart';

/// [BaseWeapon] is the abstract foundation for every weapon that can be
/// attached to a character.
///
/// The weapon orbits its parent component at a fixed [orbitRadius],
/// rotating to face the current [aimAngle]. Subclasses must override
/// [onFire] to implement concrete attack behaviour (spawning
/// projectiles, melee hit detection, etc.).
///
/// Each weapon owns its own **cooldown**. The [baseCooldown] can be
/// modified at runtime through [CooldownModifier]s — making it easy
/// for augments, buffs, and debuffs to speed up or slow down the
/// attack rate without touching the base value.
///
/// Add a [BaseWeapon] as a child of a character component. It will
/// reposition and rotate itself each frame based on the aim direction.
abstract class BaseWeapon extends PositionComponent {
  /// Creates a [BaseWeapon] with the given [orbitRadius] and
  /// [baseCooldown].
  ///
  /// [orbitRadius] and [baseCooldown] must be non-negative.
  BaseWeapon({this.orbitRadius = 24, this.baseCooldown = 0.3})
    : assert(
        orbitRadius >= 0,
        'orbitRadius must be non-negative: $orbitRadius',
      ),
      assert(
        baseCooldown >= 0,
        'baseCooldown must be non-negative: $baseCooldown',
      );

  /// Distance from the parent's center at which the weapon orbits.
  final double orbitRadius;

  /// Base cooldown duration in seconds between consecutive shots.
  ///
  /// The actual cooldown used at runtime is [effectiveCooldown], which
  /// accounts for any active [CooldownModifier]s.
  final double baseCooldown;

  double _cooldownTimer = 0;

  final List<CooldownModifier> _cooldownModifiers = [];

  /// Current aim angle in radians (0 = right, π/2 = down in screen
  /// coordinates).
  double aimAngle = 0;

  /// Whether the weapon is currently being aimed (action joystick
  /// dragged or arrow keys held).
  bool isAiming = false;

  //#region Cooldown

  /// Returns the effective cooldown after applying all registered
  /// [CooldownModifier]s.
  ///
  /// Each modifier's [CooldownModifier.multiplier] is applied
  /// multiplicatively to [baseCooldown]. The result is clamped to
  /// a minimum of zero.
  double get effectiveCooldown {
    var cd = baseCooldown;
    for (final mod in _cooldownModifiers) {
      cd *= mod.multiplier;
    }
    return cd.clamp(0, double.infinity);
  }

  /// Returns `true` when the cooldown has expired and the weapon can
  /// fire again.
  bool get canFire => _cooldownTimer <= 0;

  /// Registers a [CooldownModifier] that affects [effectiveCooldown].
  ///
  /// If a modifier with the same [CooldownModifier.id] already exists
  /// it is replaced.
  void addCooldownModifier(CooldownModifier modifier) {
    _cooldownModifiers.removeWhere((m) => m.id == modifier.id);
    _cooldownModifiers.add(modifier);
  }

  /// Removes a previously registered [CooldownModifier] by [id].
  ///
  /// Does nothing when no modifier with that [id] exists.
  void removeCooldownModifier(String id) {
    _cooldownModifiers.removeWhere((m) => m.id == id);
  }

  /// Returns an unmodifiable view of the active cooldown modifiers.
  List<CooldownModifier> get cooldownModifiers =>
      List.unmodifiable(_cooldownModifiers);

  //#endregion

  //#region Public API

  /// Sets the aim direction from a normalised [direction] vector.
  ///
  /// The vector is converted to radians via [atan2]. A zero-length
  /// vector is ignored so the last valid aim is preserved.
  void setAimDirection(Vector2 direction) {
    if (direction.isZero()) return;
    aimAngle = atan2(direction.y, direction.x);
  }

  /// Attempts to fire the weapon.
  ///
  /// Returns `true` when the weapon was fired (i.e. cooldown had
  /// expired). On success the cooldown timer is reset to
  /// [effectiveCooldown] and the abstract [onFire] is invoked.
  bool tryFire() {
    if (_cooldownTimer > 0) return false;
    _cooldownTimer = effectiveCooldown;
    onFire();
    return true;
  }

  /// Called when the weapon actually fires.
  ///
  /// Subclasses implement this to perform the actual attack (spawning
  /// projectiles, melee hit detection, etc.). Prefer calling
  /// [tryFire] instead of invoking this directly so that cooldown is
  /// respected.
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

    // Tick the cooldown timer.
    if (_cooldownTimer > 0) {
      _cooldownTimer = (_cooldownTimer - dt).clamp(0, double.infinity);
    }

    // Position the weapon on the orbit around the parent's anchor.
    final parentComp = parent;
    final parentSize = parentComp is PositionComponent
        ? parentComp.size
        : Vector2.zero();
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
