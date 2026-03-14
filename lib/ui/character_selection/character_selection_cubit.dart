import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:nexus_survivor/domain/character_repository.dart';
import 'package:nexus_survivor/game/character/base/character_type.dart';

/// [CharacterSelectionCubit] manages the persisted character selection.
///
/// The state is the currently selected [CharacterType], or `null` when
/// no character has been chosen yet. Call [load] once at startup to
/// hydrate state from the repository and [select] whenever the player
/// picks a different character.
@injectable
class CharacterSelectionCubit extends Cubit<CharacterType?> {
  /// Creates a [CharacterSelectionCubit] backed by [repository].
  CharacterSelectionCubit(this._repository) : super(null);

  final CharacterRepository _repository;

  /// Loads the previously persisted character into state.
  void load() {
    emit(_repository.loadSelectedCharacter());
  }

  /// Saves [type] and updates state.
  void select(CharacterType type) {
    _repository.saveSelectedCharacter(type);
    emit(type);
  }
}
