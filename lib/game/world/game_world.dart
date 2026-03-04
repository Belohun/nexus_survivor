import 'package:flame/components.dart';
import 'package:nexus_survivor/game/nexus_survivor.dart';
import 'package:nexus_survivor/game/level/base_level.dart';

/// [GameWorld] is the root Flame [World] that contains all gameplay
/// entities.
///
/// It manages loading and unloading of [BaseLevel] instances and
/// provides access to the currently active level. Add characters,
/// projectiles, and other gameplay components as children of this
/// world so the camera can follow the action.
class GameWorld extends World with HasGameReference<NexusSurvivor> {
  /// Creates a [GameWorld].
  GameWorld();

  //#region Private fields

  BaseLevel? _currentLevel;

  //#endregion

  //#region Public getters

  /// The level that is currently loaded, or `null` when none is active.
  BaseLevel? get currentLevel => _currentLevel;

  //#endregion

  //#region Level management

  /// Loads the given [level] into the world, replacing any previously
  /// active level.
  ///
  /// The old level (if any) is removed from the component tree before
  /// the new one is added. Callers are responsible for calling
  /// [BaseLevel.startLevel] after the level is mounted.
  Future<void> loadLevel(BaseLevel level) async {
    if (_currentLevel != null) {
      _currentLevel!.removeFromParent();
      _currentLevel = null;
    }

    _currentLevel = level;
    await add(level);
  }

  /// Removes the current level without loading a replacement.
  void unloadLevel() {
    if (_currentLevel != null) {
      _currentLevel!.removeFromParent();
      _currentLevel = null;
    }
  }

  //#endregion
}
