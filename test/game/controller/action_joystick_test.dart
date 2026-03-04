import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_survivor/game/controller/action_joystick.dart';

void main() {
  group('ActionJoystick', () {
    test('creates with default sizes', () {
      final joystick = ActionJoystick();

      expect(joystick.knob, isNotNull);
      expect(joystick.background, isNotNull);
    });

    test('creates with custom sizes', () {
      final joystick = ActionJoystick(
        padSize: 200,
        knobSize: 80,
        marginRight: 20,
        marginBottom: 20,
      );

      expect(joystick.knob, isNotNull);
      expect(joystick.background, isNotNull);
      expect(joystick.background!.size, Vector2.all(200));
      expect(joystick.knob!.size, Vector2.all(80));
    });

    test('aimDirection returns zero when idle', () {
      final joystick = ActionJoystick();

      expect(joystick.aimDirection, Vector2.zero());
    });

    test('isAiming is false when idle', () {
      final joystick = ActionJoystick();

      expect(joystick.isAiming, isFalse);
    });

    test('wasAiming is false initially', () {
      final joystick = ActionJoystick();

      expect(joystick.wasAiming, isFalse);
    });

    test('justReleased is false when idle', () {
      final joystick = ActionJoystick();

      expect(joystick.justReleased, isFalse);
    });

    test('intensity starts at zero', () {
      final joystick = ActionJoystick();

      expect(joystick.intensity, 0.0);
    });
  });
}
