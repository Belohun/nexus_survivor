import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_survivor/game/weapon/base_weapon.dart';

/// A minimal concrete [BaseWeapon] used in tests.
class _TestWeapon extends BaseWeapon {
  _TestWeapon({super.orbitRadius});

  int fireCount = 0;

  @override
  void onFire() {
    fireCount++;
  }
}

void main() {
  group('BaseWeapon', () {
    //#region Construction

    test('creates with default orbit radius', () {
      final weapon = _TestWeapon();

      expect(weapon.orbitRadius, 24);
      expect(weapon.aimAngle, 0);
      expect(weapon.isAiming, isFalse);
    });

    test('creates with custom orbit radius', () {
      final weapon = _TestWeapon(orbitRadius: 50);

      expect(weapon.orbitRadius, 50);
    });

    test('asserts on negative orbit radius', () {
      expect(
        () => _TestWeapon(orbitRadius: -1),
        throwsA(
          isA<AssertionError>().having(
            (e) => e.message,
            'message',
            contains('orbitRadius must be non-negative: -1'),
          ),
        ),
      );
    });

    //#endregion

    //#region setAimDirection

    test('setAimDirection updates aimAngle from direction vector', () {
      final weapon = _TestWeapon();

      // Aim right → angle 0.
      weapon.setAimDirection(Vector2(1, 0));
      expect(weapon.aimAngle, closeTo(0, 0.001));

      // Aim down → angle π/2.
      weapon.setAimDirection(Vector2(0, 1));
      expect(weapon.aimAngle, closeTo(pi / 2, 0.001));

      // Aim left → angle π (or -π).
      weapon.setAimDirection(Vector2(-1, 0));
      expect(weapon.aimAngle.abs(), closeTo(pi, 0.001));

      // Aim up → angle -π/2.
      weapon.setAimDirection(Vector2(0, -1));
      expect(weapon.aimAngle, closeTo(-pi / 2, 0.001));
    });

    test('setAimDirection ignores zero vector', () {
      final weapon = _TestWeapon();
      weapon.setAimDirection(Vector2(1, 0));
      final originalAngle = weapon.aimAngle;

      weapon.setAimDirection(Vector2.zero());

      expect(weapon.aimAngle, originalAngle);
    });

    //#endregion

    //#region onFire

    test('onFire is callable and tracks invocations', () {
      final weapon = _TestWeapon();

      weapon.onFire();
      weapon.onFire();

      expect(weapon.fireCount, 2);
    });

    //#endregion
  });
}
