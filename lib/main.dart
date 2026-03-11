import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:nexus_survivor/game/ui/main_menu/main_menu_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to landscape only.
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Enable fullscreen — hide status bar and navigation bar.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(
    WidgetsApp(
      title: 'Nexus Survivor',
      color: const Color(0xFF1A1A2E),
      home: const MainMenuPage(),
      pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) =>
          PageRouteBuilder<T>(
            settings: settings,
            pageBuilder: (context, a, b) => builder(context),
          ),
    ),
  );
}
