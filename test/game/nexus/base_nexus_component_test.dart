import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_survivor/game/nexus/nexus_stats.dart';
import 'package:nexus_survivor/game/nexus_survivor.dart';

import '../../helpers/test_nexus.dart';

void main() {
  group('NexusStats', () {
    test('currentHp defaults to maxHp', () {
      final stats = defaultTestNexusStats(maxHp: 200);
      expect(stats.currentHp, 200);
    });

    test('isDestroyed returns true when currentHp is zero', () {
      final stats = defaultTestNexusStats(maxHp: 100, currentHp: 0);
      expect(stats.isDestroyed, isTrue);
    });

    test('hpFraction returns correct ratio', () {
      final stats = defaultTestNexusStats(maxHp: 200, currentHp: 50);
      expect(stats.hpFraction, closeTo(0.25, 0.001));
    });

    test('copyWith preserves original values when no overrides given', () {
      final stats = defaultTestNexusStats(maxHp: 300, defense: 10);
      final copy = stats.copyWith();
      expect(copy.maxHp, 300);
      expect(copy.defense, 10);
      expect(copy.currentHp, 300);
    });

    test('copyWith applies overrides', () {
      final stats = defaultTestNexusStats(maxHp: 300, defense: 10);
      final copy = stats.copyWith(maxHp: 500, defense: 20, currentHp: 100);
      expect(copy.maxHp, 500);
      expect(copy.defense, 20);
      expect(copy.currentHp, 100);
    });

    test('assert triggers for maxHp <= 0', () {
      expect(
        () => defaultTestNexusStats(maxHp: 0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('assert triggers for negative defense', () {
      expect(
        () => defaultTestNexusStats(defense: -1),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('BaseNexusComponent', () {
    Future<(NexusSurvivor, TestNexus)> mountedNexus({NexusStats? stats}) async {
      final game = await initializeGame(NexusSurvivor.new);
      final nexus = TestNexus(testStats: stats ?? defaultTestNexusStats());
      await game.ensureAdd(nexus);
      return (game, nexus);
    }

    test('stats are a copy of baseStats', () async {
      final stats = defaultTestNexusStats(maxHp: 200, defense: 5);
      final (_, nexus) = await mountedNexus(stats: stats);

      expect(nexus.stats.maxHp, 200);
      expect(nexus.stats.defense, 5);

      // Mutating live stats should not affect the original.
      nexus.stats.defense = 99;
      expect(stats.defense, 5);
    });

    test('takeDamage reduces currentHp', () async {
      final (_, nexus) = await mountedNexus(
        stats: defaultTestNexusStats(maxHp: 100),
      );

      nexus.takeDamage(30);
      expect(nexus.stats.currentHp, 70);
      expect(nexus.isDestroyed, isFalse);
    });

    test('takeDamage respects defense', () async {
      final (_, nexus) = await mountedNexus(
        stats: defaultTestNexusStats(maxHp: 100, defense: 10),
      );

      nexus.takeDamage(25);
      // 25 - 10 defense = 15 effective damage → 85 HP.
      expect(nexus.stats.currentHp, 85);
    });

    test('defense cannot reduce damage below zero', () async {
      final (_, nexus) = await mountedNexus(
        stats: defaultTestNexusStats(maxHp: 100, defense: 50),
      );

      nexus.takeDamage(10);
      // 10 - 50 defense = clamped to 0 → 100 HP unchanged.
      expect(nexus.stats.currentHp, 100);
    });

    test('takeDamage triggers onDestroyed when HP reaches zero', () async {
      final (_, nexus) = await mountedNexus(
        stats: defaultTestNexusStats(maxHp: 50),
      );

      nexus.takeDamage(50);
      expect(nexus.isDestroyed, isTrue);
      expect(nexus.destroyedCount, 1);
    });

    test('onDestroyed is called exactly once', () async {
      final (_, nexus) = await mountedNexus(
        stats: defaultTestNexusStats(maxHp: 50),
      );

      nexus.takeDamage(50);
      nexus.takeDamage(20); // Already destroyed — should be no-op.
      expect(nexus.destroyedCount, 1);
    });

    test('HP does not go below zero', () async {
      final (_, nexus) = await mountedNexus(
        stats: defaultTestNexusStats(maxHp: 30),
      );

      nexus.takeDamage(100);
      expect(nexus.stats.currentHp, 0);
    });

    test('heal restores HP up to maxHp', () async {
      final (_, nexus) = await mountedNexus(
        stats: defaultTestNexusStats(maxHp: 100),
      );

      nexus.takeDamage(60);
      expect(nexus.stats.currentHp, 40);

      nexus.heal(30);
      expect(nexus.stats.currentHp, 70);

      // Should not exceed maxHp.
      nexus.heal(500);
      expect(nexus.stats.currentHp, 100);
    });

    test('heal has no effect on destroyed nexus', () async {
      final (_, nexus) = await mountedNexus(
        stats: defaultTestNexusStats(maxHp: 50),
      );

      nexus.takeDamage(50);
      expect(nexus.isDestroyed, isTrue);

      nexus.heal(30);
      expect(nexus.stats.currentHp, 0);
    });

    test('assert triggers for negative damage', () async {
      final (_, nexus) = await mountedNexus(
        stats: defaultTestNexusStats(maxHp: 100),
      );

      expect(() => nexus.takeDamage(-5), throwsA(isA<AssertionError>()));
    });

    test('assert triggers for negative heal', () async {
      final (_, nexus) = await mountedNexus(
        stats: defaultTestNexusStats(maxHp: 100),
      );

      expect(() => nexus.heal(-5), throwsA(isA<AssertionError>()));
    });
  });
}
