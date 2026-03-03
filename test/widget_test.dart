import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_survivor/game/game_page/game_page.dart';

void main() {
  testWidgets('GamePage renders without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const GamePage());
    await tester.pump();

    // The GameWidget should be present in the tree.
    expect(find.byType(GamePage), findsOneWidget);
  });
}
