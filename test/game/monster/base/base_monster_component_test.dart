import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_survivor/game/monster/base/monster_stats.dart';
import 'package:nexus_survivor/game/monster/base/monster_target_mode.dart';
import 'package:nexus_survivor/game/nexus_survivor.dart';

import '../../../helpers/test_character.dart';
import '../../../helpers/test_monster.dart';
import '../../../helpers/test_nexus.dart';

void main() {
  group('MonsterStats', () {
    test('currentHp defaults to maxHp', () {
      final stats = defaultTestMonsterStats(maxHp: 80);
      expect(stats.currentHp, 80);
    });

    test('isAlive returns true when currentHp > 0', () {
      final stats = defaultTestMonsterStats(maxHp: 50, speed: 60, damage: 5);
      expect(stats.isAlive, isTrue);
    });

    test('isAlive returns false when currentHp is 0', () {
      final stats = MonsterStats(maxHp: 50, currentHp: 0, speed: 60, damage: 5);
      expect(stats.isAlive, isFalse);
    });

    test('hpFraction returns correct ratio', () {
      final stats = MonsterStats(
        maxHp: 100,
        currentHp: 25,
        speed: 60,
        damage: 5,
      );
      expect(stats.hpFraction, closeTo(0.25, 0.001));
    });

    test('copyWith preserves original values when no overrides given', () {
      final stats = defaultTestMonsterStats(maxHp: 80, defense: 5);
      final copy = stats.copyWith();
      expect(copy.maxHp, 80);
      expect(copy.defense, 5);
      expect(copy.currentHp, 80);
    });

    test('copyWith applies overrides', () {
      final stats = defaultTestMonsterStats(maxHp: 80);
      final copy = stats.copyWith(maxHp: 200, damage: 20);
      expect(copy.maxHp, 200);
      expect(copy.damage, 20);
    });

    test('assert triggers for maxHp <= 0', () {
      expect(
        () => MonsterStats(maxHp: 0, speed: 60, damage: 5),
        throwsA(isA<AssertionError>()),
      );
    });

    test('assert triggers for negative speed', () {
      expect(
        () => MonsterStats(maxHp: 50, speed: -1, damage: 5),
        throwsA(isA<AssertionError>()),
      );
    });

    test('assert triggers for deaggroRange < aggroRange', () {
      expect(
        () => MonsterStats(
          maxHp: 50,
          speed: 60,
          damage: 5,
          aggroRange: 200,
          deaggroRange: 100,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('BaseMonsterComponent', () {
    Future<(NexusSurvivor, TestMonster, TestNexus, TestCharacter)>
    mountedMonster({
      MonsterStats? stats,
      Vector2? spawnPosition,
      bool withPlayer = true,
    }) async {
      final game = await initializeGame(NexusSurvivor.new);

      final nexus = TestNexus(
        testStats: defaultTestNexusStats(maxHp: 500),
        testSize: Vector2(64, 64),
        testPosition: Vector2(-32, -32),
      );
      await game.ensureAdd(nexus);

      final character = TestCharacter(
        testStats: defaultTestStats(maxHp: 100, speed: 200, damage: 10),
      );
      await character.init();
      await game.ensureAdd(character);

      final monster = TestMonster(
        nexus: nexus,
        spawnPosition: spawnPosition ?? Vector2(300, 0),
        player: withPlayer ? character : null,
        testStats: stats ?? defaultTestMonsterStats(),
      );
      await game.ensureAdd(monster);

      return (game, monster, nexus, character);
    }

    test('stats are a copy of baseStats', () async {
      final (_, monster, _, _) = await mountedMonster(
        stats: defaultTestMonsterStats(maxHp: 80, defense: 3),
      );

      expect(monster.stats.maxHp, 80);
      expect(monster.stats.defense, 3);

      // Mutating live stats should not affect the original.
      monster.stats.defense = 99;
      expect(monster.baseStats.defense, 3);
    });

    test('starts targeting nexus', () async {
      final (_, monster, _, _) = await mountedMonster();
      expect(monster.targetMode, MonsterTargetMode.nexus);
    });

    test('receiveDamage reduces HP', () async {
      final (_, monster, _, _) = await mountedMonster(
        stats: defaultTestMonsterStats(maxHp: 50),
      );

      monster.receiveDamage(20);
      expect(monster.stats.currentHp, 30);
      expect(monster.isDead, isFalse);
    });

    test('receiveDamage respects defense', () async {
      final (_, monster, _, _) = await mountedMonster(
        stats: defaultTestMonsterStats(maxHp: 50, defense: 5),
      );

      monster.receiveDamage(8);
      // 8 - 5 defense = 3 effective damage → 47 HP.
      expect(monster.stats.currentHp, 47);
    });

    test('defense cannot reduce damage below zero', () async {
      final (_, monster, _, _) = await mountedMonster(
        stats: defaultTestMonsterStats(maxHp: 50, defense: 20),
      );

      monster.receiveDamage(5);
      expect(monster.stats.currentHp, 50);
    });

    test('receiveDamage kills monster when HP reaches zero', () async {
      final (_, monster, _, _) = await mountedMonster(
        stats: defaultTestMonsterStats(maxHp: 30),
      );

      monster.receiveDamage(30);
      expect(monster.isDead, isTrue);
      expect(monster.deathCount, 1);
    });

    test('receiveDamage does nothing when already dead', () async {
      final (_, monster, _, _) = await mountedMonster(
        stats: defaultTestMonsterStats(maxHp: 30),
      );

      monster.receiveDamage(30);
      expect(monster.isDead, isTrue);

      // Should be no-op.
      monster.receiveDamage(10);
      expect(monster.deathCount, 1);
    });

    test('HP does not go below zero', () async {
      final (_, monster, _, _) = await mountedMonster(
        stats: defaultTestMonsterStats(maxHp: 20),
      );

      monster.receiveDamage(100);
      expect(monster.stats.currentHp, 0);
    });

    test('receiveDamage switches aggro to player', () async {
      final (_, monster, _, _) = await mountedMonster(
        stats: defaultTestMonsterStats(maxHp: 100),
      );

      expect(monster.targetMode, MonsterTargetMode.nexus);
      monster.receiveDamage(10);
      expect(monster.targetMode, MonsterTargetMode.player);
      expect(monster.aggroChangedCount, 1);
      expect(monster.lastAggroMode, MonsterTargetMode.player);
    });

    test('deathCallback is invoked on kill', () async {
      int callbackCount = 0;

      final game = await initializeGame(NexusSurvivor.new);
      final nexus = TestNexus(
        testStats: defaultTestNexusStats(maxHp: 500),
        testSize: Vector2(64, 64),
        testPosition: Vector2(-32, -32),
      );
      await game.ensureAdd(nexus);

      final monster = TestMonster(
        nexus: nexus,
        spawnPosition: Vector2(300, 0),
        testStats: defaultTestMonsterStats(maxHp: 10),
        deathCallback: () => callbackCount++,
      );
      await game.ensureAdd(monster);

      monster.receiveDamage(10);
      expect(callbackCount, 1);
    });

    test('aggro switches to player within aggroRange', () async {
      // Place the player at the origin, monster at 100 px distance.
      final (game, monster, _, character) = await mountedMonster(
        stats: defaultTestMonsterStats(aggroRange: 150, deaggroRange: 300),
        spawnPosition: Vector2(100, 0),
      );
      character.position.setFrom(Vector2.zero());

      // Tick so aggro logic runs — distance is 100, < 150 aggroRange.
      game.update(0.016);

      expect(monster.targetMode, MonsterTargetMode.player);
    });

    test('aggro switches back to nexus beyond deaggroRange', () async {
      final (game, monster, _, character) = await mountedMonster(
        stats: defaultTestMonsterStats(aggroRange: 50, deaggroRange: 100),
        spawnPosition: Vector2(60, 0),
      );
      character.position.setFrom(Vector2(40, 0));

      // Tick to trigger aggro (distance ~20, < 50).
      game.update(0.016);
      expect(monster.targetMode, MonsterTargetMode.player);

      // Move player far away.
      character.position.setFrom(Vector2(500, 0));
      game.update(0.016);
      expect(monster.targetMode, MonsterTargetMode.nexus);
    });

    test('moves toward nexus when targeting nexus', () async {
      // Spawn monster far to the right, nexus at origin.
      final (game, monster, _, _) = await mountedMonster(
        stats: defaultTestMonsterStats(speed: 100),
        spawnPosition: Vector2(500, 0),
        withPlayer: false,
      );

      final initialX = monster.position.x;
      game.update(0.5);
      // Monster should have moved left toward nexus.
      expect(monster.position.x, lessThan(initialX));
    });

    test('assert triggers for negative damage', () async {
      final (_, monster, _, _) = await mountedMonster();
      expect(() => monster.receiveDamage(-5), throwsA(isA<AssertionError>()));
    });
  });
}
