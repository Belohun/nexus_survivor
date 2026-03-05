import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_survivor/game/weapon/effect/base_weapon_effect.dart';

/// A minimal concrete [BaseWeaponEffect] for testing.
class _TestEffect extends BaseWeaponEffect {
  _TestEffect({
    required super.spawnPosition,
    required super.direction,
    super.speed = 100,
    super.damage = 10,
    this.maxUpdates = 999,
  });

  final int maxUpdates;
  int updateCount = 0;

  @override
  bool get isFinished => updateCount >= maxUpdates;

  @override
  void onEffectUpdate(double dt) {
    updateCount++;
  }
}

void main() {
  group('BaseWeaponEffect', () {
    //#region Construction

    test('creates with correct spawn position and direction', () {
      final effect = _TestEffect(
        spawnPosition: Vector2(10, 20),
        direction: Vector2(1, 0),
      );

      expect(effect.position, Vector2(10, 20));
      expect(effect.direction, Vector2(1, 0));
      expect(effect.speed, 100);
      expect(effect.damage, 10);
    });

    test('normalises direction on creation', () {
      final effect = _TestEffect(
        spawnPosition: Vector2.zero(),
        direction: Vector2(3, 4),
      );

      expect(effect.direction.length, closeTo(1.0, 0.001));
    });

    test('asserts on negative speed', () {
      expect(
        () => _TestEffect(
          spawnPosition: Vector2.zero(),
          direction: Vector2(1, 0),
          speed: -1,
        ),
        throwsA(
          isA<AssertionError>().having(
            (e) => e.message,
            'message',
            contains('speed must be non-negative: -1'),
          ),
        ),
      );
    });

    test('asserts on negative damage', () {
      expect(
        () => _TestEffect(
          spawnPosition: Vector2.zero(),
          direction: Vector2(1, 0),
          damage: -5,
        ),
        throwsA(
          isA<AssertionError>().having(
            (e) => e.message,
            'message',
            contains('damage must be non-negative: -5'),
          ),
        ),
      );
    });

    //#endregion

    //#region Lifecycle

    test('calls onEffectUpdate every frame', () {
      final effect = _TestEffect(
        spawnPosition: Vector2.zero(),
        direction: Vector2(1, 0),
      );

      effect.update(0.016);
      effect.update(0.016);
      effect.update(0.016);

      expect(effect.updateCount, 3);
    });

    test('isFinished is false before reaching max updates', () {
      final effect = _TestEffect(
        spawnPosition: Vector2.zero(),
        direction: Vector2(1, 0),
        maxUpdates: 5,
      );

      for (var i = 0; i < 4; i++) {
        effect.update(0.016);
      }

      expect(effect.isFinished, isFalse);
    });

    test('isFinished is true after reaching max updates', () {
      final effect = _TestEffect(
        spawnPosition: Vector2.zero(),
        direction: Vector2(1, 0),
        maxUpdates: 3,
      );

      for (var i = 0; i < 3; i++) {
        effect.update(0.016);
      }

      expect(effect.isFinished, isTrue);
    });

    //#endregion
  });
}
