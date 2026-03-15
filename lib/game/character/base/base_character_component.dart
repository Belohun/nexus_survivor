import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:nexus_survivor/game/character/base/character_state.dart';
import 'package:nexus_survivor/game/character/base/character_stats.dart';
import 'package:nexus_survivor/game/nexus_survivor.dart';
import 'package:nexus_survivor/game/weapon/base_weapon.dart';

/// [BaseCharacterComponent] is the abstract foundation for every character
/// (player **and** enemies) in the game.
///
/// Subclasses **must** implement:
/// - [animations] — a [SpriteAnimation] for every [CharacterState].
/// - [baseStats] — the initial [CharacterStats] for this character.
///
/// The class provides built-in:
/// - 8-directional movement with sprite flipping
/// - Attack with cooldown and critical-hit support
/// - Damage / knockback / invincibility-frame handling
/// - Dashing with i-frames
/// - XP / leveling (with an [onLevelUp] hook)
/// - A simple state machine that guards illegal transitions
abstract class BaseCharacterComponent extends SpriteAnimationComponent
    with HasGameReference<NexusSurvivor>, CollisionCallbacks {
  //#region Abstract contract

  /// Returns a complete map of animations — one entry per [CharacterState].
  ///
  /// Called once during [onLoad]; the result is cached. Subclasses that
  /// omit any state will trigger an assertion failure at load time.
  Map<CharacterState, SpriteAnimation> get animations;

  /// Returns the starting [CharacterStats] for this character.
  ///
  /// A mutable copy is stored in [stats] during [onLoad].
  CharacterStats get baseStats;

  //#endregion

  //#region Private fields

  double _invincibilityTimer = 0;
  double _dashTimer = 0;
  double _dashCooldownTimer = 0;
  double _knockbackTimer = 0;
  double _stunTimer = 0;

  /// How long a knockback effect lasts (seconds).
  static const double _knockbackDuration = 0.15;

  /// Cached animation map populated in [onLoad].
  late final Map<CharacterState, SpriteAnimation> _animations;

  /// Random generator shared across the character (for crits, etc.).
  final Random _rng = Random();

  CharacterState _currentState = CharacterState.idle;

  /// Whether the sprite should be rendered mirrored horizontally.
  ///
  /// Set by [move] when the character faces left. Only affects the
  /// sprite rendering — child components (e.g. weapons) are not
  /// transformed.
  bool _facingLeft = false;

  //#endregion

  //#region Public state

  /// Live (mutable) stats — initialised from [baseStats] in [onLoad].
  late CharacterStats stats;

  /// The current state of this character.
  CharacterState get currentState => _currentState;

  /// The direction the character is currently facing.
  Direction facingDirection = Direction.down;

  /// Whether the character's sprite is rendered facing left.
  ///
  /// Only the sprite rendering is mirrored — child components such as
  /// weapons are **not** affected by this flag.
  bool get isFacingLeft => _facingLeft;

  /// Current velocity in pixels per second.
  ///
  /// Updated by [move], [dash], and [applyKnockback].
  final Vector2 velocity = Vector2.zero();

  /// The world-space direction the character is currently aiming.
  ///
  /// Defaults to facing down. Updated by [PlayerController] or AI
  /// systems. The attached [weapon] reads this to orient itself.
  final Vector2 aimDirection = Vector2(0, 1);

  BaseWeapon? _weapon;

  /// The weapon currently attached to this character, or `null`.
  ///
  /// Setting a new weapon removes the previous one from the component
  /// tree and adds the new one as a child.
  BaseWeapon? get weapon => _weapon;

  set weapon(BaseWeapon? value) {
    if (_weapon != null) {
      _weapon!.removeFromParent();
    }
    _weapon = value;
    if (_weapon != null && isMounted) {
      add(_weapon!);
    }
  }

  //#endregion

  //#region Allowed transitions

  /// Defines which states each state is allowed to transition **to**.
  static const Map<CharacterState, Set<CharacterState>> _allowedTransitions = {
    CharacterState.idle: {
      CharacterState.moving,
      CharacterState.attacking,
      CharacterState.hit,
      CharacterState.dying,
      CharacterState.dashing,
      CharacterState.stunned,
    },
    CharacterState.moving: {
      CharacterState.idle,
      CharacterState.attacking,
      CharacterState.hit,
      CharacterState.dying,
      CharacterState.dashing,
      CharacterState.stunned,
    },
    CharacterState.attacking: {
      CharacterState.idle,
      CharacterState.moving,
      CharacterState.hit,
      CharacterState.dying,
      CharacterState.stunned,
    },
    CharacterState.hit: {
      CharacterState.idle,
      CharacterState.dying,
      CharacterState.stunned,
    },
    CharacterState.dying: {CharacterState.dead},
    CharacterState.dead: {},
    CharacterState.dashing: {
      CharacterState.idle,
      CharacterState.moving,
      CharacterState.dying,
    },
    CharacterState.stunned: {
      CharacterState.idle,
      CharacterState.hit,
      CharacterState.dying,
    },
  };

  //#endregion

  //#region Lifecycle

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    stats = baseStats.copyWith();
    _animations = animations;

    // Validate that every state has an animation.
    final missing = CharacterState.values
        .where((s) => !_animations.containsKey(s))
        .toList();
    assert(missing.isEmpty, '$runtimeType is missing animations for: $missing');

    anchor = Anchor.center;
    _syncAnimation();

    // Add a hitbox so the collision system can detect overlaps.
    await add(RectangleHitbox());

    // Mount the weapon if one was assigned before loading.
    if (_weapon != null) {
      await add(_weapon!);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_currentState == CharacterState.dead) return;

    _tickTimers(dt);
    _applyVelocity(dt);
    _handleAutoStateTransitions();
    _syncAnimation();

    // Keep the weapon oriented toward the current aim direction.
    _weapon?.setAimDirection(aimDirection);
  }

  @override
  void render(Canvas canvas) {
    if (_facingLeft) {
      canvas.save();
      canvas.translate(size.x, 0);
      canvas.scale(-1, 1);
      super.render(canvas);
      canvas.restore();
    } else {
      super.render(canvas);
    }
  }

  //#endregion

  //#region Collision resolution

  /// The position recorded before the last velocity application.
  ///
  /// Used by [onCollision] to revert movement into static obstacles
  /// such as the nexus.
  final Vector2 _previousPosition = Vector2.zero();

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    _blockMovementIntoObstacle(other);
  }

  /// Reverts the character's position to [_previousPosition] on axes
  /// that cause overlap with [obstacle], so the character cannot walk
  /// on top of it.
  void _blockMovementIntoObstacle(PositionComponent obstacle) {
    final obstacleRect = obstacle.toRect();

    // Try keeping the new X but reverting Y.
    final tryRevertY = toRect().shift(
      Offset(0, _previousPosition.y - position.y),
    );
    // Try keeping the new Y but reverting X.
    final tryRevertX = toRect().shift(
      Offset(_previousPosition.x - position.x, 0),
    );

    final overlapsWithRevertedY = obstacleRect.overlaps(tryRevertY);
    final overlapsWithRevertedX = obstacleRect.overlaps(tryRevertX);

    if (!overlapsWithRevertedY) {
      // Reverting Y alone resolves it — allow horizontal sliding.
      position.y = _previousPosition.y;
    } else if (!overlapsWithRevertedX) {
      // Reverting X alone resolves it — allow vertical sliding.
      position.x = _previousPosition.x;
    } else {
      // Both axes contribute — revert fully.
      position.setFrom(_previousPosition);
    }
  }

  //#endregion

  //#region Movement

  /// Moves the character toward [direction] (expected magnitude 0–1).
  ///
  /// Applies [stats.speed] and updates [facingDirection]. While active
  /// the state is set to [CharacterState.moving]. A zero-length
  /// [direction] transitions back to [CharacterState.idle].
  void move(Vector2 direction, double dt) {
    if (isLocked) return;

    if (direction.isZero()) {
      _tryTransition(CharacterState.idle);
      return;
    }

    final normalized = direction.normalized();
    velocity.setFrom(normalized * stats.speed);
    facingDirection = Direction.fromVector(normalized.x, normalized.y);

    // Track facing for sprite-only flipping (does not affect children).
    if (facingDirection.isLeft) {
      _facingLeft = true;
    } else if (facingDirection.isRight) {
      _facingLeft = false;
    }

    _tryTransition(CharacterState.moving);
  }

  //#endregion

  //#region Attack

  /// Triggers a basic attack toward the [target] world position.
  ///
  /// Returns `true` when the attack was initiated (i.e. the weapon's
  /// cooldown was ready and the character is not locked). The cooldown
  /// is managed by the equipped [BaseWeapon]. Override [onAttack] for
  /// projectile spawning, melee hit detection, or other custom
  /// behaviour.
  bool attack(Vector2 target) {
    if (isLocked) return false;
    if (_weapon == null || !_weapon!.canFire) return false;

    _weapon!.tryFire();
    _tryTransition(CharacterState.attacking);
    onAttack(target);
    return true;
  }

  /// Called when an attack is initiated.
  ///
  /// Override to implement projectile spawning, melee hit detection,
  /// etc. The default implementation does nothing.
  void onAttack(Vector2 target) {}

  /// Calculates final outgoing damage, applying critical-hit logic.
  ///
  /// Uses [CharacterStats.critChance] and [CharacterStats.critMultiplier].
  double calculateDamage() {
    final isCrit = _rng.nextDouble() < stats.critChance;
    return isCrit ? stats.damage * stats.critMultiplier : stats.damage;
  }

  //#endregion

  //#region Receive damage

  /// Applies [amount] damage to this character, respecting defense and
  /// invincibility frames.
  ///
  /// Optionally pass [knockbackDirection] to push the character on hit.
  /// Triggers [CharacterState.hit] (or [die] when HP reaches zero).
  void receiveDamage(double amount, {Vector2? knockbackDirection}) {
    if (_currentState == CharacterState.dead ||
        _currentState == CharacterState.dying) {
      return;
    }
    if (_invincibilityTimer > 0) return;

    final effective = (amount - stats.defense).clamp(0.0, double.infinity);
    stats.currentHp -= effective;

    if (stats.currentHp <= 0) {
      stats.currentHp = 0;
      die();
      return;
    }

    _invincibilityTimer = stats.invincibilityDuration;
    _tryTransition(CharacterState.hit);

    if (knockbackDirection != null) {
      applyKnockback(knockbackDirection);
    }

    onDamageReceived(effective);
  }

  /// Called after damage has been applied.
  ///
  /// Override for custom reactions such as screen shake or SFX. The
  /// default implementation does nothing.
  void onDamageReceived(double effectiveDamage) {}

  //#endregion

  //#region Knockback

  /// Pushes the character in [direction] using [CharacterStats.knockbackForce].
  ///
  /// A zero-length [direction] defaults to pushing upward.
  void applyKnockback(Vector2 direction) {
    if (_currentState == CharacterState.dead) return;

    final normalized = direction.isZero()
        ? Vector2(0, -1)
        : direction.normalized();
    velocity.setFrom(normalized * stats.knockbackForce);
    _knockbackTimer = _knockbackDuration;
  }

  //#endregion

  //#region Dash

  /// Performs a dash in the given [direction].
  ///
  /// Falls back to [facingDirection] when [direction] is zero-length.
  /// Returns `true` when the dash was initiated (i.e. cooldown was
  /// ready). The character receives i-frames for the dash duration.
  bool dash(Vector2 direction) {
    if (isLocked) return false;
    if (_dashCooldownTimer > 0 || _dashTimer > 0) return false;

    final dir = direction.isZero() ? _facingToVector() : direction.normalized();

    velocity.setFrom(dir * stats.speed * stats.dashSpeedMultiplier);
    _dashTimer = stats.dashDuration;
    _dashCooldownTimer = stats.dashCooldown;
    _invincibilityTimer = stats.dashDuration;
    _tryTransition(CharacterState.dashing);
    return true;
  }

  //#endregion

  //#region Stun

  /// Stuns the character for [duration] seconds.
  ///
  /// The character cannot act until the stun expires. Ignored when
  /// already dead or dying.
  void stun(double duration) {
    assert(duration > 0, 'Stun duration must be positive: $duration');
    if (_currentState == CharacterState.dead ||
        _currentState == CharacterState.dying) {
      return;
    }
    _stunTimer = duration;
    velocity.setZero();
    _tryTransition(CharacterState.stunned);
  }

  //#endregion

  //#region Death

  /// Kills the character immediately.
  ///
  /// Zeroes velocity, transitions to [CharacterState.dying], and
  /// invokes [onDeath].
  void die() {
    velocity.setZero();
    _tryTransition(CharacterState.dying);
    onDeath();
  }

  /// Called when the character dies.
  ///
  /// Override for custom death behaviour such as dropping loot or
  /// playing a sound effect. The default implementation does nothing.
  void onDeath() {}

  //#endregion

  //#region XP / Leveling

  /// Awards [amount] XP to this character.
  ///
  /// When the XP threshold is met the character levels up and
  /// [onLevelUp] is called. Multiple level-ups in a single call are
  /// supported.
  void addXp(int amount) {
    assert(amount >= 0, 'XP amount must be non-negative: $amount');
    stats.currentXp += amount;
    while (stats.currentXp >= stats.xpToNextLevel) {
      stats.currentXp -= stats.xpToNextLevel;
      stats.level += 1;
      stats.xpToNextLevel = _xpForLevel(stats.level + 1);
      onLevelUp(stats.level);
    }
  }

  /// Called when the character reaches [newLevel].
  ///
  /// Override to apply stat upgrades, unlock abilities, etc. The
  /// default implementation does nothing.
  void onLevelUp(int newLevel) {}

  /// Returns the XP required to reach [level] using a simple
  /// quadratic curve.
  int _xpForLevel(int level) => (100 * pow(level, 1.5)).toInt();

  //#endregion

  //#region Healing

  /// Restores [amount] HP, clamped to [CharacterStats.maxHp].
  ///
  /// Has no effect when the character is dead.
  void heal(double amount) {
    assert(amount >= 0, 'Heal amount must be non-negative: $amount');
    if (!stats.isAlive) return;
    stats.currentHp = (stats.currentHp + amount).clamp(0, stats.maxHp);
  }

  //#endregion

  //#region Queries

  /// Returns `true` when the character is still alive.
  bool get isAlive => stats.isAlive;

  /// Returns `true` when invincibility frames are active.
  bool get isInvincible => _invincibilityTimer > 0;

  /// Returns `true` when the character is mid-dash.
  bool get isDashing => _dashTimer > 0;

  /// Returns `true` when the character can initiate an attack.
  ///
  /// Requires an equipped weapon whose cooldown has expired and the
  /// character must not be locked.
  bool get canAttack => _weapon != null && _weapon!.canFire && !isLocked;

  /// Returns `true` when the character can initiate a dash.
  bool get canDash => _dashCooldownTimer <= 0 && _dashTimer <= 0 && !isLocked;

  /// Returns `true` when the character cannot voluntarily act (dead,
  /// dying, stunned, or hit-stunned).
  bool get isLocked =>
      _currentState == CharacterState.dead ||
      _currentState == CharacterState.dying ||
      _currentState == CharacterState.stunned ||
      _currentState == CharacterState.hit;

  //#endregion

  //#region Private helpers

  /// Attempts a state transition; silently ignored if not allowed.
  bool _tryTransition(CharacterState next) {
    if (next == _currentState) return false;
    final allowed = _allowedTransitions[_currentState];
    if (allowed == null || !allowed.contains(next)) return false;
    _currentState = next;
    return true;
  }

  void _tickTimers(double dt) {
    if (_invincibilityTimer > 0) {
      _invincibilityTimer = (_invincibilityTimer - dt).clamp(
        0,
        double.infinity,
      );
      // Flashing effect during invincibility.
      opacity = (_invincibilityTimer * 10).toInt().isEven ? 1.0 : 0.4;
      if (_invincibilityTimer == 0) opacity = 1.0;
    }

    if (_dashTimer > 0) {
      _dashTimer = (_dashTimer - dt).clamp(0, double.infinity);
    }

    if (_dashCooldownTimer > 0) {
      _dashCooldownTimer = (_dashCooldownTimer - dt).clamp(0, double.infinity);
    }

    if (_knockbackTimer > 0) {
      _knockbackTimer = (_knockbackTimer - dt).clamp(0, double.infinity);
    }

    if (_stunTimer > 0) {
      _stunTimer = (_stunTimer - dt).clamp(0, double.infinity);
      if (_stunTimer == 0) {
        _tryTransition(CharacterState.idle);
      }
    }
  }

  void _applyVelocity(double dt) {
    _previousPosition.setFrom(position);
    position.add(velocity * dt);

    // Decay velocity when not actively moving or dashing.
    if (_knockbackTimer <= 0 && _dashTimer <= 0) {
      if (_currentState != CharacterState.moving) {
        velocity.setZero();
      }
    }
  }

  void _handleAutoStateTransitions() {
    // After dash ends → idle.
    if (_currentState == CharacterState.dashing && _dashTimer <= 0) {
      velocity.setZero();
      _tryTransition(CharacterState.idle);
    }

    // After hit i-frames expire → idle.
    if (_currentState == CharacterState.hit && _invincibilityTimer <= 0) {
      _tryTransition(CharacterState.idle);
    }

    // After dying animation completes → dead.
    if (_currentState == CharacterState.dying) {
      final dyingAnim = _animations[CharacterState.dying];
      if (dyingAnim != null &&
          animationTicker != null &&
          animationTicker!.done()) {
        _tryTransition(CharacterState.dead);
      }
    }
  }

  /// Swaps the current animation to match [_currentState].
  void _syncAnimation() {
    final target = _animations[_currentState];
    if (target != null && animation != target) {
      animation = target;
    }
  }

  /// Converts the current [facingDirection] into a unit vector.
  Vector2 _facingToVector() {
    return switch (facingDirection) {
      Direction.up => Vector2(0, -1),
      Direction.upRight => Vector2(1, -1).normalized(),
      Direction.right => Vector2(1, 0),
      Direction.downRight => Vector2(1, 1).normalized(),
      Direction.down => Vector2(0, 1),
      Direction.downLeft => Vector2(-1, 1).normalized(),
      Direction.left => Vector2(-1, 0),
      Direction.upLeft => Vector2(-1, -1).normalized(),
      Direction.none => Vector2.zero(),
    };
  }

  //#endregion
}
