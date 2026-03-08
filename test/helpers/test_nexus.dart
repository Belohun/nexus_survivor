import 'package:flame/components.dart';
import 'package:nexus_survivor/game/nexus/base_nexus_component.dart';
import 'package:nexus_survivor/game/nexus/nexus_stats.dart';

/// A minimal concrete [BaseNexusComponent] used in tests.
///
/// Records hook invocations so tests can assert destruction callbacks.
class TestNexus extends BaseNexusComponent {
  /// Creates a [TestNexus] with the given [testStats].
  ///
  /// [testSize] and [testPosition] control the component's geometry
  /// for collision-related tests.
  TestNexus({
    required NexusStats testStats,
    Vector2? testSize,
    Vector2? testPosition,
  }) : _testStats = testStats,
       _testSize = testSize,
       _testPosition = testPosition;

  final NexusStats _testStats;
  final Vector2? _testSize;
  final Vector2? _testPosition;

  /// Number of times [onDestroyed] was called.
  int destroyedCount = 0;

  @override
  NexusStats get baseStats => _testStats;

  @override
  void onDestroyed() {
    destroyedCount++;
  }

  @override
  Future<void> onLoad() async {
    if (_testSize != null) size = _testSize;
    if (_testPosition != null) position = _testPosition;
    await super.onLoad();
  }
}

/// Creates a default [NexusStats] suitable for most tests.
NexusStats defaultTestNexusStats({
  double maxHp = 100,
  double? currentHp,
  double defense = 0,
}) {
  return NexusStats(maxHp: maxHp, currentHp: currentHp, defense: defense);
}
