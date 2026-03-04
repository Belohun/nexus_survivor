import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_survivor/game/nexus_survivor.dart';

void main() {
  testWidgets('NexusSurvivor renders without errors', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: GameWidget(game: NexusSurvivor()),
      ),
    );
    await tester.pump();

    // The GameWidget should be present in the tree.
    expect(find.byType(GameWidget<NexusSurvivor>), findsOneWidget);
  });
}
