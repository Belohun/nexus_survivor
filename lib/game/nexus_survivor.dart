import 'package:flame/events.dart';
import 'package:flame/game.dart';

/// [NexusSurvivor] is the top-level Flame game instance.
///
/// Mixes in [HasKeyboardHandlerComponents] so child components (such as
/// [PlayerController]) can receive keyboard events, and
/// [HasCollisionDetection] to enable the built-in collision system.
class NexusSurvivor extends FlameGame
    with HasKeyboardHandlerComponents, HasCollisionDetection {}
