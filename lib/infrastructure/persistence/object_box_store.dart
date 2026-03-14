import 'package:nexus_survivor/infrastructure/persistence/selected_character_entity.dart';
import 'package:nexus_survivor/objectbox.g.dart';

/// [ObjectBoxStore] manages the ObjectBox [Store] lifecycle and provides
/// convenient access to individual boxes.
///
/// Call [ObjectBoxStore.create] once during app startup and keep the
/// singleton available for the rest of the app's lifetime.
class ObjectBoxStore {
  ObjectBoxStore._create(this._store);

  final Store _store;

  /// Opens (or creates) the ObjectBox database and returns a ready-to-use
  /// [ObjectBoxStore] instance.
  static Future<ObjectBoxStore> create() async {
    final store = await openStore();
    return ObjectBoxStore._create(store);
  }

  /// Returns the box for [SelectedCharacterEntity].
  Box<SelectedCharacterEntity> get selectedCharacterBox =>
      _store.box<SelectedCharacterEntity>();

  /// Closes the underlying store. Call when the app shuts down.
  void close() => _store.close();
}
