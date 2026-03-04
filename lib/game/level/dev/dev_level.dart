import 'package:nexus_survivor/game/level/base_level.dart';
import 'package:nexus_survivor/game/level/level_config.dart';
import 'package:nexus_survivor/game/world/wave_config.dart';

/// [DevLevel] is a concrete [BaseLevel] used during development.
///
/// It provides a simple multi-wave configuration with no real enemy
/// spawning — [onSpawnEnemy] is a no-op so the wave timer ticks but
/// no entities are created. This allows testing of the level state
/// machine, nexus health, and the joystick/controller pipeline on a
/// blank canvas.
class DevLevel extends BaseLevel {
  /// Creates a [DevLevel] with the given [config].
  ///
  /// When [config] is omitted a default single-wave configuration is
  /// used.
  DevLevel({LevelConfig? config})
    : super(config: config ?? _defaultDevConfig());

  /// Number of times [onSpawnEnemy] was invoked (for debug display).
  int spawnCount = 0;

  /// Number of times the level was completed.
  int completeCount = 0;

  /// Number of times the level failed.
  int failedCount = 0;

  //#region BaseLevel hooks

  @override
  void onSpawnEnemy(int waveNumber) {
    spawnCount++;
    // No-op: real enemy spawning is not yet implemented.
    // Immediately mark the enemy as defeated so the wave can progress.
    onEnemyDefeated();
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
