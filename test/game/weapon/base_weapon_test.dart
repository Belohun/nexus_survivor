import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_survivor/game/nexus_survivor.dart';
import 'package:nexus_survivor/game/weapon/base_weapon.dart';
import 'package:nexus_survivor/game/weapon/cooldown_modifier.dart';

/// A minimal concrete [BaseWeapon] used in tests.
class _TestWeapon extends BaseWeapon {
  _TestWeapon({super.orbitRadius, super.baseCooldown});

  int fireCount = 0;

  @override
  void onFire() {
    fireCount++;
  }
}

void main() {
  group('BaseWeapon', () {
    //#region Construction

    test('creates with default orbit radius and cooldown', () {
      final weapon = _TestWeapon();

      expect(weapon.orbitRadius, 24);
      expect(weapon.baseCooldown, 0.3);
      expect(weapon.aimAngle, 0);
      expect(weapon.isAiming, isFalse);
      expect(weapon.canFire, isTrue);
    });

    test('creates with custom orbit radius', () {
      final weapon = _TestWeapon(orbitRadius: 50);

      expect(weapon.orbitRadius, 50);
    });

    test('creates with custom baseCooldown', () {
      final weapon = _TestWeapon(baseCooldown: 1.5);

      expect(weapon.baseCooldown, 1.5);
      expect(weapon.effectiveCooldown, 1.5);
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

    test('asserts on negative baseCooldown', () {
      expect(
        () => _TestWeapon(baseCooldown: -0.1),
        throwsA(
          isA<AssertionError>().having(
            (e) => e.message,
            'message',
            contains('baseCooldown must be non-negative: -0.1'),
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

    //#region tryFire / cooldown

    test('tryFire fires and starts cooldown', () async {
      final game = await initializeGame(NexusSurvivor.new);
      final weapon = _TestWeapon(baseCooldown: 1.0);
      await game.ensureAdd(weapon);

      expect(weapon.canFire, isTrue);

      final result = weapon.tryFire();

      expect(result, isTrue);
      expect(weapon.fireCount, 1);
      expect(weapon.canFire, isFalse);

      game.onRemove();
    });

    test('tryFire is blocked while on cooldown', () async {
      final game = await initializeGame(NexusSurvivor.new);
      final weapon = _TestWeapon(baseCooldown: 1.0);
      await game.ensureAdd(weapon);

      weapon.tryFire();
      final second = weapon.tryFire();

      expect(second, isFalse);
      expect(weapon.fireCount, 1);

      game.onRemove();
    });

    test('cooldown expires after baseCooldown duration', () async {
      final game = await initializeGame(NexusSurvivor.new);
      final weapon = _TestWeapon(baseCooldown: 0.5);
      await game.ensureAdd(weapon);

      weapon.tryFire();
      expect(weapon.canFire, isFalse);

      game.update(0.6);

      expect(weapon.canFire, isTrue);

      game.onRemove();
    });

    test('zero baseCooldown allows immediate re-fire', () async {
      final game = await initializeGame(NexusSurvivor.new);
      final weapon = _TestWeapon(baseCooldown: 0);
      await game.ensureAdd(weapon);

      weapon.tryFire();
      expect(weapon.canFire, isTrue);

      final second = weapon.tryFire();
      expect(second, isTrue);
      expect(weapon.fireCount, 2);

      game.onRemove();
    });

    //#endregion

    //#region CooldownModifier

    test('addCooldownModifier reduces effectiveCooldown', () {
      final weapon = _TestWeapon(baseCooldown: 1.0);

      weapon.addCooldownModifier(
        const CooldownModifier(id: 'rapid_fire', multiplier: 0.8),
      );

      expect(weapon.effectiveCooldown, closeTo(0.8, 0.001));
    });

    test('addCooldownModifier increases effectiveCooldown', () {
      final weapon = _TestWeapon(baseCooldown: 1.0);

      weapon.addCooldownModifier(
        const CooldownModifier(id: 'slow_debuff', multiplier: 1.5),
      );

      expect(weapon.effectiveCooldown, closeTo(1.5, 0.001));
    });

    test('multiple modifiers stack multiplicatively', () {
      final weapon = _TestWeapon(baseCooldown: 1.0);

      weapon.addCooldownModifier(
        const CooldownModifier(id: 'mod_a', multiplier: 0.8),
      );
      weapon.addCooldownModifier(
        const CooldownModifier(id: 'mod_b', multiplier: 0.5),
      );

      // 1.0 * 0.8 * 0.5 = 0.4
      expect(weapon.effectiveCooldown, closeTo(0.4, 0.001));
    });

    test('removeCooldownModifier restores effectiveCooldown', () {
      final weapon = _TestWeapon(baseCooldown: 1.0);

      weapon.addCooldownModifier(
        const CooldownModifier(id: 'buff', multiplier: 0.5),
      );
      expect(weapon.effectiveCooldown, closeTo(0.5, 0.001));

      weapon.removeCooldownModifier('buff');

      expect(weapon.effectiveCooldown, closeTo(1.0, 0.001));
    });

    test('adding modifier with same id replaces existing one', () {
      final weapon = _TestWeapon(baseCooldown: 1.0);

      weapon.addCooldownModifier(
        const CooldownModifier(id: 'buff', multiplier: 0.5),
      );
      weapon.addCooldownModifier(
        const CooldownModifier(id: 'buff', multiplier: 0.9),
      );

      expect(weapon.cooldownModifiers.length, 1);
      expect(weapon.effectiveCooldown, closeTo(0.9, 0.001));
    });

    test('removing non-existent modifier is a no-op', () {
      final weapon = _TestWeapon(baseCooldown: 1.0);

      weapon.removeCooldownModifier('does_not_exist');

      expect(weapon.effectiveCooldown, closeTo(1.0, 0.001));
    });

    test('modifier affects tryFire cooldown duration', () async {
      final game = await initializeGame(NexusSurvivor.new);
      final weapon = _TestWeapon(baseCooldown: 1.0);
      await game.ensureAdd(weapon);

      // Add a 50 % reduction modifier.
      weapon.addCooldownModifier(
        const CooldownModifier(id: 'rapid', multiplier: 0.5),
      );

      weapon.tryFire();
      expect(weapon.canFire, isFalse);

      // After 0.6 s the effective 0.5 s cooldown should have expired.
      game.update(0.6);
      expect(weapon.canFire, isTrue);

      game.onRemove();
    });

    //#endregion
  });
}
