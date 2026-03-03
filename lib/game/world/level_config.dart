import 'package:nexus_survivor/game/world/wave_config.dart';

/// [LevelConfig] holds the immutable configuration for a complete level.
///
/// A level consists of one or more [WaveConfig] entries that define
/// the enemy waves the player must survive. An optional [timeLimit]
/// triggers automatic failure when exceeded.
class LevelConfig {
  /// Creates a [LevelConfig].
  ///
  /// [waves] must contain at least one entry. [nexusMaxHp] must be
  /// positive. [timeLimit], when provided, must be positive.
  LevelConfig({
    required this.levelNumber,
    required List<WaveConfig> waves,
    required this.nexusMaxHp,
    this.timeLimit,
  }) : assert(levelNumber >= 1, 'levelNumber must be >= 1: $levelNumber'),
       assert(waves.isNotEmpty, 'waves must not be empty'),
       assert(nexusMaxHp > 0, 'nexusMaxHp must be > 0: $nexusMaxHp'),
       assert(
         timeLimit == null || timeLimit > 0,
         'timeLimit must be > 0 when provided: $timeLimit',
       ),
       waves = List<WaveConfig>.unmodifiable(waves);

  /// Sequential level number (1-based).
  final int levelNumber;

  /// Ordered list of enemy waves. Treated as read-only.
  final List<WaveConfig> waves;

  /// Maximum hit points of the nexus the player must defend.
  final double nexusMaxHp;

  /// Optional time limit in seconds. When elapsed the level fails
  /// automatically. `null` means no time limit.
  final double? timeLimit;

  /// Total number of waves in this level.
  int get totalWaves => waves.length;
}
