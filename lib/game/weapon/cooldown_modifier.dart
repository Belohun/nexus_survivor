/// [CooldownModifier] represents a named multiplicative modifier applied
/// to a weapon's base cooldown.
///
/// Augments, buffs, and debuffs create instances of this class and
/// register them with a [BaseWeapon] via [BaseWeapon.addCooldownModifier].
/// A [multiplier] of `0.8` reduces cooldown by 20 %; a value of `1.5`
/// increases it by 50 %.
class CooldownModifier {
  /// Creates a [CooldownModifier] with a unique [id] and a
  /// [multiplier].
  ///
  /// [multiplier] must be positive.
  const CooldownModifier({required this.id, required this.multiplier})
    : assert(multiplier > 0, 'multiplier must be positive: $multiplier');

  /// Unique identifier used to add or remove this modifier.
  final String id;

  /// Multiplicative factor applied to the weapon's base cooldown.
  ///
  /// Values below 1.0 speed up the attack rate; values above 1.0
  /// slow it down.
  final double multiplier;
}
