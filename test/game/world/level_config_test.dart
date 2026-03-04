import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_survivor/game/world/level_config.dart';
import 'package:nexus_survivor/game/world/wave_config.dart';

void main() {
  group('LevelConfig', () {
    test('creates with required fields', () {
      final config = LevelConfig(
        levelNumber: 1,
        waves: const [WaveConfig(waveNumber: 1, enemyCount: 5)],
        nexusMaxHp: 100,
      );

      expect(config.levelNumber, 1);
      expect(config.waves.length, 1);
      expect(config.nexusMaxHp, 100);
      expect(config.timeLimit, isNull);
      expect(config.totalWaves, 1);
    });

    test('creates with optional timeLimit', () {
      final config = LevelConfig(
        levelNumber: 2,
        waves: const [
          WaveConfig(waveNumber: 1, enemyCount: 3),
          WaveConfig(waveNumber: 2, enemyCount: 6),
        ],
        nexusMaxHp: 200,
        timeLimit: 120.0,
      );

      expect(config.timeLimit, 120.0);
      expect(config.totalWaves, 2);
    });

    test('waves list is unmodifiable', () {
      final config = LevelConfig(
        levelNumber: 1,
        waves: const [WaveConfig(waveNumber: 1, enemyCount: 5)],
        nexusMaxHp: 100,
      );

      expect(
        () => (config.waves as List).add(
          const WaveConfig(waveNumber: 2, enemyCount: 3),
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('asserts on levelNumber < 1', () {
      expect(
        () => LevelConfig(
          levelNumber: 0,
          waves: const [WaveConfig(waveNumber: 1, enemyCount: 1)],
          nexusMaxHp: 100,
        ),
        throwsA(
          isA<AssertionError>().having(
            (e) => e.message,
            'message',
            contains('levelNumber must be >= 1: 0'),
          ),
        ),
      );
    });

    test('asserts on empty waves', () {
      expect(
        () => LevelConfig(levelNumber: 1, waves: const [], nexusMaxHp: 100),
        throwsA(
          isA<AssertionError>().having(
            (e) => e.message,
            'message',
            contains('waves must not be empty'),
          ),
        ),
      );
    });

    test('asserts on nexusMaxHp <= 0', () {
      expect(
        () => LevelConfig(
          levelNumber: 1,
          waves: const [WaveConfig(waveNumber: 1, enemyCount: 1)],
          nexusMaxHp: 0,
        ),
        throwsA(
          isA<AssertionError>().having(
            (e) => e.message,
            'message',
            contains('nexusMaxHp must be > 0: 0'),
          ),
        ),
      );
    });

    test('asserts on timeLimit <= 0', () {
      expect(
        () => LevelConfig(
          levelNumber: 1,
          waves: const [WaveConfig(waveNumber: 1, enemyCount: 1)],
          nexusMaxHp: 100,
          timeLimit: 0,
        ),
        throwsA(
          isA<AssertionError>().having(
            (e) => e.message,
            'message',
            contains('timeLimit must be > 0 when provided: 0'),
          ),
        ),
      );
    });
  });
}
