import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nexus_survivor/game/character/base/character_type.dart';
import 'package:nexus_survivor/game/game_page/game_page.dart';
import 'package:nexus_survivor/ui/character_selection/character_selection_cubit.dart';
import 'package:nexus_survivor/ui/character_selection/character_selection_page.dart';

/// [MainMenuPage] is the entry screen of the application.
///
/// Displays a centred title, the previously selected character (if any), and
/// a list of menu options. "Character Selection" navigates to
/// [CharacterSelectionPage] where the player picks their character and then
/// starts the game. "Dev Level" is a quick shortcut that launches [GamePage]
/// immediately with the [CharacterType.devGunner].
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
              const SizedBox(height: 24),
              BlocBuilder<CharacterSelectionCubit, CharacterType?>(
                builder: (context, savedCharacter) {
                  if (savedCharacter != null) {
                    return _SelectedCharacterBadge(type: savedCharacter);
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 24),
              _MenuButton(
                label: 'Character selection',
                onPressed: () => _navigateToCharacterSelection(context),
              ),
              const SizedBox(height: 16),
              BlocBuilder<CharacterSelectionCubit, CharacterType?>(
                builder: (context, selected) => _MenuButton(
                  label: 'Dev Level',
                  enabled: selected != null,
                  onPressed: () {
                    if (selected != null) {
                      _navigateToGame(context, selected);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToGame(BuildContext context, CharacterType characterType) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, animation, _) =>
            GamePage(characterType: characterType),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  void _navigateToCharacterSelection(BuildContext context) {
    Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        pageBuilder: (_, animation, _) => const CharacterSelectionPage(),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }
}

/// Displays the currently saved character name and colour swatch.
class _SelectedCharacterBadge extends StatelessWidget {
  const _SelectedCharacterBadge({required this.type});

  final CharacterType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0x22FFFFFF),
        border: Border.all(color: const Color(0xFF0F3460), width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: type.placeholderColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Selected: ${type.displayName}',
            style: const TextStyle(
              color: Color(0xFFE0E0FF),
              fontSize: 18,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}

/// A simple rectangular menu button with a border.
///
/// When [enabled] is `false` the button appears dimmed and taps are ignored.
class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.label,
    required this.onPressed,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.4,
        child: Container(
          width: 350,
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
      ),
    );
  }
}
