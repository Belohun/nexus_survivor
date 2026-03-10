import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:nexus_survivor/game/monster/base/base_monster_component.dart';

/// [BaseWeaponEffect] is the abstract foundation for every visual and
/// gameplay effect spawned by a weapon on use.
///
/// Examples include projectiles (bullets, arrows), melee swings, area
/// blasts, or beam effects. Each effect is a [PositionComponent] that
/// lives in the game world and removes itself once finished.
///
/// Weapon effects carry a [RectangleHitbox] so the engine's collision
/// system can detect overlaps with [BaseMonsterComponent] hit-boxes.
/// On first contact the effect deals [damage] and marks itself as hit.
///
/// Subclasses must implement:
/// - [onEffectUpdate] — per-frame logic such as movement or hit detection.
/// - [isFinished] — whether the effect has completed and should be
///   removed.
abstract class BaseWeaponEffect extends PositionComponent
    with CollisionCallbacks {
  /// Creates a [BaseWeaponEffect] travelling in [direction] from
  /// [spawnPosition] dealing [damage] on hit.
  ///
  /// [speed] must be non-negative. [damage] must be non-negative.
  /// When [piercing] is `true` the effect does not self-destruct on
  /// the first hit and can damage multiple enemies.
  BaseWeaponEffect({
    required Vector2 spawnPosition,
    required Vector2 direction,
    required this.speed,
    required this.damage,
    this.piercing = false,
  }) : assert(speed >= 0, 'speed must be non-negative: $speed'),
       assert(damage >= 0, 'damage must be non-negative: $damage') {
    position.setFrom(spawnPosition);
    _direction = direction.normalized();
  }

  /// Movement speed in pixels per second.
  final double speed;

  /// Damage dealt on hit.
  final double damage;

  /// Whether this effect can hit multiple enemies without being
  /// consumed.
  final bool piercing;

  late final Vector2 _direction;

  /// The normalised travel direction of this effect.
  Vector2 get direction => _direction;

  /// Whether the effect has been consumed by hitting an enemy.
  bool get hasHit => _hasHit;
  bool _hasHit = false;

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
  Future<void> onLoad() async {
    await super.onLoad();
    await add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    onEffectUpdate(dt);

    if (isFinished) {
      removeFromParent();
    }
  }

  //#endregion

  //#region Collision with monsters

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is BaseMonsterComponent && !other.isDead) {
      final knockbackDir = (other.position - position).normalized();
      other.receiveDamage(damage, knockbackDirection: knockbackDir);

      if (!piercing) {
        _hasHit = true;
        removeFromParent();
      }
    }
  }

  //#endregion
}
