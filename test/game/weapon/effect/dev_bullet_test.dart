import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_survivor/game/weapon/effect/dev_bullet.dart';

void main() {
  group('DevBullet', () {
    //#region Construction

    test('creates with default values', () {
      final bullet = DevBullet(
        spawnPosition: Vector2(10, 20),
        direction: Vector2(1, 0),
      );

      expect(bullet.position, Vector2(10, 20));
      expect(bullet.speed, 400);
      expect(bullet.damage, 10);
      expect(bullet.maxDistance, 300);
      expect(bullet.isFinished, isFalse);
    });

    test('creates with custom values', () {
      final bullet = DevBullet(
        spawnPosition: Vector2.zero(),
        direction: Vector2(0, 1),
        speed: 200,
        damage: 25,
        maxDistance: 500,
      );

      expect(bullet.speed, 200);
      expect(bullet.damage, 25);
      expect(bullet.maxDistance, 500);
    });

    test('asserts on non-positive maxDistance', () {
      expect(
        () => DevBullet(
          spawnPosition: Vector2.zero(),
          direction: Vector2(1, 0),
          maxDistance: 0,
        ),
        throwsA(
          isA<AssertionError>().having(
            (e) => e.message,
            'message',
            contains('maxDistance must be positive: 0'),
          ),
        ),
      );
    });

    test('asserts on negative maxDistance', () {
      expect(
        () => DevBullet(
          spawnPosition: Vector2.zero(),
          direction: Vector2(1, 0),
          maxDistance: -10,
        ),
        throwsA(
          isA<AssertionError>().having(
            (e) => e.message,
            'message',
            contains('maxDistance must be positive: -10'),
          ),
        ),
      );
    });

    //#endregion

    //#region Movement

    test('moves in the specified direction each frame', () {
      final bullet = DevBullet(
        spawnPosition: Vector2.zero(),
        direction: Vector2(1, 0),
        speed: 100,
      );

      bullet.onEffectUpdate(1.0);

      expect(bullet.position.x, closeTo(100, 0.01));
      expect(bullet.position.y, closeTo(0, 0.01));
    });

    test('moves diagonally when direction is diagonal', () {
      final bullet = DevBullet(
        spawnPosition: Vector2.zero(),
        direction: Vector2(1, 1),
        speed: 100,
      );

      bullet.onEffectUpdate(1.0);

      // Normalised (1,1) ≈ (0.707, 0.707), so after 1s at speed 100
      // position should be roughly (70.7, 70.7).
      expect(bullet.position.x, closeTo(70.71, 0.1));
      expect(bullet.position.y, closeTo(70.71, 0.1));
    });

    //#endregion

    //#region Lifetime

    test('isFinished becomes true after travelling maxDistance', () {
      final bullet = DevBullet(
        spawnPosition: Vector2.zero(),
        direction: Vector2(1, 0),
        speed: 300,
        maxDistance: 300,
      );

      expect(bullet.isFinished, isFalse);

      // 1 second at speed 300 = 300px → matches maxDistance.
      bullet.onEffectUpdate(1.0);

      expect(bullet.isFinished, isTrue);
    });

    test('isFinished stays false before reaching maxDistance', () {
      final bullet = DevBullet(
        spawnPosition: Vector2.zero(),
        direction: Vector2(1, 0),
        speed: 100,
        maxDistance: 300,
      );

      // 1 second at speed 100 = 100px < 300.
      bullet.onEffectUpdate(1.0);

      expect(bullet.isFinished, isFalse);
    });

    //#endregion
  });
}
