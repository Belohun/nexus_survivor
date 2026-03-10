import 'dart:ui';

import 'package:flame/components.dart';
import 'package:nexus_survivor/game/monster/base/base_monster_component.dart';
import 'package:nexus_survivor/game/monster/base/monster_stats.dart';
import 'package:nexus_survivor/game/monster/base/monster_target_mode.dart';

/// [DevMonster] is a concrete [BaseMonsterComponent] used during
/// development.
///
/// It renders as a simple red square (no sprite assets required)
/// and provides default stats suitable for testing the monster AI,
/// aggro system, and wave spawning.
class DevMonster extends BaseMonsterComponent {
  /// Creates a [DevMonster] at the given [spawnPosition].
  ///
  /// Uses [devStats] when provided; otherwise falls back to sensible
  /// defaults.
  DevMonster({
    required super.nexus,
    required super.spawnPosition,
    super.player,
    super.deathCallback,
    MonsterStats? devStats,
  }) : _devStats =
           devStats ??
           MonsterStats(
             maxHp: 30,
             speed: 60,
             damage: 5,
             attackCooldown: 1.0,
             aggroRange: 150,
             deaggroRange: 300,
             xpReward: 10,
           );

  final MonsterStats _devStats;

  /// Whether the monster is currently aggroed (used for colour change).
  bool _aggroed = false;

  //#region BaseMonsterComponent contract

  @override
  MonsterStats get baseStats => _devStats;

  @override
  void renderMonster(Canvas canvas) {
    final paint = Paint()
      ..color = _aggroed
          ? const Color(0xFFFF5722) // orange-red when aggroed
          : const Color(0xFFE53935); // red when passive

    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), paint);

    // Draw a small eye indicator for facing.
    final eyePaint = Paint()..color = const Color(0xFFFFFFFF);
    canvas.drawCircle(Offset(size.x * 0.7, size.y * 0.3), 3, eyePaint);
  }

  @override
  void onAggroChanged(MonsterTargetMode newMode) {
    _aggroed = newMode == MonsterTargetMode.player;
  }

  //#endregion

  //#region Lifecycle

  @override
  Future<void> onLoad() async {
    size = Vector2(24, 24);
    await super.onLoad();
  }

  //#endregion
}
