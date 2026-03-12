// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:nexus_survivor/domain/character_repository.dart' as _i745;
import 'package:nexus_survivor/infrastructure/infrastructure_module.dart'
    as _i414;
import 'package:nexus_survivor/infrastructure/persistence/object_box_character_repository.dart'
    as _i889;
import 'package:nexus_survivor/infrastructure/persistence/object_box_store.dart'
    as _i569;
import 'package:nexus_survivor/ui/character_selection/character_selection_cubit.dart'
    as _i999;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final infrastructureModule = _$InfrastructureModule();
    await gh.singletonAsync<_i569.ObjectBoxStore>(
      () => infrastructureModule.objectBoxStore(),
      preResolve: true,
    );
    gh.singleton<_i745.CharacterRepository>(
      () => _i889.ObjectBoxCharacterRepository(gh<_i569.ObjectBoxStore>()),
    );
    gh.factory<_i999.CharacterSelectionCubit>(
      () => _i999.CharacterSelectionCubit(gh<_i745.CharacterRepository>()),
    );
    return this;
  }
}

class _$InfrastructureModule extends _i414.InfrastructureModule {}
