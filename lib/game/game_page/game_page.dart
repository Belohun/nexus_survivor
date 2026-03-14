import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:nexus_survivor/game/character/base/character_type.dart';
import 'package:nexus_survivor/game/dev_nexus_survivor.dart';
import 'package:nexus_survivor/ui/pause/pause_overlay.dart';

/// [GamePage] is the top-level widget that hosts the Flame game.
///
/// Registers the pause-menu overlay so it can be activated from the
/// in-game [PauseButton]. The [characterType] determines which player
/// character and weapon combination is used.
class GamePage extends StatefulWidget {
  /// Creates a [GamePage] for the given [characterType].
  const GamePage({super.key, required this.characterType});

  /// The character variant selected by the player in the main menu.
  final CharacterType characterType;

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late final DevNexusSurvivor _game;

  @override
  void initState() {
    super.initState();
    _game = DevNexusSurvivor(characterType: widget.characterType);
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: GameWidget(
      game: _game,
      overlayBuilderMap: {
        pauseOverlayKey: (context, game) => PauseOverlay(
          game: game as Game,
          onExitToMenu: () => _exitToMainMenu(context),
        ),
      },
    ),
  );

  void _exitToMainMenu(BuildContext context) {
    _game.overlays.remove(pauseOverlayKey);
    _game.resumeEngine();
    Navigator.of(context).pop();
  }
}
