/// [CharacterStats] holds the mutable statistics for a character.
///
/// Used by [BaseCharacterComponent] to drive combat, movement, and
/// progression. Call [copyWith] to create buff/debuff overlays.
class CharacterStats {
  /// Creates a new [CharacterStats] instance.
  ///
  /// [currentHp] defaults to [maxHp] when omitted.
  CharacterStats({
    required this.maxHp,
    double? currentHp,
    required this.speed,
    required this.damage,
    this.defense = 0,
    this.invincibilityDuration = 0.5,
    this.dashSpeedMultiplier = 2.5,
    this.dashDuration = 0.2,
    this.dashCooldown = 1.0,
    this.knockbackForce = 200,
    this.level = 1,
    this.currentXp = 0,
    this.xpToNextLevel = 100,
    this.critChance = 0.05,
    this.critMultiplier = 2.0,
  }) : currentHp = currentHp ?? maxHp;

  /// Maximum hit points.
  double maxHp;

  /// Current hit points.
  double currentHp;

  /// Movement speed in pixels per second.
  double speed;

  /// Base attack damage dealt per hit.
  double damage;

  /// Damage reduction (flat).
  ///
  /// Incoming damage is reduced by this value before being applied.
  double defense;

  /// Duration (seconds) the character is invincible after taking a hit.
  double invincibilityDuration;

  /// Speed multiplier applied during a dash.
  double dashSpeedMultiplier;

  /// Duration (seconds) of a single dash.
  double dashDuration;

  /// Cooldown (seconds) between dashes.
  double dashCooldown;

  /// Force applied when the character is knocked back.
  double knockbackForce;

  /// Current character level (starts at 1).
  int level;

  /// Current experience points accumulated.
  int currentXp;

  /// XP required to reach the next level.
  int xpToNextLevel;

  /// Critical-hit chance in the range 0.0 – 1.0.
  double critChance;

  /// Critical-hit damage multiplier (e.g. 2.0 = double damage).
  double critMultiplier;

  /// Returns `true` when [currentHp] is greater than zero.
  bool get isAlive => currentHp > 0;

  /// Returns a deep copy, optionally overriding individual fields.
  CharacterStats copyWith({
    double? maxHp,
    double? currentHp,
    double? speed,
    double? damage,
    double? defense,
    double? invincibilityDuration,
    double? dashSpeedMultiplier,
    double? dashDuration,
    double? dashCooldown,
    double? knockbackForce,
    int? level,
    int? currentXp,
    int? xpToNextLevel,
    double? critChance,
    double? critMultiplier,
  }) {
    return CharacterStats(
      maxHp: maxHp ?? this.maxHp,
      currentHp: currentHp ?? this.currentHp,
      speed: speed ?? this.speed,
      damage: damage ?? this.damage,
      defense: defense ?? this.defense,
      invincibilityDuration:
          invincibilityDuration ?? this.invincibilityDuration,
      dashSpeedMultiplier: dashSpeedMultiplier ?? this.dashSpeedMultiplier,
      dashDuration: dashDuration ?? this.dashDuration,
      dashCooldown: dashCooldown ?? this.dashCooldown,
      knockbackForce: knockbackForce ?? this.knockbackForce,
      level: level ?? this.level,
      currentXp: currentXp ?? this.currentXp,
      xpToNextLevel: xpToNextLevel ?? this.xpToNextLevel,
      critChance: critChance ?? this.critChance,
      critMultiplier: critMultiplier ?? this.critMultiplier,
    );
  }
}
