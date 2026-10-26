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
import 'package:msp430_lab/core/injection/register_module.dart' as _i894;
import 'package:msp430_lab/core/layout/layout_reader.dart' as _i33;
import 'package:msp430_lab/core/router/router_config.dart' as _i447;
import 'package:msp430_lab/core/services/haptics/haptics_service.dart' as _i823;
import 'package:msp430_lab/core/services/localization/locale_service.dart'
    as _i6;
import 'package:msp430_lab/core/services/storage/storage_service.dart' as _i717;
import 'package:msp430_lab/features/root/data/datasources/root_local_datasource.dart'
    as _i174;
import 'package:msp430_lab/features/root/data/repositories/root_repository_impl.dart'
    as _i1069;
import 'package:msp430_lab/features/root/domain/facade/root_facade.dart'
    as _i511;
import 'package:msp430_lab/features/root/domain/repositories/root_repository.dart'
    as _i490;
import 'package:msp430_lab/features/root/presentation/states/root_bloc.dart'
    as _i854;
import 'package:msp430_lab/features/root/presentation/ui/widgets/nav_bar/navigation_controller.dart'
    as _i245;
import 'package:msp430_lab/features/root/presentation/ui/widgets/nav_bar/side_nav_controller.dart'
    as _i409;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    gh.lazySingleton<_i717.StorageService>(() => registerModule.storageService);
    gh.lazySingleton<_i823.HapticsService>(() => registerModule.haptics);
    gh.lazySingleton<_i33.LayoutReader>(
      () => _i33.LayoutReader(),
      dispose: (i) => i.dispose(),
    );
    gh.lazySingleton<_i447.AppRouteRegistry>(() => _i447.AppRouteRegistry());
    gh.lazySingleton<_i174.RootLocalDataSource>(
      () => const _i174.RootLocalDataSource(),
    );
    gh.lazySingleton<_i245.NavigationController>(
      () => _i245.NavigationController(),
    );
    gh.lazySingleton<_i447.AppRouterConfig>(
      () => _i447.AppRouterConfig(gh<_i447.AppRouteRegistry>()),
    );
    gh.lazySingleton<_i490.RootRepository>(
      () => _i1069.RootRepositoryImpl(gh<_i174.RootLocalDataSource>()),
    );
    gh.lazySingleton<_i6.LocaleService>(
      () => _i6.LocaleService(gh<_i717.StorageService>()),
    );
    gh.lazySingleton<_i409.SideNavController>(
      () => _i409.SideNavController(gh<_i717.StorageService>()),
    );
    gh.lazySingleton<_i511.RootFacade>(
      () => _i511.RootFacade(gh<_i490.RootRepository>()),
    );
    gh.factory<_i854.RootBloc>(() => _i854.RootBloc(gh<_i511.RootFacade>()));
    return this;
  }
}

class _$RegisterModule extends _i894.RegisterModule {}
