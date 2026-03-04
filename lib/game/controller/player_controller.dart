import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:nexus_survivor/game/character/base/base_character_component.dart';
import 'package:nexus_survivor/game/controller/movement_joystick.dart';
import 'package:nexus_survivor/game/nexus_survivor.dart';
import 'package:nexus_survivor/game/skill/skill_manager.dart';

/// [PlayerController] translates keyboard and mouse input into actions
/// on a [BaseCharacterComponent].
///
/// Console-style control scheme:
/// - **WASD** — 8-directional movement (left stick)
/// - **Arrow keys / Mouse** — aim direction (right stick)
/// - **Space** — basic attack in the current aim direction
/// - **Left Shift** — dash in the current movement or aim direction
/// - **Q / E / R** — activate skill slot 0, 1, 2 respectively
///
/// Add this component as a child of the game or the world. It must be
/// provided with a reference to the player's [BaseCharacterComponent]
/// and an optional [SkillManager].
class PlayerController extends Component
    with KeyboardHandler, HasGameReference<NexusSurvivor> {
  /// Creates a [PlayerController] bound to the given [character].
  ///
  /// When [skillManager] is provided, skill activation keys (Q/E/R)
  /// are enabled. When [movementJoystick] is provided, touch-based
  /// movement via the virtual joystick is enabled.
  PlayerController({
    required this.character,
    this.skillManager,
    this.movementJoystick,
  });

  /// The character this controller drives.
  final BaseCharacterComponent character;

  /// Optional skill manager for skill activation via Q/E/R.
  final SkillManager? skillManager;

  /// Optional virtual joystick for touch-based movement.
  final MovementJoystick? movementJoystick;

  //#region Private fields

  // Movement keys currently held.
  final Set<LogicalKeyboardKey> _pressedKeys = {};

  // Aim direction updated by arrow keys. Defaults to facing down.
  final Vector2 _aimDirection = Vector2(0, 1);

  // Whether arrow keys are actively providing aim input.
  bool _arrowAiming = false;

  /// Maps WASD keys to their movement contribution vectors.
  static final Map<LogicalKeyboardKey, Vector2> _moveKeyMap = {
    LogicalKeyboardKey.keyW: Vector2(0, -1),
    LogicalKeyboardKey.keyS: Vector2(0, 1),
    LogicalKeyboardKey.keyA: Vector2(-1, 0),
    LogicalKeyboardKey.keyD: Vector2(1, 0),
  };

  /// Maps arrow keys to their aim contribution vectors.
  static final Map<LogicalKeyboardKey, Vector2> _aimKeyMap = {
    LogicalKeyboardKey.arrowUp: Vector2(0, -1),
    LogicalKeyboardKey.arrowDown: Vector2(0, 1),
    LogicalKeyboardKey.arrowLeft: Vector2(-1, 0),
    LogicalKeyboardKey.arrowRight: Vector2(1, 0),
  };

  /// Maps skill keys to slot indices.
  static final Map<LogicalKeyboardKey, int> _skillKeyMap = {
    LogicalKeyboardKey.keyQ: 0,
    LogicalKeyboardKey.keyE: 1,
    LogicalKeyboardKey.keyR: 2,
  };

  //#endregion

  //#region Key handling

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    _pressedKeys
      ..clear()
      ..addAll(keysPressed);

    // Handle attack on key down.
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.space) {
        _performAttack();
        return false;
      }

      if (event.logicalKey == LogicalKeyboardKey.shiftLeft) {
        _performDash();
        return false;
      }

      // Skill activation.
      final skillSlot = _skillKeyMap[event.logicalKey];
      if (skillSlot != null) {
        _performSkill(skillSlot);
        return false;
      }
    }

    return true;
  }

  //#endregion

  //#region Update loop

  @override
  void update(double dt) {
    super.update(dt);

    _updateAimDirection();
    _updateMovement(dt);
  }

  //#endregion

  //#region Private helpers

  /// Builds a combined movement vector from currently held WASD keys
  /// or the virtual joystick and applies it to the character.
  ///
  /// Keyboard input takes priority when active. When no WASD keys are
  /// pressed the joystick direction is used instead.
  void _updateMovement(double dt) {
    final direction = Vector2.zero();

    for (final entry in _moveKeyMap.entries) {
      if (_pressedKeys.contains(entry.key)) {
        direction.add(entry.value);
      }
    }

    // Fall back to joystick input when no keyboard movement is active.
    if (direction.isZero() && movementJoystick != null) {
      direction.setFrom(movementJoystick!.movementDirection);
    }

    // Normalize diagonal movement so speed is consistent.
    if (direction.length > 1) {
      direction.normalize();
    }

    character.move(direction, dt);
  }

  /// Updates the aim direction from arrow keys. When no arrow key is
  /// pressed the last direction is retained so the player always has
  /// a valid aim.
  void _updateAimDirection() {
    final aim = Vector2.zero();
    _arrowAiming = false;

    for (final entry in _aimKeyMap.entries) {
      if (_pressedKeys.contains(entry.key)) {
        aim.add(entry.value);
        _arrowAiming = true;
      }
    }

    if (_arrowAiming && !aim.isZero()) {
      _aimDirection.setFrom(aim.normalized());
    }
  }

  /// Triggers a basic attack toward [_aimDirection].
  void _performAttack() {
    // Convert aim direction to a world-space target position relative
    // to the character.
    final target = character.position + _aimDirection * 100;
    character.attack(target);
  }

  /// Triggers a dash in the current movement direction, falling back
  /// to [_aimDirection].
  void _performDash() {
    final moveDir = _currentMoveDirection();
    character.dash(moveDir.isZero() ? _aimDirection : moveDir);
  }

  /// Activates the skill in the given [slot].
  void _performSkill(int slot) {
    skillManager?.activateSkill(slot, _aimDirection);
  }

  /// Returns the current raw movement vector from held WASD keys.
  Vector2 _currentMoveDirection() {
    final direction = Vector2.zero();
    for (final entry in _moveKeyMap.entries) {
      if (_pressedKeys.contains(entry.key)) {
        direction.add(entry.value);
      }
    }
    if (direction.length > 1) {
      direction.normalize();
    }
    return direction;
  }

  //#endregion
}
