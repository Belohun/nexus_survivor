import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_survivor/game/character/base/character_state.dart';
import 'package:nexus_survivor/game/character/base/character_stats.dart';
import 'package:nexus_survivor/game/nexus_survivor.dart';
import 'package:nexus_survivor/game/weapon/base_weapon.dart';

import '../../helpers/game_helpers.dart';
import '../../helpers/test_character.dart';
import '../../helpers/test_nexus.dart';

/// A minimal concrete [BaseWeapon] for attack-cooldown tests.
class _TestWeapon extends BaseWeapon {
  _TestWeapon({super.baseCooldown});

  int fireCount = 0;

  @override
  void onFire() {
    fireCount++;
  }
}

void main() {
  group('BaseCharacterComponent', () {
    //#region Lifecycle & initial state

    test('starts in idle state with full HP', () async {
      await withMountedCharacter(
        testBody: (game, character) async {
          expect(character.currentState, CharacterState.idle);
          expect(character.stats.currentHp, character.stats.maxHp);
          expect(character.isAlive, isTrue);
          expect(character.isLocked, isFalse);
          expect(character.velocity, Vector2.zero());
        },
      );
    });

    test('stats are a copy of baseStats', () async {
      final stats = defaultTestStats(maxHp: 50, damage: 7);
      await withMountedCharacter(
        stats: stats,
        testBody: (game, character) async {
          expect(character.stats.maxHp, 50);
          expect(character.stats.damage, 7);

          // Mutating live stats should not affect the original.
          character.stats.damage = 99;
          expect(stats.damage, 7);
        },
      );
    });

    //#endregion

    //#region Movement

    test('move sets velocity and transitions to moving', () async {
      await withMountedCharacter(
        testBody: (game, character) async {
          character.move(Vector2(1, 0), 0.016);

          expect(character.currentState, CharacterState.moving);
          expect(character.velocity.x, closeTo(200, 0.1));
          expect(character.velocity.y, closeTo(0, 0.1));
          expect(character.facingDirection, Direction.right);
        },
      );
    });

    test('move with zero direction transitions to idle', () async {
      await withMountedCharacter(
        testBody: (game, character) async {
          // First move so we are in moving state.
          character.move(Vector2(1, 0), 0.016);
          expect(character.currentState, CharacterState.moving);

          character.move(Vector2.zero(), 0.016);
          expect(character.currentState, CharacterState.idle);
        },
      );
    });

    test('diagonal movement is normalised', () async {
      await withMountedCharacter(
        stats: defaultTestStats(speed: 100),
        testBody: (game, character) async {
          character.move(Vector2(1, 1), 0.016);

          // Magnitude should be speed (100), not speed * sqrt(2).
          expect(character.velocity.length, closeTo(100, 0.1));
        },
      );
    });

    test('move is ignored when character is locked', () async {
      await withMountedCharacter(
        testBody: (game, character) async {
          character.stun(5.0);
          expect(character.isLocked, isTrue);

          character.move(Vector2(1, 0), 0.016);

          // Should still be stunned, not moving.
          expect(character.currentState, CharacterState.stunned);
        },
      );
    });

    test('position updates when velocity is applied', () async {
      await withMountedCharacter(
        stats: defaultTestStats(speed: 100),
        testBody: (game, character) async {
          final startX = character.position.x;
          character.move(Vector2(1, 0), 0.016);

          // Simulate one game frame.
          game.update(1.0);

          expect(character.position.x, greaterThan(startX));
        },
      );
    });

    //#endregion

    //#region Attack

    test('attack transitions to attacking and calls onAttack', () async {
      await withMountedCharacter(
        testBody: (game, character) async {
          final weapon = _TestWeapon();
          character.weapon = weapon;
          game.update(0);
          await game.ready();

          final result = character.attack(Vector2(100, 0));

          expect(result, isTrue);
          expect(character.currentState, CharacterState.attacking);
          expect(character.attackCount, 1);
          expect(character.lastAttackTarget, Vector2(100, 0));
        },
      );
    });

    test('attack respects cooldown', () async {
      await withMountedCharacter(
        testBody: (game, character) async {
          final weapon = _TestWeapon(baseCooldown: 1.0);
          character.weapon = weapon;
          game.update(0);
          await game.ready();

          character.attack(Vector2(1, 0));
          expect(character.canAttack, isFalse);

          final second = character.attack(Vector2(1, 0));
          expect(second, isFalse);
          expect(character.attackCount, 1);
        },
      );
    });

    test('attack becomes available after cooldown expires', () async {
      await withMountedCharacter(
        testBody: (game, character) async {
          final weapon = _TestWeapon(baseCooldown: 0.5);
          character.weapon = weapon;
          game.update(0);
          await game.ready();

          character.attack(Vector2(1, 0));
          expect(character.canAttack, isFalse);

          // Tick past the cooldown.
          game.update(0.6);

          expect(character.canAttack, isTrue);
        },
      );
    });

    test('attack fails when character is locked', () async {
      await withMountedCharacter(
        testBody: (game, character) async {
          final weapon = _TestWeapon();
          character.weapon = weapon;
          game.update(0);
          await game.ready();

          character.stun(5.0);

          final result = character.attack(Vector2(1, 0));

          expect(result, isFalse);
          expect(character.attackCount, 0);
        },
      );
    });

    //#endregion

    //#region Receive damage

    test('receiveDamage reduces HP and transitions to hit', () async {
      await withMountedCharacter(
        stats: defaultTestStats(maxHp: 100, defense: 0),
        testBody: (game, character) async {
          character.receiveDamage(30);

          expect(character.stats.currentHp, closeTo(70, 0.01));
          expect(character.currentState, CharacterState.hit);
          expect(character.damageReceivedCount, 1);
          expect(character.lastEffectiveDamage, closeTo(30, 0.01));
        },
      );
    });

    test('receiveDamage respects defense', () async {
      await withMountedCharacter(
        stats: defaultTestStats(maxHp: 100, defense: 10),
        testBody: (game, character) async {
          character.receiveDamage(25);

          // effective = 25 - 10 = 15
          expect(character.stats.currentHp, closeTo(85, 0.01));
          expect(character.lastEffectiveDamage, closeTo(15, 0.01));
        },
      );
    });

    test('receiveDamage does not go below zero effective', () async {
      await withMountedCharacter(
        stats: defaultTestStats(maxHp: 100, defense: 50),
        testBody: (game, character) async {
          character.receiveDamage(10);

          // defense > damage → effective = 0
          expect(character.stats.currentHp, closeTo(100, 0.01));
        },
      );
    });

    test('receiveDamage triggers death when HP reaches zero', () async {
      await withMountedCharacter(
        stats: defaultTestStats(maxHp: 50, defense: 0),
        testBody: (game, character) async {
          character.receiveDamage(50);

          expect(character.stats.currentHp, 0);
          expect(character.currentState, CharacterState.dying);
          expect(character.deathCount, 1);
        },
      );
    });

    test('receiveDamage is ignored while invincible', () async {
      await withMountedCharacter(
        stats: defaultTestStats(maxHp: 100, defense: 0),
        testBody: (game, character) async {
          character.receiveDamage(10);
          expect(character.isInvincible, isTrue);

          // Let the hit state resolve so we can receive another hit.
          // But invincibility should block it.
          character.receiveDamage(10);

          // Only the first damage should have applied.
          expect(character.damageReceivedCount, 1);
          expect(character.stats.currentHp, closeTo(90, 0.01));
        },
      );
    });

    test('receiveDamage is ignored when dead', () async {
      await withMountedCharacter(
        stats: defaultTestStats(maxHp: 20, defense: 0),
        testBody: (game, character) async {
          character.receiveDamage(20); // kills character
          expect(character.currentState, CharacterState.dying);

          character.receiveDamage(10); // should be ignored

          expect(character.stats.currentHp, 0);
        },
      );
    });

    test('receiveDamage applies knockback when direction given', () async {
      await withMountedCharacter(
        stats: defaultTestStats(maxHp: 100, defense: 0),
        testBody: (game, character) async {
          final startPos = character.position.clone();
          character.receiveDamage(10, knockbackDirection: Vector2(1, 0));

          // Velocity should be set by knockback.
          expect(character.velocity.x, greaterThan(0));

          game.update(0.1);
          expect(character.position.x, greaterThan(startPos.x));
        },
      );
    });

    //#endregion

    //#region Dash

    test('dash transitions to dashing and applies speed boost', () async {
      await withMountedCharacter(
        stats: defaultTestStats(
          speed: 100,
          dashSpeedMultiplier: 3.0,
          dashDuration: 0.2,
          dashCooldown: 1.0,
        ),
        testBody: (game, character) async {
          final result = character.dash(Vector2(1, 0));

          expect(result, isTrue);
          expect(character.currentState, CharacterState.dashing);
          expect(character.isDashing, isTrue);
          expect(character.isInvincible, isTrue);
          expect(character.velocity.x, closeTo(300, 0.1));
        },
      );
    });

    test('dash respects cooldown', () async {
      await withMountedCharacter(
        stats: defaultTestStats(dashCooldown: 2.0, dashDuration: 0.1),
        testBody: (game, character) async {
          character.dash(Vector2(1, 0));
          expect(character.canDash, isFalse);

          // Tick past dash duration but not cooldown.
          game.update(0.5);

          expect(character.canDash, isFalse);

          final second = character.dash(Vector2(1, 0));
          expect(second, isFalse);
        },
      );
    });

    test('dash uses facing direction when given zero vector', () async {
      await withMountedCharacter(
        stats: defaultTestStats(speed: 100, dashSpeedMultiplier: 2.0),
        testBody: (game, character) async {
          // Face left first.
          character.move(Vector2(-1, 0), 0.016);
          game.update(0.016);

          // Now dash with zero direction.
          character.dash(Vector2.zero());

          // Should dash left (facing direction).
          expect(character.velocity.x, lessThan(0));
        },
      );
    });

    test('dash fails when character is locked', () async {
      await withMountedCharacter(
        testBody: (game, character) async {
          character.stun(5.0);

          final result = character.dash(Vector2(1, 0));
          expect(result, isFalse);
        },
      );
    });

    test('dash ends and returns to idle after duration', () async {
      await withMountedCharacter(
        stats: defaultTestStats(dashDuration: 0.2, dashCooldown: 1.0),
        testBody: (game, character) async {
          character.dash(Vector2(1, 0));
          expect(character.currentState, CharacterState.dashing);

          game.update(0.3); // past dash duration

          expect(character.isDashing, isFalse);
          expect(character.currentState, CharacterState.idle);
        },
      );
    });

    //#endregion

    //#region Stun

    test('stun transitions to stunned and locks character', () async {
      await withMountedCharacter(
        testBody: (game, character) async {
          character.stun(1.0);

          expect(character.currentState, CharacterState.stunned);
          expect(character.isLocked, isTrue);
          expect(character.velocity, Vector2.zero());
        },
      );
    });

    test('stun expires and returns to idle', () async {
      await withMountedCharacter(
        testBody: (game, character) async {
          character.stun(0.5);

          game.update(0.6);

          expect(character.currentState, CharacterState.idle);
          expect(character.isLocked, isFalse);
        },
      );
    });

    test('stun asserts on non-positive duration', () {
      expect(() async {
        await withMountedCharacter(
          testBody: (game, character) async {
            character.stun(0);
          },
        );
      }, failsAssert('Stun duration must be positive: 0.0'));
    });

    test('stun is ignored when dead', () async {
      await withMountedCharacter(
        stats: defaultTestStats(maxHp: 10, defense: 0),
        testBody: (game, character) async {
          character.receiveDamage(10); // kill
          expect(character.currentState, CharacterState.dying);

          character.stun(1.0);
          expect(character.currentState, CharacterState.dying);
        },
      );
    });

    //#endregion

    //#region Death

    test('die transitions to dying and calls onDeath', () async {
      await withMountedCharacter(
        testBody: (game, character) async {
          character.die();

          expect(character.currentState, CharacterState.dying);
          expect(character.deathCount, 1);
          expect(character.velocity, Vector2.zero());
        },
      );
    });

    test('dead character stops updating position', () async {
      await withMountedCharacter(
        testBody: (game, character) async {
          character.die();
          // Force to dead state for testing.
          game.update(100); // let dying anim finish → dead

          final pos = character.position.clone();
          game.update(1.0);
          expect(character.position, pos);
        },
      );
    });

    //#endregion

    //#region Healing

    test('heal restores HP up to maxHp', () async {
      await withMountedCharacter(
        stats: defaultTestStats(maxHp: 100, defense: 0),
        testBody: (game, character) async {
          character.receiveDamage(40);

          // Tick past invincibility to confirm HP.
          game.update(1.0);

          character.heal(20);
          expect(character.stats.currentHp, closeTo(80, 0.01));

          // Heal beyond max.
          character.heal(999);
          expect(character.stats.currentHp, closeTo(100, 0.01));
        },
      );
    });

    test('heal has no effect when dead', () async {
      await withMountedCharacter(
        stats: defaultTestStats(maxHp: 10, defense: 0),
        testBody: (game, character) async {
          character.receiveDamage(10);
          character.heal(50);

          expect(character.stats.currentHp, 0);
        },
      );
    });

    test('heal asserts on negative amount', () {
      expect(() async {
        await withMountedCharacter(
          testBody: (game, character) async {
            character.heal(-1);
          },
        );
      }, failsAssert('Heal amount must be non-negative: -1.0'));
    });

    //#endregion

    //#region XP / Leveling

    test('addXp increases currentXp', () async {
      await withMountedCharacter(
        testBody: (game, character) async {
          character.addXp(50);
          expect(character.stats.currentXp, 50);
        },
      );
    });

    test('addXp triggers level up when threshold is met', () async {
      await withMountedCharacter(
        testBody: (game, character) async {
          // Default xpToNextLevel is 100.
          character.addXp(100);

          expect(character.stats.level, 2);
          expect(character.lastLevelUp, 2);
          // Remainder XP should be 0.
          expect(character.stats.currentXp, 0);
        },
      );
    });

    test('addXp supports multiple level-ups in one call', () async {
      await withMountedCharacter(
        testBody: (game, character) async {
          // Give a huge amount of XP.
          character.addXp(10000);

          expect(character.stats.level, greaterThan(2));
          expect(character.lastLevelUp, character.stats.level);
        },
      );
    });

    test('addXp asserts on negative amount', () {
      expect(() async {
        await withMountedCharacter(
          testBody: (game, character) async {
            character.addXp(-1);
          },
        );
      }, failsAssert('XP amount must be non-negative: -1'));
    });

    //#endregion

    //#region Query helpers

    test('isInvincible is true during invincibility frames', () async {
      await withMountedCharacter(
        stats: CharacterStats(
          maxHp: 100,
          speed: 200,
          damage: 10,
          defense: 0,
          invincibilityDuration: 1.0,
        ),
        testBody: (game, character) async {
          expect(character.isInvincible, isFalse);
          character.receiveDamage(10);
          expect(character.isInvincible, isTrue);

          game.update(1.1);
          expect(character.isInvincible, isFalse);
        },
      );
    });

    test('canAttack reflects cooldown and lock state', () async {
      await withMountedCharacter(
        testBody: (game, character) async {
          final weapon = _TestWeapon(baseCooldown: 1.0);
          character.weapon = weapon;
          game.update(0);
          await game.ready();

          expect(character.canAttack, isTrue);

          character.attack(Vector2(1, 0));
          expect(character.canAttack, isFalse);

          game.update(1.1);
          expect(character.canAttack, isTrue);
        },
      );
    });

    test('canDash reflects cooldown and lock state', () async {
      await withMountedCharacter(
        stats: defaultTestStats(dashCooldown: 1.0, dashDuration: 0.1),
        testBody: (game, character) async {
          expect(character.canDash, isTrue);

          character.dash(Vector2(1, 0));
          expect(character.canDash, isFalse);

          game.update(1.5);
          expect(character.canDash, isTrue);
        },
      );
    });

    //#endregion

    //#region State transitions

    test('illegal state transitions are silently ignored', () async {
      await withMountedCharacter(
        testBody: (game, character) async {
          // From idle, cannot go directly to dead.
          character.die(); // goes to dying
          expect(character.currentState, CharacterState.dying);

          // Cannot go back to idle from dying.
          character.move(Vector2(1, 0), 0.016);
          expect(character.currentState, CharacterState.dying);
        },
      );
    });

    //#endregion

    //#region Sprite flipping

    test('facing left flips sprite horizontally', () async {
      await withMountedCharacter(
        testBody: (game, character) async {
          character.move(Vector2(-1, 0), 0.016);
          expect(character.facingDirection, Direction.left);
          expect(character.isFacingLeft, isTrue);
        },
      );
    });

    test('facing right un-flips sprite', () async {
      await withMountedCharacter(
        testBody: (game, character) async {
          character.move(Vector2(-1, 0), 0.016);
          expect(character.isFacingLeft, isTrue);

          character.move(Vector2(1, 0), 0.016);
          expect(character.isFacingLeft, isFalse);
        },
      );
    });

    //#endregion

    //#region Collision resolution

    group('collision with nexus', () {
      test('character cannot walk on top of the nexus', () async {
        final game = await initializeGame(NexusSurvivor.new);

        // Place a 64×64 nexus at the origin.
        final nexus = TestNexus(
          testStats: defaultTestNexusStats(maxHp: 100),
          testSize: Vector2.all(64),
          testPosition: Vector2.zero(),
        );
        await game.ensureAdd(nexus);

        // Place the character to the right of the nexus.
        final character = TestCharacter(
          testStats: defaultTestStats(speed: 200),
        );
        await character.init();
        character.position = Vector2(80, 32);
        await game.ensureAdd(character);

        // Move the character to the left, toward the nexus.
        for (var i = 0; i < 30; i++) {
          character.move(Vector2(-1, 0), 0.016);
          game.update(0.016);
        }

        // The character should not be inside the nexus.
        final charRect = character.toRect();
        final nexusRect = nexus.toRect();
        expect(
          charRect.overlaps(nexusRect),
          isFalse,
          reason: 'Character should be blocked by the nexus, not inside it',
        );

        game.onRemove();
      });

      test('character can slide along the nexus edge', () async {
        final game = await initializeGame(NexusSurvivor.new);

        // Place a 64×64 nexus at the origin.
        final nexus = TestNexus(
          testStats: defaultTestNexusStats(maxHp: 100),
          testSize: Vector2.all(64),
          testPosition: Vector2.zero(),
        );
        await game.ensureAdd(nexus);

        // Place the character just to the right of the nexus.
        final character = TestCharacter(
          testStats: defaultTestStats(speed: 200),
        );
        await character.init();
        character.position = Vector2(80, 32);
        await game.ensureAdd(character);

        final startY = character.position.y;

        // Move diagonally (left + down) into the nexus edge.
        // The character should slide along the Y axis.
        for (var i = 0; i < 20; i++) {
          character.move(Vector2(-1, 1).normalized(), 0.016);
          game.update(0.016);
        }

        // Y should have changed (sliding along the edge).
        expect(
          character.position.y,
          greaterThan(startY),
          reason: 'Character should slide vertically along the nexus edge',
        );

        game.onRemove();
      });

      test('character far from nexus is not affected', () async {
        final game = await initializeGame(NexusSurvivor.new);

        final nexus = TestNexus(
          testStats: defaultTestNexusStats(maxHp: 100),
          testSize: Vector2.all(64),
          testPosition: Vector2.zero(),
        );
        await game.ensureAdd(nexus);

        final character = TestCharacter(
          testStats: defaultTestStats(speed: 200),
        );
        await character.init();
        character.position = Vector2(500, 500);
        await game.ensureAdd(character);

        game.update(0.016);

        // Should remain at the same position.
        expect(character.position.x, closeTo(500, 0.1));
        expect(character.position.y, closeTo(500, 0.1));

        game.onRemove();
      });
    });

    //#endregion
  });

  //#region CharacterStats

  group('Direction', () {
    test('fromVector returns correct cardinal directions', () {
      expect(Direction.fromVector(1, 0), Direction.right);
      expect(Direction.fromVector(-1, 0), Direction.left);
      expect(Direction.fromVector(0, -1), Direction.up);
      expect(Direction.fromVector(0, 1), Direction.down);
    });

    test('fromVector returns correct diagonal directions', () {
      expect(Direction.fromVector(1, -1), Direction.upRight);
      expect(Direction.fromVector(-1, -1), Direction.upLeft);
      expect(Direction.fromVector(1, 1), Direction.downRight);
      expect(Direction.fromVector(-1, 1), Direction.downLeft);
    });

    test('fromVector returns none for zero input', () {
      expect(Direction.fromVector(0, 0), Direction.none);
    });

    test('isLeft is true for left-facing directions', () {
      expect(Direction.left.isLeft, isTrue);
      expect(Direction.upLeft.isLeft, isTrue);
      expect(Direction.downLeft.isLeft, isTrue);
      expect(Direction.right.isLeft, isFalse);
    });

    test('isRight is true for right-facing directions', () {
      expect(Direction.right.isRight, isTrue);
      expect(Direction.upRight.isRight, isTrue);
      expect(Direction.downRight.isRight, isTrue);
      expect(Direction.left.isRight, isFalse);
    });
  });

  //#endregion

  //#region CharacterStats

  group('CharacterStats', () {
    test('currentHp defaults to maxHp when omitted', () {
      final s = CharacterStats(maxHp: 80, speed: 100, damage: 10);
      expect(s.currentHp, 80);
    });

    test('isAlive reflects currentHp', () {
      final s = CharacterStats(maxHp: 10, speed: 100, damage: 5);
      expect(s.isAlive, isTrue);

      s.currentHp = 0;
      expect(s.isAlive, isFalse);
    });

    test('copyWith creates independent copy', () {
      final original = CharacterStats(maxHp: 100, speed: 200, damage: 10);
      final copy = original.copyWith(damage: 50);

      expect(copy.damage, 50);
      expect(copy.maxHp, 100);
      expect(original.damage, 10);
    });
  });

  //#endregion
}
