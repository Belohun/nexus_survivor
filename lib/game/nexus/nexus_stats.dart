/// [NexusStats] holds the mutable statistics for the nexus building.
///
/// Used by [BaseNexusComponent] to track health and damage reduction.
class NexusStats {
  /// Creates a [NexusStats] instance.
  ///
  /// [currentHp] defaults to [maxHp] when omitted.
  NexusStats({required this.maxHp, double? currentHp, this.defense = 0})
    : assert(maxHp > 0, 'maxHp must be > 0: $maxHp'),
      assert(defense >= 0, 'defense must be >= 0: $defense'),
      currentHp = currentHp ?? maxHp;

  /// Maximum hit points the nexus can have.
  double maxHp;

  /// Current hit points. When this reaches zero the game is over.
  double currentHp;

  /// Flat damage reduction applied to every incoming hit.
  ///
  /// Incoming damage is reduced by this value before being applied.
  double defense;

  /// Returns `true` when the nexus has been destroyed.
  bool get isDestroyed => currentHp <= 0;

  /// Returns the current HP as a fraction of [maxHp] (0.0 – 1.0).
  double get hpFraction => (currentHp / maxHp).clamp(0.0, 1.0);

  /// Returns a copy with optionally overridden fields.
  NexusStats copyWith({double? maxHp, double? currentHp, double? defense}) {
    return NexusStats(
      maxHp: maxHp ?? this.maxHp,
      currentHp: currentHp ?? this.currentHp,
      defense: defense ?? this.defense,
    );
  }
}
