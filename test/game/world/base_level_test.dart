import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_survivor/game/nexus_survivor.dart';
import 'package:nexus_survivor/game/world/level_config.dart';
import 'package:nexus_survivor/game/world/level_state.dart';
import 'package:nexus_survivor/game/world/wave_config.dart';

import '../../helpers/test_level.dart';

void main() {
  group('BaseLevel', () {
    Future<(NexusSurvivor, TestLevel)> mountedLevel({
      LevelConfig? config,
    }) async {
      final game = await initializeGame(NexusSurvivor.new);
      final level = TestLevel(config: config ?? defaultTestLevelConfig());
      await game.ensureAdd(level);
      return (game, level);
    }

    test('starts in loading state', () async {
      final (_, level) = await mountedLevel();

      expect(level.currentState, LevelState.loading);
      expect(level.nexusHp, 0);
    });

    test(
      'startLevel transitions to playing and initialises nexus HP',
      () async {
        final (_, level) = await mountedLevel();
        level.startLevel();

        expect(level.currentState, LevelState.playing);
        expect(level.nexusHp, 100);
        expect(level.currentWaveIndex, 0);
        expect(level.elapsedTime, 0);
      },
    );

    test('startLevel asserts when not in loading state', () async {
      final (_, level) = await mountedLevel();
      level.startLevel();

      expect(
        () => level.startLevel(),
        throwsA(
          isA<AssertionError>().having(
            (e) => e.message,
            'message',
            contains('startLevel() called in unexpected state'),
          ),
        ),
      );
    });

    test('transitions to waveInProgress after delay expires', () async {
      final config = LevelConfig(
        levelNumber: 1,
        waves: const [
          WaveConfig(
            waveNumber: 1,
            enemyCount: 2,
            delayBeforeWave: 1.0,
            spawnInterval: 0.5,
          ),
        ],
        nexusMaxHp: 100,
      );
      final (_, level) = await mountedLevel(config: config);
      level.startLevel();

      expect(level.currentState, LevelState.playing);

      // Advance past the delay.
      level.update(1.0);

      expect(level.currentState, LevelState.waveInProgress);
    });

    test('spawns enemies at the configured interval', () async {
      final config = LevelConfig(
        levelNumber: 1,
        waves: const [
          WaveConfig(
            waveNumber: 1,
            enemyCount: 3,
            delayBeforeWave: 0,
            spawnInterval: 1.0,
          ),
        ],
        nexusMaxHp: 100,
      );
      final (_, level) = await mountedLevel(config: config);
      level.startLevel();

      // Delay is 0, so first update should start the wave and spawn.
      level.update(0.1);
      expect(level.currentState, LevelState.waveInProgress);
      expect(level.spawnCount, 1);
      expect(level.enemiesAlive, 1);

      // Not enough time for next spawn.
      level.update(0.5);
      expect(level.spawnCount, 1);

      // Enough time for second spawn.
      level.update(0.5);
      expect(level.spawnCount, 2);
      expect(level.enemiesAlive, 2);
    });

    test('onSpawnEnemy receives correct wave number', () async {
      final config = LevelConfig(
        levelNumber: 1,
        waves: const [
          WaveConfig(
            waveNumber: 1,
            enemyCount: 1,
            delayBeforeWave: 0,
            spawnInterval: 1.0,
          ),
        ],
        nexusMaxHp: 100,
      );
      final (_, level) = await mountedLevel(config: config);
      level.startLevel();
      level.update(0.1);

      expect(level.lastSpawnWaveNumber, 1);
    });

    test('defeating all enemies completes the wave', () async {
      final config = LevelConfig(
        levelNumber: 1,
        waves: const [
          WaveConfig(
            waveNumber: 1,
            enemyCount: 2,
            delayBeforeWave: 0,
            spawnInterval: 0.1,
          ),
          WaveConfig(
            waveNumber: 2,
            enemyCount: 1,
            delayBeforeWave: 1.0,
            spawnInterval: 0.5,
          ),
        ],
        nexusMaxHp: 100,
      );
      final (_, level) = await mountedLevel(config: config);
      level.startLevel();

      // Spawn both enemies.
      level.update(0.1);
      level.update(0.1);
      expect(level.enemiesAlive, 2);
      expect(level.enemiesSpawned, 2);

      // Defeat both enemies — should advance to next wave delay.
      level.onEnemyDefeated();
      level.onEnemyDefeated();

      // Now in playing state (delay before wave 2).
      expect(level.currentState, LevelState.playing);
      expect(level.currentWaveIndex, 1);
    });

    test(
      'defeating all enemies in the last wave completes the level',
      () async {
        final config = LevelConfig(
          levelNumber: 1,
          waves: const [
            WaveConfig(
              waveNumber: 1,
              enemyCount: 1,
              delayBeforeWave: 0,
              spawnInterval: 1.0,
            ),
          ],
          nexusMaxHp: 100,
        );
        final (_, level) = await mountedLevel(config: config);
        level.startLevel();

        level.update(0.1);
        expect(level.spawnCount, 1);

        level.onEnemyDefeated();

        expect(level.currentState, LevelState.levelComplete);
        expect(level.completeCount, 1);
        expect(level.allWavesComplete, isTrue);
      },
    );

    test('damageNexus reduces HP', () async {
      final (_, level) = await mountedLevel();
      level.startLevel();

      level.damageNexus(30);

      expect(level.nexusHp, 70);
    });

    test('damageNexus triggers failure when HP reaches zero', () async {
      final (_, level) = await mountedLevel();
      level.startLevel();

      level.damageNexus(100);

      expect(level.nexusHp, 0);
      expect(level.currentState, LevelState.failed);
      expect(level.failedCount, 1);
    });

    test('damageNexus does not go below zero', () async {
      final (_, level) = await mountedLevel();
      level.startLevel();

      level.damageNexus(200);

      expect(level.nexusHp, 0);
    });

    test('damageNexus is ignored after level complete', () async {
      final config = LevelConfig(
        levelNumber: 1,
        waves: const [
          WaveConfig(
            waveNumber: 1,
            enemyCount: 1,
            delayBeforeWave: 0,
            spawnInterval: 1.0,
          ),
        ],
        nexusMaxHp: 100,
      );
      final (_, level) = await mountedLevel(config: config);
      level.startLevel();
      level.update(0.1);
      level.onEnemyDefeated();

      expect(level.currentState, LevelState.levelComplete);

      level.damageNexus(50);
      expect(level.nexusHp, 100);
    });

    test('damageNexus is ignored after failure', () async {
      final (_, level) = await mountedLevel();
      level.startLevel();
      level.damageNexus(100);

      expect(level.currentState, LevelState.failed);

      level.damageNexus(50);
      expect(level.nexusHp, 0);
      expect(level.failedCount, 1);
    });

    test('damageNexus asserts on negative amount', () async {
      final (_, level) = await mountedLevel();
      level.startLevel();

      expect(
        () => level.damageNexus(-10),
        throwsA(
          isA<AssertionError>().having(
            (e) => e.message,
            'message',
            contains('Damage amount must be >= 0: -10'),
          ),
        ),
      );
    });

    test('time limit triggers failure', () async {
      final config = LevelConfig(
        levelNumber: 1,
        waves: const [
          WaveConfig(
            waveNumber: 1,
            enemyCount: 100,
            delayBeforeWave: 0,
            spawnInterval: 0.1,
          ),
        ],
        nexusMaxHp: 100,
        timeLimit: 5.0,
      );
      final (_, level) = await mountedLevel(config: config);
      level.startLevel();

      // Advance past the time limit.
      level.update(5.0);

      expect(level.currentState, LevelState.failed);
      expect(level.failedCount, 1);
    });

    test('elapsed time tracks correctly', () async {
      final (_, level) = await mountedLevel();
      level.startLevel();

      level.update(1.5);
      level.update(2.5);

      expect(level.elapsedTime, closeTo(4.0, 0.001));
    });

    test('update stops after level complete', () async {
      final config = LevelConfig(
        levelNumber: 1,
        waves: const [
          WaveConfig(
            waveNumber: 1,
            enemyCount: 1,
            delayBeforeWave: 0,
            spawnInterval: 1.0,
          ),
        ],
        nexusMaxHp: 100,
      );
      final (_, level) = await mountedLevel(config: config);
      level.startLevel();
      level.update(0.1);
      level.onEnemyDefeated();

      final elapsed = level.elapsedTime;
      level.update(10.0);

      // Elapsed should not have changed.
      expect(level.elapsedTime, elapsed);
    });

    test('update stops after failure', () async {
      final (_, level) = await mountedLevel();
      level.startLevel();
      level.damageNexus(100);

      final elapsed = level.elapsedTime;
      level.update(10.0);

      expect(level.elapsedTime, elapsed);
    });

    test('onEnemyDefeated asserts when no enemies alive', () async {
      final (_, level) = await mountedLevel();
      level.startLevel();

      expect(
        () => level.onEnemyDefeated(),
        throwsA(
          isA<AssertionError>().having(
            (e) => e.message,
            'message',
            contains('onEnemyDefeated called with 0 enemies alive'),
          ),
        ),
      );
    });

    test('currentWave returns null when all waves done', () async {
      final config = LevelConfig(
        levelNumber: 1,
        waves: const [
          WaveConfig(
            waveNumber: 1,
            enemyCount: 1,
            delayBeforeWave: 0,
            spawnInterval: 1.0,
          ),
        ],
        nexusMaxHp: 100,
      );
      final (_, level) = await mountedLevel(config: config);
      level.startLevel();
      level.update(0.1);
      level.onEnemyDefeated();

      expect(level.currentWave, isNull);
    });

    test('multi-wave level progresses through all waves', () async {
      final config = LevelConfig(
        levelNumber: 1,
        waves: const [
          WaveConfig(
            waveNumber: 1,
            enemyCount: 1,
            delayBeforeWave: 0,
            spawnInterval: 1.0,
          ),
          WaveConfig(
            waveNumber: 2,
            enemyCount: 1,
            delayBeforeWave: 0,
            spawnInterval: 1.0,
          ),
        ],
        nexusMaxHp: 100,
      );
      final (_, level) = await mountedLevel(config: config);
      level.startLevel();

      // Wave 1: spawn and defeat.
      level.update(0.1);
      expect(level.lastSpawnWaveNumber, 1);
      level.onEnemyDefeated();

      // Wave 2: advance past delay and spawn.
      level.update(0.1);
      expect(level.currentState, LevelState.waveInProgress);
      expect(level.lastSpawnWaveNumber, 2);
      level.onEnemyDefeated();

      expect(level.currentState, LevelState.levelComplete);
      expect(level.completeCount, 1);
    });
  });
}
