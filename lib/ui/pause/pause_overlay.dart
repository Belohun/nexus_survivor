import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';

/// The overlay key registered with [GameWidget] for the pause menu.
const String pauseOverlayKey = 'pause_menu';

/// [PauseOverlay] is the Flutter widget shown when the game is paused.
///
/// Displays "Resume" and "Exit to Main Menu" buttons over a
/// semi-transparent backdrop.
class PauseOverlay extends StatelessWidget {
  /// Creates a [PauseOverlay].
  ///
  /// [game] is the current Flame game instance used to resume play.
  /// [onExitToMenu] is called when the player chooses to leave.
  const PauseOverlay({
    required this.game,
    required this.onExitToMenu,
    super.key,
  });

  /// The running Flame game.
  final Game game;

  /// Callback invoked when the player taps "Exit to Main Menu".
  final VoidCallback onExitToMenu;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        color: const Color(0xAA000000),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Paused',
                style: TextStyle(
                  color: Color(0xFFE0E0FF),
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 40),
              _PauseMenuButton(
                label: 'Resume',
                onPressed: () {
                  game.overlays.remove(pauseOverlayKey);
                  game.resumeEngine();
                },
              ),
              const SizedBox(height: 16),
              _PauseMenuButton(
                label: 'Exit to Main Menu',
                onPressed: onExitToMenu,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A simple rectangular button used inside the pause menu.
class _PauseMenuButton extends StatelessWidget {
  const _PauseMenuButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 260,
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
              fontSize: 20,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }
}
