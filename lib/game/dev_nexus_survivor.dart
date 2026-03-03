import 'package:flame/camera.dart';
import 'package:nexus_survivor/game/character/dev_character.dart';
import 'package:nexus_survivor/game/controller/movement_joystick.dart';
import 'package:nexus_survivor/game/controller/player_controller.dart';
import 'package:nexus_survivor/game/nexus_survivor.dart';
import 'package:nexus_survivor/game/world/dev_background.dart';
import 'package:nexus_survivor/game/world/dev_level.dart';
import 'package:nexus_survivor/game/world/game_world.dart';

/// [DevNexusSurvivor] is a development-only [NexusSurvivor] variant
/// that wires up a [DevCharacter], [DevLevel], [MovementJoystick],
/// and [PlayerController] on load.
///
/// Use this in [GamePage] during development to get a running game
/// with placeholder graphics and working joystick movement without
/// requiring real art assets or enemy implementations.
class DevNexusSurvivor extends NexusSurvivor {
  /// The root game world containing all gameplay entities.
  late final GameWorld gameWorld;

  /// The player character (cyan square placeholder).
  late final DevCharacter player;

  /// The virtual joystick for touch-based movement.
  late final MovementJoystick movementJoystick;

  /// The development level driving the wave state machine.
  late final DevLevel devLevel;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Create and mount the game world.
    gameWorld = GameWorld();
    world = gameWorld;

    // Set up the camera to follow the player.
    camera = CameraComponent(world: gameWorld);

    // Create the player character at the centre of the world.
    player = DevCharacter();
    await gameWorld.add(DevBackground());
    await gameWorld.add(player);

    // Load and start the dev level.
    devLevel = DevLevel();
    await gameWorld.loadLevel(devLevel);
    devLevel.startLevel();

    // Create the movement joystick (HUD — added to the camera viewport).
    movementJoystick = MovementJoystick();
    await camera.viewport.add(movementJoystick);

    // Create the player controller with joystick support.
    final controller = PlayerController(
      character: player,
      movementJoystick: movementJoystick,
    );
    await add(controller);

    // Make the camera follow the player.
    camera.follow(player);
  }
}
