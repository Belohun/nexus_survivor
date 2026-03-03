import 'package:nexus_survivor/game/world/base_level.dart';
import 'package:nexus_survivor/game/world/level_config.dart';
import 'package:nexus_survivor/game/world/wave_config.dart';

/// A minimal concrete [BaseLevel] used in tests.
///
/// Records hook invocations so tests can assert spawn counts,
/// completion, and failure callbacks.
class TestLevel extends BaseLevel {
  /// Creates a [TestLevel] with the given [config].
  TestLevel({required super.config});

  /// Number of times [onSpawnEnemy] was called.
  int spawnCount = 0;

  /// The last wave number passed to [onSpawnEnemy].
  int lastSpawnWaveNumber = 0;

  /// Number of times [onLevelComplete] was called.
  int completeCount = 0;

  /// Number of times [onLevelFailed] was called.
  int failedCount = 0;

  @override
  void onSpawnEnemy(int waveNumber) {
    spawnCount++;
    lastSpawnWaveNumber = waveNumber;
  }

  @override
  void onLevelComplete() {
    completeCount++;
  }

  @override
  void onLevelFailed() {
    failedCount++;
  }
}

/// Creates a default [LevelConfig] suitable for most tests.
LevelConfig defaultTestLevelConfig({
  int levelNumber = 1,
  List<WaveConfig>? waves,
  double nexusMaxHp = 100,
  double? timeLimit,
}) {
  return LevelConfig(
    levelNumber: levelNumber,
    waves: waves ?? [const WaveConfig(waveNumber: 1, enemyCount: 3)],
    nexusMaxHp: nexusMaxHp,
    timeLimit: timeLimit,
  );
}
