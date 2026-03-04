import 'dart:ui';

import 'package:flame/components.dart';
import 'package:nexus_survivor/game/character/base/base_character_component.dart';
import 'package:nexus_survivor/game/character/base/character_state.dart';
import 'package:nexus_survivor/game/character/base/character_stats.dart';

/// [DevCharacter] is a concrete [BaseCharacterComponent] used during
/// development.
///
/// It renders as a simple coloured rectangle (no sprite assets required)
/// and provides default stats suitable for testing movement, dashing,
/// and attacking on a blank canvas.
class DevCharacter extends BaseCharacterComponent {
  /// Creates a [DevCharacter] at the given [initialPosition].
  ///
  /// Uses [devStats] when provided; otherwise falls back to sensible
  /// defaults.
  DevCharacter({Vector2? initialPosition, CharacterStats? devStats})
    : _devStats =
          devStats ?? CharacterStats(maxHp: 100, speed: 200, damage: 10),
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

  /// Creates a 32×32 cyan square sprite for visual debugging.
  Future<Sprite> _createPlaceholderSprite() async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 32, 32),
      Paint()..color = const Color(0xFF00BCD4),
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(32, 32);
    picture.dispose();
    return Sprite(image);
  }

  //#endregion
}
