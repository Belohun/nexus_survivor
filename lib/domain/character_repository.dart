import 'package:nexus_survivor/game/character/base/character_type.dart';

/// [CharacterRepository] defines the contract for persisting and
/// retrieving the player's character selection.
abstract class CharacterRepository {
  /// Loads the previously saved [CharacterType], or `null` when no
  /// selection has been persisted yet.
  CharacterType? loadSelectedCharacter();

  /// Persists the chosen [CharacterType] so it survives app restarts.
  void saveSelectedCharacter(CharacterType type);
}
