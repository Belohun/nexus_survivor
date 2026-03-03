import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_survivor/game/character/base/base_character_component.dart';
import 'package:nexus_survivor/game/character/base/character_state.dart';
import 'package:nexus_survivor/game/character/base/character_stats.dart';
import 'package:nexus_survivor/game/controller/player_controller.dart';
import 'package:nexus_survivor/game/nexus_survivor.dart';
import 'package:nexus_survivor/game/skill/base_skill.dart';
import 'package:nexus_survivor/game/skill/skill_manager.dart';

import '../../helpers/test_character.dart';

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

/// Creates a [KeyDownEvent] for the given [key].
KeyDownEvent _keyDown(LogicalKeyboardKey key) {
  return KeyDownEvent(
    logicalKey: key,
    physicalKey: _logicalToPhysical[key] ?? PhysicalKeyboardKey.keyA,
    timeStamp: Duration.zero,
  );
}

/// Creates a [KeyUpEvent] for the given [key].
KeyUpEvent _keyUp(LogicalKeyboardKey key) {
  return KeyUpEvent(
    logicalKey: key,
    physicalKey: _logicalToPhysical[key] ?? PhysicalKeyboardKey.keyA,
    timeStamp: Duration.zero,
  );
}

/// Maps logical keys used in tests to physical keys.
final _logicalToPhysical = {
  LogicalKeyboardKey.keyW: PhysicalKeyboardKey.keyW,
  LogicalKeyboardKey.keyA: PhysicalKeyboardKey.keyA,
  LogicalKeyboardKey.keyS: PhysicalKeyboardKey.keyS,
  LogicalKeyboardKey.keyD: PhysicalKeyboardKey.keyD,
  LogicalKeyboardKey.arrowUp: PhysicalKeyboardKey.arrowUp,
  LogicalKeyboardKey.arrowDown: PhysicalKeyboardKey.arrowDown,
  LogicalKeyboardKey.arrowLeft: PhysicalKeyboardKey.arrowLeft,
  LogicalKeyboardKey.arrowRight: PhysicalKeyboardKey.arrowRight,
  LogicalKeyboardKey.space: PhysicalKeyboardKey.space,
  LogicalKeyboardKey.shiftLeft: PhysicalKeyboardKey.shiftLeft,
  LogicalKeyboardKey.keyQ: PhysicalKeyboardKey.keyQ,
  LogicalKeyboardKey.keyE: PhysicalKeyboardKey.keyE,
  LogicalKeyboardKey.keyR: PhysicalKeyboardKey.keyR,
};

void main() {
  group('PlayerController', () {
    /// Helper that sets up a full game → character → controller pipeline.
    Future<void> withController({
      CharacterStats? stats,
      bool withSkillManager = false,
      List<BaseSkill>? skills,
      required Future<void> Function(
        NexusSurvivor game,
        TestCharacter character,
        PlayerController controller,
        SkillManager? skillManager,
      )
      testBody,
    }) async {
      final game = await initializeGame(NexusSurvivor.new);
      final character = TestCharacter(testStats: stats ?? defaultTestStats());
      await character.init();
      await game.ensureAdd(character);

      SkillManager? manager;
      if (withSkillManager) {
        manager = SkillManager(owner: character);
        if (skills != null) {
          for (var i = 0; i < skills.length && i < SkillManager.maxSlots; i++) {
            manager.equipSkill(i, skills[i]);
          }
        }
        await game.ensureAdd(manager);
      }

      final controller = PlayerController(
        character: character,
        skillManager: manager,
      );
      await game.ensureAdd(controller);

      try {
        await testBody(game, character, controller, manager);
      } finally {
        game.onRemove();
      }
    }

    //#region Movement via WASD

    test('W key moves character upward', () async {
      await withController(
        stats: defaultTestStats(speed: 100),
        testBody: (game, character, controller, _) async {
          controller.onKeyEvent(_keyDown(LogicalKeyboardKey.keyW), {
            LogicalKeyboardKey.keyW,
          });
          controller.update(0.016);

          expect(character.currentState, CharacterState.moving);
          expect(character.velocity.y, closeTo(-100, 0.1));
        },
      );
    });

    test('S key moves character downward', () async {
      await withController(
        stats: defaultTestStats(speed: 100),
        testBody: (game, character, controller, _) async {
          controller.onKeyEvent(_keyDown(LogicalKeyboardKey.keyS), {
            LogicalKeyboardKey.keyS,
          });
          controller.update(0.016);

          expect(character.velocity.y, closeTo(100, 0.1));
        },
      );
    });

    test('A key moves character left', () async {
      await withController(
        stats: defaultTestStats(speed: 100),
        testBody: (game, character, controller, _) async {
          controller.onKeyEvent(_keyDown(LogicalKeyboardKey.keyA), {
            LogicalKeyboardKey.keyA,
          });
          controller.update(0.016);

          expect(character.velocity.x, closeTo(-100, 0.1));
        },
      );
    });

    test('D key moves character right', () async {
      await withController(
        stats: defaultTestStats(speed: 100),
        testBody: (game, character, controller, _) async {
          controller.onKeyEvent(_keyDown(LogicalKeyboardKey.keyD), {
            LogicalKeyboardKey.keyD,
          });
          controller.update(0.016);

          expect(character.velocity.x, closeTo(100, 0.1));
        },
      );
    });

    test('diagonal WASD movement is normalised', () async {
      await withController(
        stats: defaultTestStats(speed: 100),
        testBody: (game, character, controller, _) async {
          controller.onKeyEvent(_keyDown(LogicalKeyboardKey.keyW), {
            LogicalKeyboardKey.keyW,
            LogicalKeyboardKey.keyD,
          });
          controller.update(0.016);

          expect(character.velocity.length, closeTo(100, 0.5));
        },
      );
    });

    test('releasing all movement keys transitions to idle', () async {
      await withController(
        testBody: (game, character, controller, _) async {
          // Press W.
          controller.onKeyEvent(_keyDown(LogicalKeyboardKey.keyW), {
            LogicalKeyboardKey.keyW,
          });
          controller.update(0.016);
          expect(character.currentState, CharacterState.moving);

          // Release W.
          controller.onKeyEvent(_keyUp(LogicalKeyboardKey.keyW), {});
          controller.update(0.016);
          expect(character.currentState, CharacterState.idle);
        },
      );
    });

    //#endregion

    //#region Aim via arrow keys

    test('arrow keys update aim direction', () async {
      await withController(
        testBody: (game, character, controller, _) async {
          // Aim left.
          controller.onKeyEvent(_keyDown(LogicalKeyboardKey.arrowLeft), {
            LogicalKeyboardKey.arrowLeft,
          });
          controller.update(0.016);

          // Now attack; target should be to the left.
          controller.onKeyEvent(_keyDown(LogicalKeyboardKey.space), {
            LogicalKeyboardKey.arrowLeft,
            LogicalKeyboardKey.space,
          });

          expect(character.attackCount, 1);
          // Attack target should be offset to the left from position.
          expect(character.lastAttackTarget!.x, lessThan(character.position.x));
        },
      );
    });

    test('aim direction persists when arrow keys are released', () async {
      await withController(
        testBody: (game, character, controller, _) async {
          // Aim up.
          controller.onKeyEvent(_keyDown(LogicalKeyboardKey.arrowUp), {
            LogicalKeyboardKey.arrowUp,
          });
          controller.update(0.016);

          // Release arrow.
          controller.onKeyEvent(_keyUp(LogicalKeyboardKey.arrowUp), {});
          controller.update(0.016);

          // Attack — should still aim up.
          controller.onKeyEvent(_keyDown(LogicalKeyboardKey.space), {
            LogicalKeyboardKey.space,
          });

          expect(character.attackCount, 1);
          expect(character.lastAttackTarget!.y, lessThan(character.position.y));
        },
      );
    });

    //#endregion

    //#region Attack via Space

    test('space triggers basic attack', () async {
      await withController(
        testBody: (game, character, controller, _) async {
          controller.onKeyEvent(_keyDown(LogicalKeyboardKey.space), {
            LogicalKeyboardKey.space,
          });

          expect(character.attackCount, 1);
          expect(character.currentState, CharacterState.attacking);
        },
      );
    });

    test('space returns false to stop propagation', () async {
      await withController(
        testBody: (game, character, controller, _) async {
          final result = controller.onKeyEvent(
            _keyDown(LogicalKeyboardKey.space),
            {LogicalKeyboardKey.space},
          );

          expect(result, isFalse);
        },
      );
    });

    test('key repeat (KeyRepeatEvent) does not re-trigger attack', () async {
      await withController(
        testBody: (game, character, controller, _) async {
          // First attack.
          controller.onKeyEvent(_keyDown(LogicalKeyboardKey.space), {
            LogicalKeyboardKey.space,
          });
          expect(character.attackCount, 1);

          // Simulate key repeat (not KeyDownEvent).
          final repeatEvent = KeyRepeatEvent(
            logicalKey: LogicalKeyboardKey.space,
            physicalKey: PhysicalKeyboardKey.space,
            timeStamp: Duration.zero,
          );
          controller.onKeyEvent(repeatEvent, {LogicalKeyboardKey.space});
          // Should not fire again because KeyRepeatEvent is not
          // KeyDownEvent.
          expect(character.attackCount, 1);
        },
      );
    });

    //#endregion

    //#region Dash via Left Shift

    test('left shift triggers dash', () async {
      await withController(
        testBody: (game, character, controller, _) async {
          controller.onKeyEvent(_keyDown(LogicalKeyboardKey.shiftLeft), {
            LogicalKeyboardKey.shiftLeft,
          });

          expect(character.currentState, CharacterState.dashing);
          expect(character.isDashing, isTrue);
        },
      );
    });

    test('dash uses movement direction when WASD held', () async {
      await withController(
        stats: defaultTestStats(speed: 100, dashSpeedMultiplier: 2.0),
        testBody: (game, character, controller, _) async {
          // Hold D (moving right).
          controller.onKeyEvent(_keyDown(LogicalKeyboardKey.keyD), {
            LogicalKeyboardKey.keyD,
          });
          controller.update(0.016);

          // Now dash while D is still held.
          controller.onKeyEvent(_keyDown(LogicalKeyboardKey.shiftLeft), {
            LogicalKeyboardKey.keyD,
            LogicalKeyboardKey.shiftLeft,
          });

          // Velocity should be pointing right at boosted speed.
          expect(character.velocity.x, greaterThan(0));
        },
      );
    });

    test('dash falls back to aim direction when no WASD held', () async {
      await withController(
        testBody: (game, character, controller, _) async {
          // Aim left.
          controller.onKeyEvent(_keyDown(LogicalKeyboardKey.arrowLeft), {
            LogicalKeyboardKey.arrowLeft,
          });
          controller.update(0.016);

          // Release arrow, then dash (no WASD held).
          controller.onKeyEvent(_keyUp(LogicalKeyboardKey.arrowLeft), {});
          controller.onKeyEvent(_keyDown(LogicalKeyboardKey.shiftLeft), {
            LogicalKeyboardKey.shiftLeft,
          });

          // Velocity should point left.
          expect(character.velocity.x, lessThan(0));
        },
      );
    });

    test('left shift returns false to stop propagation', () async {
      await withController(
        testBody: (game, character, controller, _) async {
          final result = controller.onKeyEvent(
            _keyDown(LogicalKeyboardKey.shiftLeft),
            {LogicalKeyboardKey.shiftLeft},
          );

          expect(result, isFalse);
        },
      );
    });

    //#endregion

    //#region Skill activation via Q / E / R

    test('Q activates skill slot 0', () async {
      final skill = _TestSkill(name: 'A', cooldown: 1.0);

      await withController(
        withSkillManager: true,
        skills: [skill],
        testBody: (game, character, controller, manager) async {
          controller.onKeyEvent(_keyDown(LogicalKeyboardKey.keyQ), {
            LogicalKeyboardKey.keyQ,
          });

          expect(skill.executeCount, 1);
        },
      );
    });

    test('E activates skill slot 1', () async {
      final skill = _TestSkill(name: 'B', cooldown: 1.0);

      await withController(
        withSkillManager: true,
        skills: [
          _TestSkill(name: 'A', cooldown: 1.0),
          skill,
        ],
        testBody: (game, character, controller, manager) async {
          controller.onKeyEvent(_keyDown(LogicalKeyboardKey.keyE), {
            LogicalKeyboardKey.keyE,
          });

          expect(skill.executeCount, 1);
        },
      );
    });

    test('R activates skill slot 2', () async {
      final skill = _TestSkill(name: 'C', cooldown: 1.0);

      await withController(
        withSkillManager: true,
        skills: [
          _TestSkill(name: 'A', cooldown: 1.0),
          _TestSkill(name: 'B', cooldown: 1.0),
          skill,
        ],
        testBody: (game, character, controller, manager) async {
          controller.onKeyEvent(_keyDown(LogicalKeyboardKey.keyR), {
            LogicalKeyboardKey.keyR,
          });

          expect(skill.executeCount, 1);
        },
      );
    });

    test('skill key returns false to stop propagation', () async {
      await withController(
        withSkillManager: true,
        skills: [_TestSkill(name: 'A', cooldown: 1.0)],
        testBody: (game, character, controller, manager) async {
          final result = controller.onKeyEvent(
            _keyDown(LogicalKeyboardKey.keyQ),
            {LogicalKeyboardKey.keyQ},
          );

          expect(result, isFalse);
        },
      );
    });

    test('skill keys are no-op without a skill manager', () async {
      await withController(
        withSkillManager: false,
        testBody: (game, character, controller, _) async {
          // Should not throw.
          controller.onKeyEvent(_keyDown(LogicalKeyboardKey.keyQ), {
            LogicalKeyboardKey.keyQ,
          });
          controller.onKeyEvent(_keyDown(LogicalKeyboardKey.keyE), {
            LogicalKeyboardKey.keyE,
          });
          controller.onKeyEvent(_keyDown(LogicalKeyboardKey.keyR), {
            LogicalKeyboardKey.keyR,
          });
        },
      );
    });

    test('skill uses current aim direction', () async {
      final skill = _TestSkill(name: 'A', cooldown: 1.0);

      await withController(
        withSkillManager: true,
        skills: [skill],
        testBody: (game, character, controller, manager) async {
          // Aim up.
          controller.onKeyEvent(_keyDown(LogicalKeyboardKey.arrowUp), {
            LogicalKeyboardKey.arrowUp,
          });
          controller.update(0.016);

          // Activate skill.
          controller.onKeyEvent(_keyDown(LogicalKeyboardKey.keyQ), {
            LogicalKeyboardKey.arrowUp,
            LogicalKeyboardKey.keyQ,
          });

          expect(skill.lastAimDirection!.y, closeTo(-1, 0.01));
        },
      );
    });

    //#endregion

    //#region Unhandled keys

    test('unhandled keys return true for propagation', () async {
      await withController(
        testBody: (game, character, controller, _) async {
          final result = controller.onKeyEvent(
            _keyDown(LogicalKeyboardKey.escape),
            {LogicalKeyboardKey.escape},
          );

          expect(result, isTrue);
        },
      );
    });

    //#endregion
  });
}
