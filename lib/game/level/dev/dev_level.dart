import 'dart:math';

import 'package:flame/components.dart';
import 'package:nexus_survivor/game/character/base/base_character_component.dart';
import 'package:nexus_survivor/game/level/base_level.dart';
import 'package:nexus_survivor/game/level/level_config.dart';
import 'package:nexus_survivor/game/monster/dev_monster.dart';
import 'package:nexus_survivor/game/nexus/base_nexus_component.dart';
import 'package:nexus_survivor/game/world/wave_config.dart';

/// [DevLevel] is a concrete [BaseLevel] used during development.
///
/// It spawns [DevMonster] instances at random positions on a circle
/// surrounding the nexus. Each monster targets the nexus by default
/// and switches to the player on aggro.
class DevLevel extends BaseLevel {
  /// Creates a [DevLevel] with the given [config].
  ///
  /// [nexus] and [player] are required so spawned monsters can
  /// navigate toward them. When [config] is omitted a default
  /// multi-wave configuration is used.
  DevLevel({
    LevelConfig? config,
    this.nexus,
    this.player,
    this.spawnRadius = 500,
  }) : super(config: config ?? _defaultDevConfig());

  /// The nexus component monsters will target.
  final BaseNexusComponent? nexus;

  /// The player character — monsters switch aggro when nearby.
  final BaseCharacterComponent? player;

  /// Radius of the spawn circle centred on the nexus.
  final double spawnRadius;

  /// Number of times [onSpawnEnemy] was invoked (for debug display).
  int spawnCount = 0;

  /// Number of times the level was completed.
  int completeCount = 0;

  /// Number of times the level failed.
  int failedCount = 0;

  final Random _rng = Random();

  //#region BaseLevel hooks

  @override
  void onSpawnEnemy(int waveNumber) {
    spawnCount++;

    if (nexus == null) {
      // Fallback: no nexus reference — immediately mark defeated so
      // the wave state machine can progress.
      onEnemyDefeated();
      return;
    }

    final angle = _rng.nextDouble() * 2 * pi;
    final spawnPos =
        nexus!.center +
        Vector2(cos(angle) * spawnRadius, sin(angle) * spawnRadius);

    final monster = DevMonster(
      nexus: nexus!,
      spawnPosition: spawnPos,
      player: player,
      deathCallback: onEnemyDefeated,
    );

    // Add the monster to the same parent as the level (the GameWorld).
    parent?.add(monster);
  }

  @override
  void onLevelComplete() {
    completeCount++;
  }

  @override
  void onLevelFailed() {
    failedCount++;
  }

  //#endregion

  /// Returns a default [LevelConfig] for development testing.
  static LevelConfig _defaultDevConfig() {
    return LevelConfig(
      levelNumber: 1,
      waves: const [
        WaveConfig(
          waveNumber: 1,
          enemyCount: 3,
          spawnInterval: 2.0,
          delayBeforeWave: 1.0,
        ),
        WaveConfig(
          waveNumber: 2,
          enemyCount: 5,
          spawnInterval: 1.5,
          delayBeforeWave: 2.0,
        ),
      ],
      nexusMaxHp: 500,
    );
  }
}
