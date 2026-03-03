import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_survivor/game/controller/movement_joystick.dart';

void main() {
  group('MovementJoystick', () {
    test('creates with default sizes', () {
      final joystick = MovementJoystick();

      expect(joystick.knob, isNotNull);
      expect(joystick.background, isNotNull);
    });

    test('creates with custom sizes', () {
      final joystick = MovementJoystick(
        padSize: 200,
        knobSize: 80,
        marginLeft: 20,
        marginBottom: 20,
      );

      expect(joystick.knob, isNotNull);
      expect(joystick.background, isNotNull);
      expect(joystick.background!.size, Vector2.all(200));
      expect(joystick.knob!.size, Vector2.all(80));
    });

    test('direction returns zero when idle', () {
      final joystick = MovementJoystick();

      expect(joystick.movementDirection, Vector2.zero());
    });

    test('intensity starts at zero', () {
      final joystick = MovementJoystick();

      expect(joystick.intensity, 0.0);
    });
  });
}
