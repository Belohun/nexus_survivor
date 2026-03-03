import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_survivor/game/world/wave_config.dart';

void main() {
  group('WaveConfig', () {
    test('creates with required fields', () {
      const wave = WaveConfig(waveNumber: 1, enemyCount: 5);

      expect(wave.waveNumber, 1);
      expect(wave.enemyCount, 5);
      expect(wave.spawnInterval, 1.0);
      expect(wave.delayBeforeWave, 3.0);
    });

    test('creates with all fields overridden', () {
      const wave = WaveConfig(
        waveNumber: 3,
        enemyCount: 10,
        spawnInterval: 0.5,
        delayBeforeWave: 5.0,
      );

      expect(wave.waveNumber, 3);
      expect(wave.enemyCount, 10);
      expect(wave.spawnInterval, 0.5);
      expect(wave.delayBeforeWave, 5.0);
    });

    test('copyWith creates independent copy', () {
      const original = WaveConfig(waveNumber: 1, enemyCount: 5);
      final copy = original.copyWith(enemyCount: 20, spawnInterval: 0.2);

      expect(copy.waveNumber, 1);
      expect(copy.enemyCount, 20);
      expect(copy.spawnInterval, 0.2);
      expect(copy.delayBeforeWave, 3.0);
    });

    test('copyWith with no arguments returns equivalent copy', () {
      const original = WaveConfig(
        waveNumber: 2,
        enemyCount: 8,
        spawnInterval: 0.7,
        delayBeforeWave: 2.0,
      );
      final copy = original.copyWith();

      expect(copy.waveNumber, original.waveNumber);
      expect(copy.enemyCount, original.enemyCount);
      expect(copy.spawnInterval, original.spawnInterval);
      expect(copy.delayBeforeWave, original.delayBeforeWave);
    });

    test('asserts on waveNumber < 1', () {
      expect(
        () => WaveConfig(waveNumber: 0, enemyCount: 1),
        throwsA(
          isA<AssertionError>().having(
            (e) => e.message,
            'message',
            contains('waveNumber must be >= 1: 0'),
          ),
        ),
      );
    });

    test('asserts on enemyCount < 1', () {
      expect(
        () => WaveConfig(waveNumber: 1, enemyCount: 0),
        throwsA(
          isA<AssertionError>().having(
            (e) => e.message,
            'message',
            contains('enemyCount must be >= 1: 0'),
          ),
        ),
      );
    });

    test('asserts on spawnInterval <= 0', () {
      expect(
        () => WaveConfig(waveNumber: 1, enemyCount: 1, spawnInterval: 0),
        throwsA(
          isA<AssertionError>().having(
            (e) => e.message,
            'message',
            contains('spawnInterval must be > 0: 0'),
          ),
        ),
      );
    });

    test('asserts on negative delayBeforeWave', () {
      expect(
        () => WaveConfig(waveNumber: 1, enemyCount: 1, delayBeforeWave: -1),
        throwsA(
          isA<AssertionError>().having(
            (e) => e.message,
            'message',
            contains('delayBeforeWave must be >= 0: -1'),
          ),
        ),
      );
    });
  });
}
