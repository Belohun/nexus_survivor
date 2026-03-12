import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:nexus_survivor/game/character/base/base_character_component.dart';
import 'package:nexus_survivor/game/monster/dev_monster.dart';
import 'package:nexus_survivor/game/nexus/base_nexus_component.dart';
import 'package:nexus_survivor/game/world/game_world.dart';

/// [DevSpawnButton] is a tap-able HUD button that spawns a single
/// [DevMonster] at a random position around the nexus.
///
/// Add this to `camera.viewport` so it renders as a fixed overlay.
class DevSpawnButton extends PositionComponent with TapCallbacks {
  /// Creates a [DevSpawnButton].
  ///
  /// [nexus], [player], and [gameWorld] are used to spawn and wire
  /// the monster. [spawnRadius] controls how far from the nexus the
  /// monsters appear.
  DevSpawnButton({
    required this.nexus,
    required this.player,
    required this.gameWorld,
    this.spawnRadius = 500,
  });

  /// The nexus component monsters will target.
  final BaseNexusComponent nexus;

  /// The player character.
  final BaseCharacterComponent player;

  /// The game world to add monsters to.
  final GameWorld gameWorld;

  /// Radius of the spawn circle centred on the nexus.
  final double spawnRadius;

  final Random _rng = Random();

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(120, 40);
    // Position in the top-right area of the viewport.
    position = Vector2(10, 10);
    anchor = Anchor.topLeft;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Button background.
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      const Radius.circular(8),
    );
    canvas.drawRRect(rrect, _bgPaint);
    canvas.drawRRect(rrect, _borderPaint);

    // Button label.
    final paragraphBuilder =
        ParagraphBuilder(
            ParagraphStyle(textAlign: TextAlign.center, fontSize: 12),
          )
          ..pushStyle(TextStyle(color: const Color(0xFFFFFFFF)))
          ..addText('Spawn Monster');

    final paragraph = paragraphBuilder.build()
      ..layout(ParagraphConstraints(width: size.x));

    canvas.drawParagraph(paragraph, Offset(0, (size.y - 14) / 2));
  }

  @override
  void onTapUp(TapUpEvent event) {
    final angle = _rng.nextDouble() * 2 * pi;
    final spawnPos =
        nexus.center +
        Vector2(cos(angle) * spawnRadius, sin(angle) * spawnRadius);

    final monster = DevMonster(
      nexus: nexus,
      spawnPosition: spawnPos,
      player: player,
    );

    gameWorld.add(monster);
  }

  //#region Paint objects

  static final Paint _bgPaint = Paint()..color = const Color(0xAA333333);

  static final Paint _borderPaint = Paint()
    ..color = const Color(0xFFE53935)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  //#endregion
}
