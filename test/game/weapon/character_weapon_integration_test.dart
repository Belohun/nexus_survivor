import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_survivor/game/weapon/base_weapon.dart';

import '../../helpers/game_helpers.dart';

/// A minimal concrete [BaseWeapon] for testing within a character.
class _TestWeapon extends BaseWeapon {
  _TestWeapon();

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
  });
}
