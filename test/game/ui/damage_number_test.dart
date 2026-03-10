import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_survivor/game/nexus_survivor.dart';
import 'package:nexus_survivor/game/ui/damage_number.dart';

void main() {
  group('DamageNumber', () {
    test('removes itself after lifetime expires', () async {
      final game = await initializeGame(NexusSurvivor.new);

      final dmgNum = DamageNumber(
        value: 42,
        worldPosition: Vector2(100, 100),
        lifetime: 0.5,
      );
      await game.ensureAdd(dmgNum);

      expect(game.children.whereType<DamageNumber>().length, 1);

      // Advance past the lifetime.
      game.update(0.6);

      // After update, it should have called removeFromParent.
      // The actual removal happens on the next game processing cycle.
      game.update(0);
      expect(game.children.whereType<DamageNumber>().length, 0);
    });

    test('drifts upward over time', () async {
      final game = await initializeGame(NexusSurvivor.new);

      final dmgNum = DamageNumber(
        value: 10,
        worldPosition: Vector2(50, 200),
        lifetime: 1.0,
      );
      await game.ensureAdd(dmgNum);

      final initialY = dmgNum.position.y;
      game.update(0.2);
      expect(dmgNum.position.y, lessThan(initialY));
    });

    test('stores value and isCrit flag', () {
      final dmgNum = DamageNumber(
        value: 99,
        worldPosition: Vector2.zero(),
        isCrit: true,
      );

      expect(dmgNum.value, 99);
      expect(dmgNum.isCrit, isTrue);
    });

    test('default lifetime is 0.8 seconds', () {
      final dmgNum = DamageNumber(value: 10, worldPosition: Vector2.zero());
      expect(dmgNum.lifetime, 0.8);
    });
  });
}
