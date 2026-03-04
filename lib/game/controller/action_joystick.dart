import 'package:flame/components.dart';
import 'package:flame_svg/flame_svg.dart';
import 'package:flutter/widgets.dart';
import 'package:nexus_survivor/gen/assets.gen.dart';
import 'package:nexus_survivor/game/nexus_survivor.dart';

/// [ActionJoystick] is a touch-based virtual joystick for aiming
/// attacks, abilities, and movement skills.
///
/// It uses the same SVG assets as [MovementJoystick] and is placed in
/// the bottom-right corner of the viewport. The joystick provides a
/// normalised direction vector via [aimDirection] and exposes
/// [isAiming] to detect when the player is actively dragging the knob.
///
/// The controller can detect the release frame (transition from aiming
/// to not-aiming) via [wasAiming] and use it to trigger an attack in
/// the aimed direction.
///
/// Add this component to the camera viewport (HUD layer) so it
/// renders on top of the world and stays fixed on screen.
class ActionJoystick extends JoystickComponent {
  /// Creates an [ActionJoystick] with default size and margin.
  ///
  /// [padSize] controls the overall diameter of the background pad.
  /// [knobSize] controls the diameter of the draggable knob.
  /// [marginRight] and [marginBottom] control the offset from the
  /// bottom-right corner.
  ActionJoystick({
    double padSize = 128,
    double knobSize = 64,
    double marginRight = 40,
    double marginBottom = 40,
  }) : super(
         knob: SvgComponent(size: Vector2.all(knobSize)),
         background: SvgComponent(size: Vector2.all(padSize)),
         margin: EdgeInsets.only(right: marginRight, bottom: marginBottom),
       );

  //#region Private fields

  bool _wasAiming = false;

  //#endregion

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

  @override
  void update(double dt) {
    super.update(dt);
    // Track the aiming state for release detection.
    _wasAiming = isAiming;
  }

  //#endregion

  //#region Public API

  /// Returns the normalised aim direction.
  ///
  /// The vector has a magnitude between 0 and 1. Returns [Vector2.zero]
  /// when the joystick is idle.
  Vector2 get aimDirection => relativeDelta;

  /// Returns `true` when the knob is actively being dragged.
  bool get isAiming => !relativeDelta.isZero();

  /// Returns `true` when the knob was being dragged in the previous
  /// frame but is no longer.
  ///
  /// Use this to detect the release frame and trigger an attack.
  bool get wasAiming => _wasAiming;

  /// Returns `true` when the player just released the joystick.
  ///
  /// This is `true` for exactly one frame after the knob snaps back
  /// to the centre.
  bool get justReleased => _wasAiming && !isAiming;

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
