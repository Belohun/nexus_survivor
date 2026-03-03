import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:nexus_survivor/game/character/base/base_character_component.dart';
import 'package:nexus_survivor/game/character/base/character_state.dart';
import 'package:nexus_survivor/game/character/base/character_stats.dart';

/// A minimal concrete [BaseCharacterComponent] used in tests.
///
/// Requires [init] to be called before being added to a game so that
/// the placeholder animations can be built from an async [Image].
class TestCharacter extends BaseCharacterComponent {
  /// Creates a [TestCharacter] with the given [testStats].
  TestCharacter({required CharacterStats testStats}) : _testStats = testStats;

  final CharacterStats _testStats;

  /// The last target position received by [onAttack].
  Vector2? lastAttackTarget;

  /// Number of times [onAttack] was called.
  int attackCount = 0;

  /// Number of times [onDeath] was called.
  int deathCount = 0;

  /// Number of times [onDamageReceived] was called.
  int damageReceivedCount = 0;

  /// The last effective damage value passed to [onDamageReceived].
  double lastEffectiveDamage = 0;

  /// The last level passed to [onLevelUp].
  int lastLevelUp = 0;

  late final Map<CharacterState, SpriteAnimation> _cachedAnimations;

  /// Initialises placeholder animations from an async-generated image.
  ///
  /// Must be called **before** the component is added to the game tree.
  Future<void> init() async {
    final image = await generateImage();
    final anim = SpriteAnimation.spriteList([Sprite(image)], stepTime: 1);
    _cachedAnimations = {
      for (final state in CharacterState.values) state: anim,
    };
  }

  @override
  CharacterStats get baseStats => _testStats;

  @override
  Map<CharacterState, SpriteAnimation> get animations => _cachedAnimations;

  @override
  void onAttack(Vector2 target) {
    lastAttackTarget = target.clone();
    attackCount++;
  }

  @override
  void onDeath() {
    deathCount++;
  }

  @override
  void onDamageReceived(double effectiveDamage) {
    damageReceivedCount++;
    lastEffectiveDamage = effectiveDamage;
  }

  @override
  void onLevelUp(int newLevel) {
    lastLevelUp = newLevel;
  }
}

/// Creates default [CharacterStats] suitable for most tests.
CharacterStats defaultTestStats({
  double maxHp = 100,
  double speed = 200,
  double damage = 10,
  double defense = 0,
  double attackCooldown = 0.3,
  double dashCooldown = 1.0,
  double dashDuration = 0.2,
  double dashSpeedMultiplier = 2.5,
  double critChance = 0,
  double critMultiplier = 2.0,
}) {
  return CharacterStats(
    maxHp: maxHp,
    speed: speed,
    damage: damage,
    defense: defense,
    attackCooldown: attackCooldown,
    dashCooldown: dashCooldown,
    dashDuration: dashDuration,
    dashSpeedMultiplier: dashSpeedMultiplier,
    critChance: critChance,
    critMultiplier: critMultiplier,
  );
}
