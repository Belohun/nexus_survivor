import 'package:flame_test/flame_test.dart';
import 'package:nexus_survivor/game/character/base/character_stats.dart';
import 'package:nexus_survivor/game/nexus_survivor.dart';

import 'test_character.dart';

/// Creates a [NexusSurvivor] game instance, adds a fully-initialised
/// [TestCharacter], then passes both to [testBody].
///
/// The character is initialised (placeholder animations) and mounted
/// before [testBody] is called.
Future<void> withMountedCharacter({
  CharacterStats? stats,
  required Future<void> Function(NexusSurvivor game, TestCharacter character)
  testBody,
}) async {
  final game = await initializeGame(NexusSurvivor.new);
  final character = TestCharacter(testStats: stats ?? defaultTestStats());
  await character.init();
  await game.ensureAdd(character);

  try {
    await testBody(game, character);
  } finally {
    game.onRemove();
  }
}
