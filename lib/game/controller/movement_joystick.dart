import 'package:flame/components.dart';
import 'package:flame_svg/flame_svg.dart';
import 'package:flutter/widgets.dart';
import 'package:nexus_survivor/gen/assets.gen.dart';
import 'package:nexus_survivor/game/nexus_survivor.dart';

/// [MovementJoystick] is a touch-based virtual joystick for character movement.
///
/// It uses the `joystick_circle_pad` SVG as the background pad and
/// `button_circle` SVG as the draggable knob. The joystick is placed
/// in the bottom-left corner of the viewport and provides a normalised
/// direction vector via [movementDirection] and drag intensity via
/// [intensity].
///
/// Add this component directly to the game (HUD layer) so it renders
/// on top of the world and stays fixed on screen.
class MovementJoystick extends JoystickComponent {
  /// Creates a [MovementJoystick] with default size and margin.
  ///
  /// [padSize] controls the overall diameter of the background pad.
  /// [knobSize] controls the diameter of the draggable knob.
  /// [marginLeft] and [marginBottom] control the offset from the
  /// bottom-left corner.
  MovementJoystick({
    double padSize = 128,
    double knobSize = 64,
    double marginLeft = 40,
    double marginBottom = 40,
  }) : super(
         knob: SvgComponent(size: Vector2.all(knobSize)),
         background: SvgComponent(size: Vector2.all(padSize)),
         margin: EdgeInsets.only(left: marginLeft, bottom: marginBottom),
       );

  //#region Lifecycle

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final nexusGame = game as NexusSurvivor;

    final backgroundSvg = await nexusGame.loadSvg(
      _stripAssetsPrefix(Assets.images.joystickCirclePad.path),
    );
    final knobSvg = await nexusGame.loadSvg(
      _stripAssetsPrefix(Assets.images.buttonCircle.path),
    );

    (background! as SvgComponent).svg = backgroundSvg;
    (knob! as SvgComponent).svg = knobSvg;
  }

  //#endregion

  //#region Public API

  /// Returns the normalised movement direction.
  ///
  /// The vector has a magnitude between 0 and 1. Returns [Vector2.zero]
  /// when the joystick is idle.
  Vector2 get movementDirection => relativeDelta;

  //#endregion

  //#region Private helpers

  /// Strips the leading `assets/` prefix from a flutter_gen path.
  ///
  /// Flame's [AssetsCache] already prepends `assets/` when resolving
  /// file names, so the prefix must be removed to avoid a double
  /// `assets/assets/…` lookup.
  static const String _assetsPrefix = 'assets/';

  static String _stripAssetsPrefix(String path) {
    if (path.startsWith(_assetsPrefix)) {
      return path.substring(_assetsPrefix.length);
    }
    return path;
  }

  //#endregion
}
