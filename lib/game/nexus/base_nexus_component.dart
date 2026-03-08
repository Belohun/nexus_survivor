import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:nexus_survivor/game/nexus/nexus_stats.dart';
import 'package:nexus_survivor/game/nexus_survivor.dart';

/// [BaseNexusComponent] is the abstract foundation for the nexus building
/// that the player must protect.
///
/// When the nexus is destroyed (HP reaches zero) the game is over.
/// Subclasses **must** implement:
/// - [baseStats] — the initial [NexusStats] for this nexus.
/// - [onDestroyed] — handle the destruction event.
abstract class BaseNexusComponent extends PositionComponent
    with HasGameReference<NexusSurvivor> {
  //#region Abstract contract

  /// Returns the starting [NexusStats] for this nexus.
  ///
  /// A mutable copy is stored in [stats] during [onLoad].
  NexusStats get baseStats;

  /// Called when the nexus HP drops to zero.
  ///
  /// Subclasses should trigger game-over logic here.
  void onDestroyed();

  //#endregion

  //#region Private fields

  bool _destroyed = false;

  //#endregion

  //#region Public state

  /// Live (mutable) stats — initialised from [baseStats] in [onLoad].
  late NexusStats stats;

  /// Whether the nexus has been destroyed.
  bool get isDestroyed => _destroyed;

  //#endregion

  //#region Lifecycle

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    stats = baseStats.copyWith();
    await add(RectangleHitbox());
  }

  //#endregion

  //#region Damage

  /// Deals [amount] raw damage to the nexus.
  ///
  /// Damage is reduced by the nexus [NexusStats.defense] before being
  /// applied. When HP reaches zero [onDestroyed] is called exactly
  /// once.
  void takeDamage(double amount) {
    assert(amount >= 0, 'Damage amount must be >= 0: $amount');

    if (_destroyed) return;

    final effectiveDamage = (amount - stats.defense).clamp(0.0, amount);
    stats.currentHp = (stats.currentHp - effectiveDamage).clamp(
      0.0,
      stats.maxHp,
    );

    if (stats.currentHp <= 0) {
      _destroyed = true;
      onDestroyed();
    }
  }

  /// Restores [amount] HP to the nexus, clamped to [NexusStats.maxHp].
  ///
  /// Has no effect on a destroyed nexus.
  void heal(double amount) {
    assert(amount >= 0, 'Heal amount must be >= 0: $amount');

    if (_destroyed) return;

    stats.currentHp = (stats.currentHp + amount).clamp(0.0, stats.maxHp);
  }

  //#endregion
}
