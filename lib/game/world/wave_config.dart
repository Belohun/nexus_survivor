/// [WaveConfig] holds the immutable configuration for a single enemy wave.
///
/// Each wave defines how many enemies to spawn, how quickly they appear,
/// and how long to wait before the wave begins.
class WaveConfig {
  /// Creates a [WaveConfig].
  ///
  /// All numeric values must be positive or non-negative as documented.
  const WaveConfig({
    required this.waveNumber,
    required this.enemyCount,
    this.spawnInterval = 1.0,
    this.delayBeforeWave = 3.0,
  }) : assert(waveNumber >= 1, 'waveNumber must be >= 1: $waveNumber'),
       assert(enemyCount >= 1, 'enemyCount must be >= 1: $enemyCount'),
       assert(spawnInterval > 0, 'spawnInterval must be > 0: $spawnInterval'),
       assert(
         delayBeforeWave >= 0,
         'delayBeforeWave must be >= 0: $delayBeforeWave',
       );

  /// Sequential wave number (1-based).
  final int waveNumber;

  /// Total number of enemies to spawn during this wave.
  final int enemyCount;

  /// Time in seconds between individual enemy spawns.
  final double spawnInterval;

  /// Delay in seconds before this wave starts (e.g. a grace period).
  final double delayBeforeWave;

  /// Returns a copy with optionally overridden fields.
  WaveConfig copyWith({
    int? waveNumber,
    int? enemyCount,
    double? spawnInterval,
    double? delayBeforeWave,
  }) {
    return WaveConfig(
      waveNumber: waveNumber ?? this.waveNumber,
      enemyCount: enemyCount ?? this.enemyCount,
      spawnInterval: spawnInterval ?? this.spawnInterval,
      delayBeforeWave: delayBeforeWave ?? this.delayBeforeWave,
    );
  }
}
