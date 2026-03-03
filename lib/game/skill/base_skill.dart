import 'package:flame/components.dart';
import 'package:nexus_survivor/game/character/base/base_character_component.dart';

/// [BaseSkill] is the abstract foundation for every activatable skill in
/// the game.
///
/// Each skill has a [cooldown] timer, a [name] for UI display, and an
/// [execute] callback that fires when the player activates it. Subclasses
/// must override [execute] to implement the concrete behaviour (e.g.
/// spawning a projectile, applying a buff, or dealing AoE damage).
abstract class BaseSkill {
  /// Creates a [BaseSkill] with the given [name] and [cooldown] duration.
  ///
  /// [cooldown] must be non-negative.
  BaseSkill({
    required this.name,
    required this.cooldown,
    this.isInterruptive = false,
  }) : assert(cooldown >= 0, 'Cooldown must be non-negative: $cooldown');

  /// Human-readable skill name (for UI / tooltips).
  final String name;

  /// Base cooldown duration in seconds between activations.
  final double cooldown;

  /// Whether activating this skill locks the character's state (e.g.
  /// channelled abilities). Non-interruptive skills fire independently
  /// of the character's current action.
  final bool isInterruptive;

  double _cooldownTimer = 0;

  /// Returns `true` when the skill is off cooldown and ready to fire.
  bool get isReady => _cooldownTimer <= 0;

  /// Returns the remaining cooldown in seconds.
  double get cooldownRemaining => _cooldownTimer;

  /// Returns a normalised cooldown progress from 0.0 (ready) to 1.0
  /// (just activated).
  ///
  /// Useful for UI cooldown indicators.
  double get cooldownProgress =>
      cooldown > 0 ? (_cooldownTimer / cooldown).clamp(0.0, 1.0) : 0.0;

  /// Attempts to activate the skill toward [aimDirection] on behalf of
  /// [owner].
  ///
  /// Returns `true` when the skill was successfully activated. The
  /// cooldown timer resets automatically on success.
  bool activate(BaseCharacterComponent owner, Vector2 aimDirection) {
    if (!isReady) return false;
    if (owner.isLocked) return false;

    _cooldownTimer = cooldown;
    execute(owner, aimDirection);
    return true;
  }

  /// Implements the concrete skill behaviour.
  ///
  /// Called by [activate] after cooldown and lock checks have passed.
  /// [owner] is the character using the skill; [aimDirection] is the
  /// world-space direction the player is aiming.
  void execute(BaseCharacterComponent owner, Vector2 aimDirection);

  /// Ticks the internal cooldown timer by [dt] seconds.
  void update(double dt) {
    if (_cooldownTimer > 0) {
      _cooldownTimer = (_cooldownTimer - dt).clamp(0.0, double.infinity);
    }
  }
}
