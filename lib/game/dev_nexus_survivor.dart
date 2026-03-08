import 'package:flame/components.dart';
import 'package:nexus_survivor/game/character/dev_character.dart';
import 'package:nexus_survivor/game/controller/action_joystick.dart';
import 'package:nexus_survivor/game/controller/movement_joystick.dart';
import 'package:nexus_survivor/game/controller/player_controller.dart';
import 'package:nexus_survivor/game/nexus/dev_nexus.dart';
import 'package:nexus_survivor/game/nexus_survivor.dart';
import 'package:nexus_survivor/game/ui/dev_spawn_button.dart';
import 'package:nexus_survivor/game/weapon/dev_weapon.dart';
import 'package:nexus_survivor/game/world/dev/dev_background.dart';
import 'package:nexus_survivor/game/level/level.dart';
import 'package:nexus_survivor/game/world/game_world.dart';

/// [DevNexusSurvivor] is a development-only [NexusSurvivor] variant
/// that wires up a [DevCharacter], [DevLevel], [MovementJoystick],
/// [ActionJoystick], [DevWeapon], and [PlayerController] on load.
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

  /// The virtual joystick for aiming and triggering actions.
  late final ActionJoystick actionJoystick;

  /// The development weapon (orange rectangle placeholder).
  late final DevWeapon devWeapon;

  /// The nexus building placed at the centre of the world.
  late final DevNexus nexus;

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

    // Create the player character to the right of the nexus.
    player = DevCharacter(initialPosition: Vector2(80, 0));

    // Attach the dev weapon to the player.
    devWeapon = DevWeapon();
    player.weapon = devWeapon;

    await gameWorld.add(DevBackground());

    // Place the nexus at the centre of the world.
    nexus = DevNexus();
    await gameWorld.add(nexus);

    await gameWorld.add(player);

    // Load and start the dev level (with nexus & player references).
    devLevel = DevLevel(nexus: nexus, player: player);
    await gameWorld.loadLevel(devLevel);
    devLevel.startLevel();

    // Create the movement joystick (HUD — added to the camera viewport).
    movementJoystick = MovementJoystick();
    await camera.viewport.add(movementJoystick);

    // Create the action joystick (HUD — bottom-right corner).
    actionJoystick = ActionJoystick();
    await camera.viewport.add(actionJoystick);

    // Add a debug spawn button to the HUD.
    final spawnButton = DevSpawnButton(
      nexus: nexus,
      player: player,
      gameWorld: gameWorld,
    );
    await camera.viewport.add(spawnButton);

    // Create the player controller with both joysticks.
    final controller = PlayerController(
      character: player,
      movementJoystick: movementJoystick,
      actionJoystick: actionJoystick,
    );
    await add(controller);

    // Make the camera follow the player.
    camera.follow(player);
  }
}
