import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nexus_survivor/injection.dart';
import 'package:nexus_survivor/ui/character_selection/character_selection_cubit.dart';
import 'package:nexus_survivor/ui/main_menu/main_menu_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to landscape only.
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Enable fullscreen — hide status bar and navigation bar.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Resolve all registered dependencies (including async singletons).
  await configureDependencies();

  runApp(
    BlocProvider(
      create: (_) => getIt<CharacterSelectionCubit>()..load(),
      child: MaterialApp(
        title: 'Nexus Survivor',
        color: const Color(0xFF1A1A2E),
        home: const MainMenuPage(),
      ),
    ),
  );
}
