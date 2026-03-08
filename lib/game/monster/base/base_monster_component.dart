import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:nexus_survivor/game/character/base/base_character_component.dart';
import 'package:nexus_survivor/game/monster/base/monster_stats.dart';
import 'package:nexus_survivor/game/monster/base/monster_target_mode.dart';
import 'package:nexus_survivor/game/nexus/base_nexus_component.dart';
import 'package:nexus_survivor/game/nexus_survivor.dart';
import 'package:nexus_survivor/game/ui/damage_number.dart';

/// [BaseMonsterComponent] is the abstract foundation for every enemy
/// that can be spawned in waves.
///
/// Monsters are drawn toward the nexus by default. When the player
/// character attacks them (or gets within [MonsterStats.aggroRange]),
/// they switch focus to the player. They return to the nexus when the
/// player exceeds [MonsterStats.deaggroRange].
///
/// Subclasses **must** implement:
/// - [baseStats] — the initial [MonsterStats] for this monster type.
/// - [renderMonster] — custom rendering (placeholder or sprite-based).
///
/// Optionally override:
/// - [onAggroChanged] — callback when the aggro target changes (for
///   animation, SFX, etc.).
/// - [onDeath] — custom death behaviour such as loot drops.
abstract class BaseMonsterComponent extends PositionComponent
    with HasGameReference<NexusSurvivor>, CollisionCallbacks {
  /// Creates a [BaseMonsterComponent] targeting the given [nexus]
  /// and optionally a [player].
  ///
  /// [spawnPosition] is the initial world position. A [deathCallback]
  /// is invoked when the monster dies (used by the level to track
  /// enemy count).
  BaseMonsterComponent({
    required this.nexus,
    required Vector2 spawnPosition,
    this.player,
    this.deathCallback,
  }) {
    position.setFrom(spawnPosition);
  }

  //#region Abstract contract

  /// Returns the starting [MonsterStats] for this monster type.
  ///
  /// A mutable copy is stored in [stats] during [onLoad].
  MonsterStats get baseStats;

  /// Renders the monster body. Called from [render] after the HP bar.
  void renderMonster(Canvas canvas);

  //#endregion

  //#region Public state

  /// Live (mutable) stats — initialised from [baseStats] in [onLoad].
  late MonsterStats stats;

  /// The nexus this monster is heading toward.
  final BaseNexusComponent nexus;

  /// The player character. When non-null, aggro logic is active.
  BaseCharacterComponent? player;

  /// Optional callback fired on death (e.g. to call
  /// [BaseLevel.onEnemyDefeated]).
  final void Function()? deathCallback;

  /// The current aggro target mode.
  MonsterTargetMode get targetMode => _targetMode;

  /// Whether this monster has been killed.
  bool get isDead => _dead;

  //#endregion

  //#region Private fields

  MonsterTargetMode _targetMode = MonsterTargetMode.nexus;
  bool _dead = false;
  double _attackCooldownTimer = 0;
  double _knockbackTimer = 0;
  final Vector2 _velocity = Vector2.zero();

  /// How long a knockback effect lasts (seconds).
  static const double _knockbackDuration = 0.15;

  /// Previous position for collision resolution.
  final Vector2 _previousPosition = Vector2.zero();

  //#endregion

  //#region Lifecycle

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    stats = baseStats.copyWith();
    anchor = Anchor.center;
    await add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_dead) {
      removeFromParent();
      return;
    }


    _tickTimers(dt);

    if (_knockbackTimer <= 0) {
      _updateAggro();
      _moveTowardTarget(dt);
      _tryAttackTarget();
    }

    _applyVelocity(dt);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    renderMonster(canvas);
    _renderHpBar(canvas);
  }

  //#endregion

  //#region Damage

  /// Applies [amount] damage to this monster, respecting [MonsterStats.defense].
  ///
  /// Optionally pass [knockbackDirection] to push the monster on hit.
  /// When HP reaches zero the monster dies.
  void receiveDamage(double amount, {Vector2? knockbackDirection}) {
    assert(amount >= 0, 'Damage amount must be >= 0: $amount');

    if (_dead) return;

    final effective = (amount - stats.defense).clamp(0.0, double.infinity);
    stats.currentHp -= effective;

    // Spawn floating damage number.
    if (effective > 0) {
      parent?.add(
        DamageNumber(value: effective, worldPosition: position.clone()),
      );
    }

    if (stats.currentHp <= 0) {
      stats.currentHp = 0;
      _die();
      return;
    }

    if (knockbackDirection != null) {
      _applyKnockback(knockbackDirection);
    }

    // Getting hit aggros the monster to the player.
    if (_targetMode == MonsterTargetMode.nexus && player != null) {
      _setTargetMode(MonsterTargetMode.player);
    }
  }

  //#endregion

  //#region Aggro

  /// Called when the monster's aggro target changes.
  ///
  /// Override to play animations, change colour, emit particles, etc.
  /// The default implementation does nothing.
  void onAggroChanged(MonsterTargetMode newMode) {}

  void _setTargetMode(MonsterTargetMode mode) {
    if (_targetMode == mode) return;
    _targetMode = mode;
    onAggroChanged(mode);
  }

  void _updateAggro() {
    if (player == null || !player!.isAlive) {
      _setTargetMode(MonsterTargetMode.nexus);
      return;
    }

    final distToPlayer = position.distanceTo(player!.center);

    if (_targetMode == MonsterTargetMode.nexus) {
      if (distToPlayer <= stats.aggroRange) {
        _setTargetMode(MonsterTargetMode.player);
      }
    } else {
      if (distToPlayer > stats.deaggroRange) {
        _setTargetMode(MonsterTargetMode.nexus);
      }
    }
  }

  //#endregion

  //#region Movement

  void _moveTowardTarget(double dt) {
    final target = _currentTargetPosition;
    final direction = target - position;

    if (direction.length < 4) {
      _velocity.setZero();
      return;
    }

    _velocity.setFrom(direction.normalized() * stats.speed);
  }

  /// Returns the world-space position of the current aggro target.
  Vector2 get _currentTargetPosition {
    if (_targetMode == MonsterTargetMode.player && player != null) {
      return player!.center;
    }
    return nexus.center;
  }

  //#endregion

  //#region Attack

  void _tryAttackTarget() {
    if (_attackCooldownTimer > 0) return;

    if (_targetMode == MonsterTargetMode.nexus) {
      final dist = position.distanceTo(nexus.center);
      if (dist < nexus.size.x / 2 + size.x / 2 + 4) {
        nexus.takeDamage(stats.damage);
        _attackCooldownTimer = stats.attackCooldown;
      }
    } else if (_targetMode == MonsterTargetMode.player && player != null) {
      final dist = position.distanceTo(player!.center);
      if (dist < player!.size.x / 2 + size.x / 2 + 4) {
        final dir = (player!.position - position);
        player!.receiveDamage(stats.damage, knockbackDirection: dir);
        _attackCooldownTimer = stats.attackCooldown;
      }
    }
  }

  //#endregion

  //#region Knockback

  void _applyKnockback(Vector2 direction) {
    final normalized = direction.isZero()
        ? Vector2(0, -1)
        : direction.normalized();
    _velocity.setFrom(normalized * stats.knockbackForce);
    _knockbackTimer = _knockbackDuration;
  }

  //#endregion

  //#region Death

  void _die() {
    _dead = true;
    _velocity.setZero();
    onDeath();
    deathCallback?.call();
    removeFromParent();
  }

  /// Called when the monster dies.
  ///
  /// Override for custom death behaviour such as dropping loot or
  /// playing a sound effect. The default implementation does nothing.
  void onDeath() {}

  //#endregion

  //#region Collision resolution

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    // Block movement into the nexus.
    if (other is BaseNexusComponent) {
      _blockMovementInto(other);
    }

    // Block movement into the player character.
    if (other is BaseCharacterComponent) {
      _blockMovementInto(other);
    }

    // Block movement into other monsters (simple separation).
    if (other is BaseMonsterComponent) {
      _separateFrom(other);
    }
  }

  void _blockMovementInto(PositionComponent obstacle) {
    final obstacleRect = obstacle.toRect();

    final tryRevertY = toRect().shift(
      Offset(0, _previousPosition.y - position.y),
    );
    final tryRevertX = toRect().shift(
      Offset(_previousPosition.x - position.x, 0),
    );

    if (!obstacleRect.overlaps(tryRevertY)) {
      position.y = _previousPosition.y;
    } else if (!obstacleRect.overlaps(tryRevertX)) {
      position.x = _previousPosition.x;
    } else {
      position.setFrom(_previousPosition);
    }
  }

  void _separateFrom(BaseMonsterComponent other) {
    final diff = position - other.position;
    if (diff.isZero()) {
      diff.setValues(1, 0);
    }
    position.add(diff.normalized() * 0.5);
  }

  //#endregion

  //#region Private helpers

  void _tickTimers(double dt) {
    if (_attackCooldownTimer > 0) {
      _attackCooldownTimer = (_attackCooldownTimer - dt).clamp(
        0,
        double.infinity,
      );
    }
    if (_knockbackTimer > 0) {
      _knockbackTimer = (_knockbackTimer - dt).clamp(0, double.infinity);
    }
  }

  void _applyVelocity(double dt) {
    _previousPosition.setFrom(position);
    position.add(_velocity * dt);

    // Decay knockback velocity.
    if (_knockbackTimer <= 0) {
      // Velocity is recalculated each frame, no manual decay needed
      // outside of knockback.
    }
  }

  void _renderHpBar(Canvas canvas) {
    if (_dead) return;
    if (stats.currentHp >= stats.maxHp) return;

    final barWidth = size.x;
    final barHeight = 4.0;
    final barY = -8.0;

    // Background (dark).
    canvas.drawRect(
      Rect.fromLTWH(0, barY, barWidth, barHeight),
      _hpBarBackgroundPaint,
    );

    // Foreground (green → red based on HP fraction).
    final fraction = stats.hpFraction;
    final filledWidth = barWidth * fraction;
    final color = Color.lerp(
      const Color(0xFFFF0000),
      const Color(0xFF00FF00),
      fraction,
    )!;

    canvas.drawRect(
      Rect.fromLTWH(0, barY, filledWidth, barHeight),
      Paint()..color = color,
    );
  }

  static final Paint _hpBarBackgroundPaint = Paint()
    ..color = const Color(0xFF333333);

  //#endregion
}
