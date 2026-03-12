import 'package:injectable/injectable.dart';
import 'package:nexus_survivor/infrastructure/persistence/object_box_store.dart';

/// [InfrastructureModule] registers infrastructure-layer singletons
/// that require asynchronous initialisation.
@module
abstract class InfrastructureModule {
  /// Opens the ObjectBox database and registers the [ObjectBoxStore]
  /// singleton for the lifetime of the app.
  ///
  /// Marked with [preResolve] so the store is fully open before
  /// any dependent service is created.
  @preResolve
  @singleton
  Future<ObjectBoxStore> objectBoxStore() => ObjectBoxStore.create();
}
