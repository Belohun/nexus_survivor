import 'package:flutter/widgets.dart';
import 'package:nexus_survivor/game/game_page/game_page.dart';

/// [MainMenuPage] is the entry screen of the application.
///
/// Displays a centred title and a list of menu options. Currently only
/// the "Dev Level" button is available — it navigates to the
/// [GamePage] which boots the development game variant.
class MainMenuPage extends StatelessWidget {
  /// Creates a [MainMenuPage].
  const MainMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        color: const Color(0xFF1A1A2E),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Nexus Survivor',
                style: TextStyle(
                  color: Color(0xFFE0E0FF),
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 60),
              _MenuButton(
                label: 'Dev Level',
                onPressed: () => _navigateToGame(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToGame(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const GamePage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}

/// A simple rectangular menu button with a border.
class _MenuButton extends StatelessWidget {
  const _MenuButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 220,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        decoration: BoxDecoration(
          color: const Color(0xFF16213E),
          border: Border.all(color: const Color(0xFF0F3460), width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFFE0E0FF),
              fontSize: 22,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }
}
