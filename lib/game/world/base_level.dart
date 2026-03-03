import 'package:flame/components.dart';
import 'package:nexus_survivor/game/world/level_config.dart';
import 'package:nexus_survivor/game/world/level_state.dart';
import 'package:nexus_survivor/game/world/wave_config.dart';

/// [BaseLevel] is the abstract foundation for every playable level.
///
/// It manages the wave state machine, spawn timing, nexus health, and
/// an optional time limit. Subclasses **must** implement:
/// - [onSpawnEnemy] — create a concrete enemy for the current wave.
/// - [onLevelComplete] — handle the win condition.
/// - [onLevelFailed] — handle the lose condition.
abstract class BaseLevel extends Component {
  /// Creates a [BaseLevel] driven by the given [config].
  BaseLevel({required this.config});

  /// The immutable configuration that defines this level's waves and
  /// properties.
  final LevelConfig config;

  //#region Private fields

  LevelState _currentState = LevelState.loading;

  int _currentWaveIndex = 0;
  int _enemiesAlive = 0;
  int _enemiesSpawned = 0;
  double _nexusHp = 0;
  double _waveSpawnTimer = 0;
  double _delayTimer = 0;
  double _elapsedTime = 0;

  //#endregion

  //#region Public getters

  /// The current lifecycle state of this level.
  LevelState get currentState => _currentState;

  /// Zero-based index of the wave currently being played.
  int get currentWaveIndex => _currentWaveIndex;

  /// Number of enemies still alive in the current wave.
  int get enemiesAlive => _enemiesAlive;

  /// Number of enemies spawned so far in the current wave.
  int get enemiesSpawned => _enemiesSpawned;

  /// Current hit points of the nexus.
  double get nexusHp => _nexusHp;

  /// Total elapsed time since the level started (seconds).
  double get elapsedTime => _elapsedTime;

  /// The [WaveConfig] for the wave currently in progress.
  ///
  /// Returns `null` when no wave is active.
  WaveConfig? get currentWave {
    if (_currentWaveIndex < config.waves.length) {
      return config.waves[_currentWaveIndex];
    }
    return null;
  }

  /// Returns `true` when all waves have been completed.
  bool get allWavesComplete => _currentWaveIndex >= config.totalWaves;

  //#endregion

  //#region Abstract hooks

  /// Called each time an enemy should be spawned during a wave.
  ///
  /// [waveNumber] is 1-based. Subclasses create and add the concrete
  /// enemy component to the game tree here.
  void onSpawnEnemy(int waveNumber);

  /// Called when all waves have been cleared and the level is won.
  void onLevelComplete();

  /// Called when the nexus is destroyed or the time limit expires.
  void onLevelFailed();

  //#endregion

  //#region Level lifecycle

  /// Starts the level by initialising nexus HP and transitioning to
  /// the pre-wave delay of the first wave.
  ///
  /// Must only be called while in [LevelState.loading].
  void startLevel() {
    assert(
      _currentState == LevelState.loading,
      'startLevel() called in unexpected state: $_currentState',
    );

    _nexusHp = config.nexusMaxHp;
    _currentWaveIndex = 0;
    _elapsedTime = 0;
    _beginWaveDelay();
  }

  //#endregion

  //#region Nexus

  /// Deals [amount] damage to the nexus.
  ///
  /// When the nexus HP drops to zero the level transitions to
  /// [LevelState.failed] and [onLevelFailed] is called.
  void damageNexus(double amount) {
    assert(amount >= 0, 'Damage amount must be >= 0: $amount');

    if (_currentState == LevelState.failed ||
        _currentState == LevelState.levelComplete) {
      return;
    }

    _nexusHp = (_nexusHp - amount).clamp(0.0, config.nexusMaxHp);

    if (_nexusHp <= 0) {
      _currentState = LevelState.failed;
      onLevelFailed();
    }
  }

  //#endregion

  //#region Enemy tracking

  /// Notifies the level that one enemy has been defeated.
  ///
  /// When all enemies in the current wave are dead the level either
  /// advances to the next wave or completes.
  void onEnemyDefeated() {
    assert(_enemiesAlive > 0, 'onEnemyDefeated called with 0 enemies alive');

    _enemiesAlive--;

    if (_enemiesAlive <= 0 &&
        _enemiesSpawned >= (currentWave?.enemyCount ?? 0)) {
      _onWaveCleared();
    }
  }

  //#endregion

  //#region Update loop

  @override
  void update(double dt) {
    super.update(dt);

    if (_currentState == LevelState.failed ||
        _currentState == LevelState.levelComplete) {
      return;
    }

    _elapsedTime += dt;

    // Check time limit.
    if (config.timeLimit != null && _elapsedTime >= config.timeLimit!) {
      _currentState = LevelState.failed;
      onLevelFailed();
      return;
    }

    switch (_currentState) {
      case LevelState.playing:
        final leftover = _updateDelay(dt);
        // If the delay expired this tick, spend the remaining time
        // spawning so the first enemy appears without an extra frame.
        if (_currentState == LevelState.waveInProgress && leftover > 0) {
          _updateWaveSpawning(leftover);
        }
      case LevelState.waveInProgress:
        _updateWaveSpawning(dt);
      case LevelState.loading:
      case LevelState.waveComplete:
      case LevelState.levelComplete:
      case LevelState.failed:
        break;
    }
  }

  //#endregion

  //#region Private wave logic

  void _beginWaveDelay() {
    final wave = config.waves[_currentWaveIndex];
    _delayTimer = wave.delayBeforeWave;
    _enemiesSpawned = 0;
    _currentState = LevelState.playing;
  }

  /// Returns the leftover time after the delay expires (0 if still waiting).
  double _updateDelay(double dt) {
    _delayTimer -= dt;
    if (_delayTimer <= 0) {
      final leftover = -_delayTimer;
      _startWave();
      return leftover;
    }
    return 0;
  }

  void _startWave() {
    _waveSpawnTimer = 0;
    _currentState = LevelState.waveInProgress;
  }

  void _updateWaveSpawning(double dt) {
    final wave = currentWave;
    if (wave == null) return;

    _waveSpawnTimer -= dt;
    if (_waveSpawnTimer <= 0 && _enemiesSpawned < wave.enemyCount) {
      _enemiesSpawned++;
      _enemiesAlive++;
      _waveSpawnTimer = wave.spawnInterval;
      // Called last so subclasses can safely invoke onEnemyDefeated()
      // from within the hook — counters are already up to date.
      onSpawnEnemy(wave.waveNumber);
    }
  }

  void _onWaveCleared() {
    _currentState = LevelState.waveComplete;
    _currentWaveIndex++;

    if (allWavesComplete) {
      _currentState = LevelState.levelComplete;
      onLevelComplete();
    } else {
      _beginWaveDelay();
    }
  }

  //#endregion
}
