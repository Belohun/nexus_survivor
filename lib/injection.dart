import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injection.config.dart';

/// The global [GetIt] service locator instance.
final GetIt getIt = GetIt.instance;

/// Initialises all registered dependencies.
///
/// Must be awaited before [runApp] is called so that async singletons
/// (e.g. the ObjectBox store) are ready when the widget tree builds.
@InjectableInit()
Future<void> configureDependencies() => getIt.init();
