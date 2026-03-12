import 'package:injectable/injectable.dart';
import 'package:nexus_survivor/domain/character_repository.dart';
import 'package:nexus_survivor/game/character/base/character_type.dart';
import 'package:nexus_survivor/infrastructure/persistence/object_box_store.dart';
import 'package:nexus_survivor/infrastructure/persistence/selected_character_entity.dart';

/// [ObjectBoxCharacterRepository] persists and retrieves the player's
/// character selection using the ObjectBox database.
@Singleton(as: CharacterRepository)
class ObjectBoxCharacterRepository implements CharacterRepository {
  /// Creates an [ObjectBoxCharacterRepository] backed by [store].
  ObjectBoxCharacterRepository(this._store);

  final ObjectBoxStore _store;

  /// Persists the chosen [CharacterType] so it survives app restarts.
  ///
  /// Uses `id: 0` on the first save so ObjectBox assigns an ID from its
  /// sequence. On subsequent saves the existing row's id is reused so the
  /// call becomes an update rather than a conflicting insert.
  @override
  void saveSelectedCharacter(CharacterType type) {
    final box = _store.selectedCharacterBox;
    final existing = box.get(1);
    box.put(
      SelectedCharacterEntity(
        id: existing?.id ?? 0,
        characterName: type.name,
      ),
    );
  }

  /// Loads the previously saved [CharacterType], or `null` when no
  /// selection has been persisted yet.
  @override
  CharacterType? loadSelectedCharacter() {
    final entity = _store.selectedCharacterBox.get(1);
    if (entity == null) {
      return null;
    }
    // Resolve enum value by its programmatic name.
    for (final type in CharacterType.values) {
      if (type.name == entity.characterName) {
        return type;
      }
    }
    return null;
  }
}

