import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_survivor/game/weapon/base_weapon.dart';

import '../../helpers/game_helpers.dart';

/// A minimal concrete [BaseWeapon] for testing within a character.
class _TestWeapon extends BaseWeapon {
  _TestWeapon({super.orbitRadius});

  int fireCount = 0;

  @override
  void onFire() {
    fireCount++;
  }
}

void main() {
  group('BaseCharacterComponent weapon integration', () {
    test('weapon is null by default', () async {
      await withMountedCharacter(
        testBody: (game, character) async {
          expect(character.weapon, isNull);
        },
      );
    });

    test('setting weapon adds it as a child', () async {
      await withMountedCharacter(
        testBody: (game, character) async {
          final weapon = _TestWeapon();
          character.weapon = weapon;

          // Pump one frame so the child is mounted.
          game.update(0);
          await game.ready();

          expect(character.weapon, weapon);
          expect(character.children.contains(weapon), isTrue);
        },
      );
    });

    test('replacing weapon removes previous one', () async {
      await withMountedCharacter(
        testBody: (game, character) async {
          final weapon1 = _TestWeapon();
          final weapon2 = _TestWeapon();

          character.weapon = weapon1;
          game.update(0);
          await game.ready();
          expect(character.children.contains(weapon1), isTrue);

          character.weapon = weapon2;
          game.update(0);
          await game.ready();

          expect(character.weapon, weapon2);
          expect(character.children.contains(weapon2), isTrue);
          // weapon1 should have been removed.
          expect(weapon1.isMounted, isFalse);
        },
      );
    });

    test('setting weapon to null removes it', () async {
      await withMountedCharacter(
        testBody: (game, character) async {
          final weapon = _TestWeapon();
          character.weapon = weapon;
          game.update(0);
          await game.ready();

          character.weapon = null;
          game.update(0);
          await game.ready();

          expect(character.weapon, isNull);
          expect(weapon.isMounted, isFalse);
        },
      );
    });

    test('aimDirection syncs to weapon each frame', () async {
      await withMountedCharacter(
        testBody: (game, character) async {
          final weapon = _TestWeapon();
          character.weapon = weapon;
          game.update(0);
          await game.ready();

          // Set aim direction to the right.
          character.aimDirection.setFrom(Vector2(1, 0));
          game.update(0.016);

          expect(weapon.aimAngle, closeTo(0, 0.001));

          // Aim down.
          character.aimDirection.setFrom(Vector2(0, 1));
          game.update(0.016);

          expect(weapon.aimAngle, closeTo(pi / 2, 0.001));
        },
      );
    });

    test('aimDirection defaults to facing down', () async {
      await withMountedCharacter(
        testBody: (game, character) async {
          expect(character.aimDirection.x, closeTo(0, 0.001));
          expect(character.aimDirection.y, closeTo(1, 0.001));
        },
      );
    });

    test('moving character does not change weapon aimAngle', () async {
      await withMountedCharacter(
        testBody: (game, character) async {
          final weapon = _TestWeapon();
          character.weapon = weapon;
          game.update(0);
          await game.ready();

          // Aim to the right and pump a frame to sync.
          character.aimDirection.setFrom(Vector2(1, 0));
          game.update(0.016);

          final angleBeforeMove = weapon.aimAngle;
          final posBeforeMove = weapon.position.clone();

          // Move left — this used to flip the character and mirror the
          // weapon's local coordinate space.
          character.move(Vector2(-1, 0), 0.016);
          game.update(0.016);

          expect(weapon.aimAngle, closeTo(angleBeforeMove, 0.001));
          expect(weapon.position.x, closeTo(posBeforeMove.x, 0.001));
          expect(weapon.position.y, closeTo(posBeforeMove.y, 0.001));

          // Move right — should also keep the weapon unchanged.
          character.move(Vector2(1, 0), 0.016);
          game.update(0.016);

          expect(weapon.aimAngle, closeTo(angleBeforeMove, 0.001));
          expect(weapon.position.x, closeTo(posBeforeMove.x, 0.001));
          expect(weapon.position.y, closeTo(posBeforeMove.y, 0.001));
        },
      );
    });

    test(
      'weapon stays on correct side after repeated direction changes',
      () async {
        await withMountedCharacter(
          testBody: (game, character) async {
            final weapon = _TestWeapon(orbitRadius: 30);
            character.weapon = weapon;
            game.update(0);
            await game.ready();

            // Aim to the right.
            character.aimDirection.setFrom(Vector2(1, 0));
            game.update(0.016);

            final expectedAngle = weapon.aimAngle;
            final expectedPos = weapon.position.clone();

            // Rapidly alternate movement direction to simulate the
            // scenario that previously caused a one-frame glitch.
            for (var i = 0; i < 10; i++) {
              final dir = i.isEven ? Vector2(-1, 0) : Vector2(1, 0);
              character.move(dir, 0.016);
              game.update(0.016);

              expect(
                weapon.aimAngle,
                closeTo(expectedAngle, 0.001),
                reason: 'aimAngle drifted on iteration $i',
              );
              expect(
                weapon.position.x,
                closeTo(expectedPos.x, 0.001),
                reason: 'position.x drifted on iteration $i',
              );
              expect(
                weapon.position.y,
                closeTo(expectedPos.y, 0.001),
                reason: 'position.y drifted on iteration $i',
              );
            }
          },
        );
      },
    );
  });
}
