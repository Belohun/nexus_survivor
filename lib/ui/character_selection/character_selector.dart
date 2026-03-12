import 'package:flutter/widgets.dart';
import 'package:nexus_survivor/game/character/base/character_type.dart';

/// [CharacterSelector] displays a list of selectable character options.
///
/// Each [CharacterType] is rendered as a coloured preview square with a
/// label underneath. The currently selected character is highlighted
/// with a brighter border. Tapping a card updates the selection via
/// [onSelected].
///
/// Set [axis] to [Axis.vertical] to stack the cards in a column instead of
/// the default horizontal row.
class CharacterSelector extends StatelessWidget {
  /// Creates a [CharacterSelector].
  const CharacterSelector({
    super.key,
    required this.selected,
    required this.onSelected,
    this.axis = Axis.horizontal,
  });

  /// The currently selected character type.
  final CharacterType selected;

  /// Called when the player taps a different character card.
  final ValueChanged<CharacterType> onSelected;

  /// Layout direction for the card list. Defaults to [Axis.horizontal].
  final Axis axis;

  @override
  Widget build(BuildContext context) {
    final cards = [
      for (final type in CharacterType.values) ...[
        _CharacterCard(
          type: type,
          isSelected: type == selected,
          onTap: () => onSelected(type),
        ),
        if (type != CharacterType.values.last)
          axis == Axis.vertical
              ? const SizedBox(height: 16)
              : const SizedBox(width: 24),
      ],
    ];

    return axis == Axis.vertical
        ? Column(mainAxisSize: MainAxisSize.min, children: cards)
        : Row(mainAxisSize: MainAxisSize.min, children: cards);
  }
}

/// A single selectable card representing a [CharacterType].
class _CharacterCard extends StatelessWidget {
  const _CharacterCard({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  final CharacterType type;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF16213E),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4FC3F7)
                : const Color(0xFF0F3460),
            width: isSelected ? 3 : 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Coloured square placeholder preview.
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: type.placeholderColor,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFFFFFFF)
                      : const Color(0x55FFFFFF),
                  width: 2,
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Character name.
            Text(
              type.displayName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFE0E0FF),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
