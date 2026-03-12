import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nexus_survivor/game/character/base/character_type.dart';
import 'package:nexus_survivor/game/game_page/game_page.dart';
import 'package:nexus_survivor/ui/character_selection/character_selection_cubit.dart';
import 'package:nexus_survivor/ui/character_selection/character_selector.dart';

/// [CharacterSelectionPage] lets the player pick a character before starting
/// a game session.
///
/// Displays a [CharacterSelector] row and a detail panel for the currently
/// highlighted [CharacterType]. Tapping a character card immediately invokes
/// [CharacterSelectionCubit.select], persisting the choice and rebuilding the
/// page. A "Play" button navigates to [GamePage] with the chosen character,
/// and a back arrow returns to the main menu.
class CharacterSelectionPage extends StatelessWidget {
  /// Creates a [CharacterSelectionPage].
  ///
  /// [initialCharacter] is used as the fallback selection when the cubit
  /// state is `null`. Defaults to [CharacterType.devGunner].
  const CharacterSelectionPage({
    super.key,
    this.initialCharacter = CharacterType.devGunner,
  });

  /// The character highlighted when the page first opens and no prior
  /// selection exists in the cubit.
  final CharacterType initialCharacter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        leading: _BackButton(onPressed: () => Navigator.of(context).pop()),
        title: Text(
          'Choose Your Character',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFFE0E0FF),
            fontSize: 32,
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.none,
          ),
        ),
        centerTitle: true,
      ),

      body: BlocBuilder<CharacterSelectionCubit, CharacterType?>(
        builder: (context, state) {
          final selected = state ?? initialCharacter;
          return Directionality(
            textDirection: TextDirection.ltr,
            child: Container(
              color: const Color(0xFF1A1A2E),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Left: character details.
                      Expanded(
                        child: Center(
                          child: _CharacterDetailPanel(type: selected),
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Right: vertical character list.
                      SingleChildScrollView(
                        child: CharacterSelector(
                          axis: Axis.vertical,
                          selected: selected,
                          onSelected: (type) => context
                              .read<CharacterSelectionCubit>()
                              .select(type),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
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
}

/// A translucent card that displays the name, colour swatch, and description
/// of the given [CharacterType].
class _CharacterDetailPanel extends StatelessWidget {
  const _CharacterDetailPanel({required this.type});

  final CharacterType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0x22FFFFFF),
        border: Border.all(color: const Color(0xFF0F3460), width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: type.placeholderColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                type.displayName,
                style: const TextStyle(
                  color: Color(0xFFE0E0FF),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            type.description,
            style: const TextStyle(
              color: Color(0xAAE0E0FF),
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.5,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}

/// A large primary action button labelled "Play".
class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 220,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        decoration: BoxDecoration(
          color: const Color(0xFF0F3460),
          border: Border.all(color: const Color(0xFF4FC3F7), width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'Play',
            style: TextStyle(
              color: Color(0xFF4FC3F7),
              fontSize: 22,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }
}

/// A small arrow button used to return to the previous route.
class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF16213E),
          border: Border.all(color: const Color(0xFF0F3460), width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          '← Back',
          style: TextStyle(
            color: Color(0xFFE0E0FF),
            fontSize: 16,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}
