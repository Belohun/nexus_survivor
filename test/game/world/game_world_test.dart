import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_survivor/game/nexus_survivor.dart';
import 'package:nexus_survivor/game/world/game_world.dart';

import '../../helpers/test_level.dart';

void main() {
  group('GameWorld', () {
    Future<(NexusSurvivor, GameWorld)> mountedWorld() async {
      final game = await initializeGame(NexusSurvivor.new);
      final world = GameWorld();
      await game.ensureAdd(world);
      return (game, world);
    }

    test('starts with no current level', () async {
      final (_, world) = await mountedWorld();

      expect(world.currentLevel, isNull);
    });

    test('loadLevel sets the current level', () async {
      final (game, world) = await mountedWorld();
      final level = TestLevel(config: defaultTestLevelConfig());

      await world.loadLevel(level);
      game.update(0);

      expect(world.currentLevel, level);
      expect(level.isMounted, isTrue);
    });

    test('loadLevel replaces the previous level', () async {
      final (game, world) = await mountedWorld();
      final level1 = TestLevel(config: defaultTestLevelConfig());
      final level2 = TestLevel(config: defaultTestLevelConfig(levelNumber: 2));

      await world.loadLevel(level1);
      game.update(0);
      await world.loadLevel(level2);
      game.update(0);

      expect(world.currentLevel, level2);
      expect(level2.isMounted, isTrue);
    });

    test('unloadLevel removes the current level', () async {
      final (game, world) = await mountedWorld();
      final level = TestLevel(config: defaultTestLevelConfig());

      await world.loadLevel(level);
      game.update(0);
      world.unloadLevel();

      expect(world.currentLevel, isNull);
    });

    test('unloadLevel is safe when no level is loaded', () async {
      final (_, world) = await mountedWorld();

      // Should not throw.
      world.unloadLevel();

      expect(world.currentLevel, isNull);
    });
  });
}
