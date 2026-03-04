/// [LevelState] represents all possible states a level can be in.
///
/// Used by [BaseLevel] to drive the wave state machine and guard
/// illegal transitions between lifecycle phases.
enum LevelState {
  /// The level is being set up (assets, spawners, etc.).
  loading,

  /// The level is active but between waves (delay countdown).
  playing,

  /// Enemies are actively being spawned and fought.
  waveInProgress,

  /// All enemies in the current wave have been defeated.
  waveComplete,

  /// Every wave has been cleared — the player won.
  levelComplete,

  /// The nexus was destroyed — the player lost.
  failed,
}
