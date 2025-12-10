import 'package:apg_scanner/data/repositories/auth_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/remote/products_remote_service.dart';
import '../../data/remote/stock_remote_service.dart';
import '../../data/repositories/products_repository.dart';
import '../../data/repositories/project_repository.dart';
import '../../data/repositories/stock_taking_repository.dart';
import '../../data/services/local_storage_service.dart';
import '../../data/services/products_local_service.dart';
import '../../data/services/stock_local_service.dart';
import '../../data/services/supabase_service.dart';
import '../../presentation/add_project/project_bloc/project_bloc.dart';
import '../../presentation/login_page/login_block/login_bloc.dart';
import '../../presentation/stock_taking/stock_taking_bloc/stock_taking_bloc.dart';
import '../session/user_session.dart';

final getIt = GetIt.instance;

void setupGetIt() {
  // Auth
  getIt.registerLazySingleton<AuthService>(() => AuthService());
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(getIt<AuthService>()),
  );
  getIt.registerLazySingleton<UserSession>(() => UserSession());

  // Local storage
  getIt.registerLazySingleton<LocalStorageService>(() => LocalStorageService());

  // Projects
  getIt.registerLazySingleton<ProjectRepository>(
    () => ProjectRepository(getIt<LocalStorageService>(), getIt<UserSession>()),
  );

  getIt.registerFactory<LoginBloc>(() => LoginBloc(getIt<AuthRepository>()));
  getIt.registerLazySingleton<ProjectBloc>(() => ProjectBloc(getIt()));

  // Products
  getIt.registerLazySingleton(() => ProductsLocalService());
  getIt.registerLazySingleton(
    () => ProductsRemoteService(Supabase.instance.client),
  );
  getIt.registerLazySingleton(
    () => ProductsRepository(
      local: getIt<ProductsLocalService>(),
      remote: getIt<ProductsRemoteService>(),
    ),
  );

  // Stock Taking (IMPORTANT!)
  getIt.registerLazySingleton(() => StockLocalService());
  getIt.registerLazySingleton(
    () => StockRemoteService(Supabase.instance.client),
  );
  getIt.registerLazySingleton(
    () => StockRepository(
      getIt<StockLocalService>(),
      getIt<StockRemoteService>(),
      getIt<UserSession>(),
    ),
  );

  getIt.registerFactory<StockBloc>(
    () => StockBloc(getIt<StockRepository>(), getIt<ProductsRepository>()),
  );
}
