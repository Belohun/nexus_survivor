import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:nexus_survivor/game/dev_nexus_survivor.dart';

/// [GamePage] is the top-level widget that hosts the Flame game.
class GamePage extends StatelessWidget {
  /// Creates a [GamePage].
  const GamePage({super.key});

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: GameWidget(game: DevNexusSurvivor()),
  );
}
