import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_survivor/game/character/base/base_character_component.dart';
import 'package:nexus_survivor/game/skill/base_skill.dart';
import 'package:nexus_survivor/game/skill/skill_manager.dart';

import '../../helpers/game_helpers.dart';

/// Concrete test skill that records invocations.
class _TestSkill extends BaseSkill {
  _TestSkill({required super.name, required super.cooldown});

  int executeCount = 0;
  Vector2? lastAimDirection;

  @override
  void execute(BaseCharacterComponent owner, Vector2 aimDirection) {
    executeCount++;
    lastAimDirection = aimDirection.clone();
  }
}

void main() {
  group('SkillManager', () {
    //#region Slot basics

    test('all slots start empty', () async {
      await withMountedCharacter(
        testBody: (game, character) async {
          final manager = SkillManager(owner: character);

          for (var i = 0; i < SkillManager.maxSlots; i++) {
            expect(manager.getSkill(i), isNull);
          }
          expect(manager.skills.length, SkillManager.maxSlots);
        },
      );
    });

    test('equipSkill places skill in the given slot', () async {
      await withMountedCharacter(
        testBody: (game, character) async {
          final manager = SkillManager(owner: character);
          final skill = _TestSkill(name: 'A', cooldown: 1.0);

          manager.equipSkill(0, skill);

          expect(manager.getSkill(0), same(skill));
          expect(manager.getSkill(1), isNull);
          expect(manager.getSkill(2), isNull);
        },
      );
    });

    test('equipSkill replaces an existing skill', () async {
      await withMountedCharacter(
        testBody: (game, character) async {
          final manager = SkillManager(owner: character);
          final first = _TestSkill(name: 'A', cooldown: 1.0);
          final second = _TestSkill(name: 'B', cooldown: 2.0);

          manager.equipSkill(1, first);
          manager.equipSkill(1, second);

          expect(manager.getSkill(1), same(second));
        },
      );
    });

    test('removeSkill returns and clears the slot', () async {
      await withMountedCharacter(
        testBody: (game, character) async {
          final manager = SkillManager(owner: character);
          final skill = _TestSkill(name: 'A', cooldown: 1.0);

          manager.equipSkill(2, skill);
          final removed = manager.removeSkill(2);

          expect(removed, same(skill));
          expect(manager.getSkill(2), isNull);
        },
      );
    });

    test('removeSkill returns null for an empty slot', () async {
      await withMountedCharacter(
        testBody: (game, character) async {
          final manager = SkillManager(owner: character);

          expect(manager.removeSkill(0), isNull);
        },
      );
    });

    test('skills getter returns unmodifiable view', () async {
      await withMountedCharacter(
        testBody: (game, character) async {
          final manager = SkillManager(owner: character);

          expect(
            () => manager.skills[0] = _TestSkill(name: 'X', cooldown: 0),
            throwsA(isA<UnsupportedError>()),
          );
        },
      );
    });

    //#endregion

    //#region Asserts on slot indices

    test('getSkill asserts on negative index', () async {
      await withMountedCharacter(
        testBody: (game, character) async {
          final manager = SkillManager(owner: character);

          expect(
            () => manager.getSkill(-1),
            failsAssert(
              'Slot index out of range: -1 (must be 0–${SkillManager.maxSlots - 1})',
            ),
          );
        },
      );
    });

    test('getSkill asserts on index >= maxSlots', () async {
      await withMountedCharacter(
        testBody: (game, character) async {
          final manager = SkillManager(owner: character);

          expect(
            () => manager.getSkill(SkillManager.maxSlots),
            failsAssert(
              'Slot index out of range: ${SkillManager.maxSlots} '
              '(must be 0–${SkillManager.maxSlots - 1})',
            ),
          );
        },
      );
    });

    test('equipSkill asserts on negative index', () async {
      await withMountedCharacter(
        testBody: (game, character) async {
          final manager = SkillManager(owner: character);

          expect(
            () => manager.equipSkill(-1, _TestSkill(name: 'X', cooldown: 0)),
            failsAssert(
              'Slot index out of range: -1 (must be 0–${SkillManager.maxSlots - 1})',
            ),
          );
        },
      );
    });

    test('removeSkill asserts on out-of-range index', () async {
      await withMountedCharacter(
        testBody: (game, character) async {
          final manager = SkillManager(owner: character);

          expect(
            () => manager.removeSkill(3),
            failsAssert(
              'Slot index out of range: 3 (must be 0–${SkillManager.maxSlots - 1})',
            ),
          );
        },
      );
    });

    test('activateSkill asserts on out-of-range index', () async {
      await withMountedCharacter(
        testBody: (game, character) async {
          final manager = SkillManager(owner: character);

          expect(
            () => manager.activateSkill(-1, Vector2.zero()),
            failsAssert(
              'Slot index out of range: -1 (must be 0–${SkillManager.maxSlots - 1})',
            ),
          );
        },
      );
    });

    //#endregion

    //#region activateSkill

    test('activateSkill fires the equipped skill', () async {
      await withMountedCharacter(
        testBody: (game, character) async {
          final manager = SkillManager(owner: character);
          final skill = _TestSkill(name: 'Bolt', cooldown: 1.0);
          manager.equipSkill(0, skill);

          final result = manager.activateSkill(0, Vector2(1, 0));

          expect(result, isTrue);
          expect(skill.executeCount, 1);
          expect(skill.lastAimDirection, Vector2(1, 0));
        },
      );
    });

    test('activateSkill returns false for empty slot', () async {
      await withMountedCharacter(
        testBody: (game, character) async {
          final manager = SkillManager(owner: character);

          final result = manager.activateSkill(0, Vector2(1, 0));

          expect(result, isFalse);
        },
      );
    });

    test('activateSkill returns false while skill is on cooldown', () async {
      await withMountedCharacter(
        testBody: (game, character) async {
          final manager = SkillManager(owner: character);
          final skill = _TestSkill(name: 'Bolt', cooldown: 2.0);
          manager.equipSkill(0, skill);

          manager.activateSkill(0, Vector2.zero());
          final second = manager.activateSkill(0, Vector2.zero());

          expect(second, isFalse);
          expect(skill.executeCount, 1);
        },
      );
    });

    //#endregion

    //#region update ticks cooldowns

    test('update ticks all equipped skill cooldowns', () async {
      await withMountedCharacter(
        testBody: (game, character) async {
          final manager = SkillManager(owner: character);

          final skill0 = _TestSkill(name: 'A', cooldown: 1.0);
          final skill1 = _TestSkill(name: 'B', cooldown: 2.0);
          manager.equipSkill(0, skill0);
          manager.equipSkill(1, skill1);

          // Activate both.
          manager.activateSkill(0, Vector2.zero());
          manager.activateSkill(1, Vector2.zero());

          expect(skill0.isReady, isFalse);
          expect(skill1.isReady, isFalse);

          // Simulate adding to the game tree so update runs.
          await game.ensureAdd(manager);
          game.update(1.0);

          expect(skill0.isReady, isTrue);
          expect(skill1.isReady, isFalse);
          expect(skill1.cooldownRemaining, closeTo(1.0, 0.001));

          game.update(1.0);
          expect(skill1.isReady, isTrue);
        },
      );
    });

    test('update handles null skill slots gracefully', () async {
      await withMountedCharacter(
        testBody: (game, character) async {
          final manager = SkillManager(owner: character);
          await game.ensureAdd(manager);

          // Should not throw even with all slots empty.
          expect(() => game.update(1.0), returnsNormally);
        },
      );
    });

    //#endregion
  });
}
