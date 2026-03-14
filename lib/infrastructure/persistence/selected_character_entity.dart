import 'package:objectbox/objectbox.dart';

/// [SelectedCharacterEntity] stores the player's last chosen character name.
///
/// Only one row is kept in the box (id == 1). The [characterName] matches
/// a [CharacterType.name] value so it can be resolved back into the enum.
@Entity()
class SelectedCharacterEntity {
  /// Creates a [SelectedCharacterEntity].
  SelectedCharacterEntity({this.id = 0, this.characterName = ''});

  /// ObjectBox auto-assigned id.
  @Id()
  int id;

  /// The [CharacterType.name] of the selected character.
  String characterName;
}
