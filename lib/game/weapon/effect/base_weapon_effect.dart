import 'package:flame/components.dart';

/// [BaseWeaponEffect] is the abstract foundation for every visual and
/// gameplay effect spawned by a weapon on use.
///
/// Examples include projectiles (bullets, arrows), melee swings, area
/// blasts, or beam effects. Each effect is a [PositionComponent] that
/// lives in the game world and removes itself once finished.
///
/// Subclasses must implement:
/// - [onEffectUpdate] — per-frame logic such as movement or hit detection.
/// - [isFinished] — whether the effect has completed and should be
///   removed.
abstract class BaseWeaponEffect extends PositionComponent {
  /// Creates a [BaseWeaponEffect] travelling in [direction] from
  /// [spawnPosition] dealing [damage] on hit.
  ///
  /// [speed] must be non-negative. [damage] must be non-negative.
  BaseWeaponEffect({
    required Vector2 spawnPosition,
    required Vector2 direction,
    required this.speed,
    required this.damage,
  }) : assert(speed >= 0, 'speed must be non-negative: $speed'),
       assert(damage >= 0, 'damage must be non-negative: $damage') {
    position.setFrom(spawnPosition);
    _direction = direction.normalized();
  }

  /// Movement speed in pixels per second.
  final double speed;

  /// Damage dealt on hit.
  final double damage;

  late final Vector2 _direction;

  /// The normalised travel direction of this effect.
  Vector2 get direction => _direction;

  /// Whether the effect has completed its lifecycle and should be
  /// removed from the component tree.
  bool get isFinished;

  /// Per-frame logic specific to the effect subclass.
  ///
  /// Called every frame by [update] before the automatic removal check.
  /// Use this to move the effect, detect collisions, apply damage, etc.
  void onEffectUpdate(double dt);

  //#region Lifecycle

  @override
  void update(double dt) {
    super.update(dt);
    onEffectUpdate(dt);

    if (isFinished) {
      removeFromParent();
    }
  }

  //#endregion
}
