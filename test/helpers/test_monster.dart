import 'dart:ui';

import 'package:nexus_survivor/game/monster/base/base_monster_component.dart';
import 'package:nexus_survivor/game/monster/base/monster_stats.dart';
import 'package:nexus_survivor/game/monster/base/monster_target_mode.dart';

/// A minimal concrete [BaseMonsterComponent] used in tests.
///
/// Records hook invocations so tests can assert aggro changes,
/// death callbacks, etc.
class TestMonster extends BaseMonsterComponent {
  /// Creates a [TestMonster] with the given [testStats].
  TestMonster({
    required super.nexus,
    required super.spawnPosition,
    super.player,
    super.deathCallback,
    required MonsterStats testStats,
  }) : _testStats = testStats;

  final MonsterStats _testStats;

  /// Number of times [onDeath] was called.
  int deathCount = 0;

  /// Number of times [onAggroChanged] was called.
  int aggroChangedCount = 0;

  /// The last [MonsterTargetMode] received by [onAggroChanged].
  MonsterTargetMode? lastAggroMode;

  @override
  MonsterStats get baseStats => _testStats;

  @override
  void renderMonster(Canvas canvas) {
    // No-op for tests.
  }

  @override
  void onDeath() {
    deathCount++;
  }

  @override
  void onAggroChanged(MonsterTargetMode newMode) {
    aggroChangedCount++;
    lastAggroMode = newMode;
  }
}

/// Creates default [MonsterStats] suitable for most tests.
MonsterStats defaultTestMonsterStats({
  double maxHp = 50,
  double speed = 60,
  double damage = 5,
  double defense = 0,
  double attackCooldown = 1.0,
  double aggroRange = 150,
  double deaggroRange = 300,
  double knockbackForce = 100,
  int xpReward = 10,
}) {
  return MonsterStats(
    maxHp: maxHp,
    speed: speed,
    damage: damage,
    defense: defense,
    attackCooldown: attackCooldown,
    aggroRange: aggroRange,
    deaggroRange: deaggroRange,
    knockbackForce: knockbackForce,
    xpReward: xpReward,
  );
}
