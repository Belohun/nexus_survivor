import 'package:flame/components.dart';
import 'package:nexus_survivor/game/character/base/base_character_component.dart';
import 'package:nexus_survivor/game/skill/base_skill.dart';

/// [SkillManager] manages a fixed set of skill slots for a character.
///
/// Attach it as a child of a [BaseCharacterComponent] to automatically
/// tick cooldowns each frame. The manager exposes three skill slots
/// (indices 0–2) that can be equipped and activated independently.
class SkillManager extends Component {
  /// Creates a [SkillManager] owned by the given [owner].
  SkillManager({required this.owner});

  /// The character that owns these skills.
  final BaseCharacterComponent owner;

  /// Maximum number of skill slots available.
  static const int maxSlots = 3;

  final List<BaseSkill?> _skills = List<BaseSkill?>.filled(maxSlots, null);

  /// Returns an unmodifiable view of the currently equipped skills.
  List<BaseSkill?> get skills => List<BaseSkill?>.unmodifiable(_skills);

  /// Returns the skill in the given [slot], or `null` if empty.
  BaseSkill? getSkill(int slot) {
    assert(
      slot >= 0 && slot < maxSlots,
      'Slot index out of range: $slot (must be 0–${maxSlots - 1})',
    );
    return _skills[slot];
  }

  /// Equips [skill] into the given [slot], replacing any existing skill.
  ///
  /// [slot] must be in the range 0–2.
  void equipSkill(int slot, BaseSkill skill) {
    assert(
      slot >= 0 && slot < maxSlots,
      'Slot index out of range: $slot (must be 0–${maxSlots - 1})',
    );
    _skills[slot] = skill;
  }

  /// Removes the skill from [slot] and returns it, or `null` if empty.
  BaseSkill? removeSkill(int slot) {
    assert(
      slot >= 0 && slot < maxSlots,
      'Slot index out of range: $slot (must be 0–${maxSlots - 1})',
    );
    final removed = _skills[slot];
    _skills[slot] = null;
    return removed;
  }

  /// Attempts to activate the skill in the given [slot] toward
  /// [aimDirection].
  ///
  /// Returns `true` when the skill fired successfully.
  bool activateSkill(int slot, Vector2 aimDirection) {
    assert(
      slot >= 0 && slot < maxSlots,
      'Slot index out of range: $slot (must be 0–${maxSlots - 1})',
    );
    final skill = _skills[slot];
    if (skill == null) return false;
    return skill.activate(owner, aimDirection);
  }

  @override
  void update(double dt) {
    super.update(dt);
    for (final skill in _skills) {
      skill?.update(dt);
    }
  }
}
