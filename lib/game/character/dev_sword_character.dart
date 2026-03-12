import 'dart:ui';

import 'package:flame/components.dart';
import 'package:nexus_survivor/game/character/base/base_character_component.dart';
import 'package:nexus_survivor/game/character/base/character_state.dart';
import 'package:nexus_survivor/game/character/base/character_stats.dart';

/// [DevSwordCharacter] is a melee-oriented [BaseCharacterComponent] used
/// during development.
///
/// It renders as a magenta coloured rectangle (no sprite assets required)
/// and provides stats tuned for close-range combat — higher damage and
/// defense but lower speed compared to [DevCharacter].
class DevSwordCharacter extends BaseCharacterComponent {
  /// Creates a [DevSwordCharacter] at the given [initialPosition].
  ///
  /// Uses [devStats] when provided; otherwise falls back to melee-tuned
  /// defaults.
  DevSwordCharacter({Vector2? initialPosition, CharacterStats? devStats})
    : _devStats =
          devStats ??
          CharacterStats(
            maxHp: 150,
            speed: 160,
            damage: 20,
            defense: 5,
            attackCooldown: 0.4,
          ),
      _initialPosition = initialPosition ?? Vector2.zero();

  final CharacterStats _devStats;
  final Vector2 _initialPosition;

  late final Map<CharacterState, SpriteAnimation> _generatedAnimations;

  //#region BaseCharacterComponent contract

  @override
  CharacterStats get baseStats => _devStats;

  @override
  Map<CharacterState, SpriteAnimation> get animations => _generatedAnimations;

  //#endregion

  //#region Lifecycle

  @override
  Future<void> onLoad() async {
    final sprite = await _createPlaceholderSprite();
    final anim = SpriteAnimation.spriteList([sprite], stepTime: 1);
    _generatedAnimations = {
      for (final state in CharacterState.values) state: anim,
    };

    size = Vector2(32, 32);
    position = _initialPosition.clone();

    await super.onLoad();
  }

  //#endregion

  //#region Private helpers

  /// Creates a 32×32 magenta square sprite for visual debugging.
  Future<Sprite> _createPlaceholderSprite() async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 32, 32),
      Paint()..color = const Color(0xFFE91E63),
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(32, 32);
    picture.dispose();
    return Sprite(image);
  }

  //#endregion
}
