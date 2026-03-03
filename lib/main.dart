import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:nexus_survivor/game/game_page/game_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to landscape only.
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Enable fullscreen — hide status bar and navigation bar.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const GamePage());
}
