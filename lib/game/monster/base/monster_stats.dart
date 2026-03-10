/// [MonsterStats] holds the immutable base configuration for a monster type.
///
/// Unlike [CharacterStats] which covers a full player character,
/// [MonsterStats] focuses on enemy-specific properties such as aggro
/// range, attack-on-contact damage, and XP reward.
class MonsterStats {
  /// Creates a [MonsterStats] instance.
  ///
  /// [currentHp] defaults to [maxHp] when omitted.
  MonsterStats({
    required this.maxHp,
    double? currentHp,
    required this.speed,
    required this.damage,
    this.defense = 0,
    this.attackCooldown = 1.0,
    this.aggroRange = 150,
    this.deaggroRange = 300,
    this.knockbackForce = 100,
    this.xpReward = 10,
  }) : assert(maxHp > 0, 'maxHp must be > 0: $maxHp'),
       assert(speed >= 0, 'speed must be >= 0: $speed'),
       assert(damage >= 0, 'damage must be >= 0: $damage'),
       assert(defense >= 0, 'defense must be >= 0: $defense'),
       assert(
         attackCooldown > 0,
         'attackCooldown must be > 0: $attackCooldown',
       ),
       assert(aggroRange > 0, 'aggroRange must be > 0: $aggroRange'),
       assert(deaggroRange > 0, 'deaggroRange must be > 0: $deaggroRange'),
       assert(
         deaggroRange >= aggroRange,
         'deaggroRange must be >= aggroRange: $deaggroRange < $aggroRange',
       ),
       assert(
         knockbackForce >= 0,
         'knockbackForce must be >= 0: $knockbackForce',
       ),
       assert(xpReward >= 0, 'xpReward must be >= 0: $xpReward'),
       currentHp = currentHp ?? maxHp;

  /// Maximum hit points.
  double maxHp;

  /// Current hit points.
  double currentHp;

  /// Movement speed in pixels per second.
  double speed;

  /// Base damage dealt per attack.
  double damage;

  /// Flat damage reduction.
  double defense;

  /// Minimum seconds between two consecutive attacks.
  double attackCooldown;

  /// Distance at which the monster switches target to the player.
  double aggroRange;

  /// Distance at which the monster loses interest in the player and
  /// returns to targeting the nexus.
  double deaggroRange;

  /// Force applied when the monster is knocked back.
  double knockbackForce;

  /// XP awarded to the player on kill.
  int xpReward;

  /// Returns `true` when [currentHp] is greater than zero.
  bool get isAlive => currentHp > 0;

  /// Returns the current HP as a fraction of [maxHp] (0.0 – 1.0).
  double get hpFraction => (currentHp / maxHp).clamp(0.0, 1.0);

  /// Returns a deep copy, optionally overriding individual fields.
  MonsterStats copyWith({
    double? maxHp,
    double? currentHp,
    double? speed,
    double? damage,
    double? defense,
    double? attackCooldown,
    double? aggroRange,
    double? deaggroRange,
    double? knockbackForce,
    int? xpReward,
  }) {
    return MonsterStats(
      maxHp: maxHp ?? this.maxHp,
      currentHp: currentHp ?? this.currentHp,
      speed: speed ?? this.speed,
      damage: damage ?? this.damage,
      defense: defense ?? this.defense,
      attackCooldown: attackCooldown ?? this.attackCooldown,
      aggroRange: aggroRange ?? this.aggroRange,
      deaggroRange: deaggroRange ?? this.deaggroRange,
      knockbackForce: knockbackForce ?? this.knockbackForce,
      xpReward: xpReward ?? this.xpReward,
    );
  }
}
