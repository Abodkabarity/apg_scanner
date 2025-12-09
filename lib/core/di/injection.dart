import 'package:apg_scanner/data/repositories/auth_repository.dart';
import 'package:get_it/get_it.dart';

import '../../data/repositories/project_repository.dart';
import '../../data/services/local_storage_service.dart';
import '../../data/services/supabase_service.dart';
import '../../presentation/add_project/project_bloc/project_bloc.dart';
import '../../presentation/login_page/login_block/login_bloc.dart';
import '../session/user_session.dart';

final getIt = GetIt.instance;

void setupGetIt() {
  getIt.registerLazySingleton<AuthService>(() => AuthService());
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(getIt<AuthService>()),
  );
  getIt.registerLazySingleton<UserSession>(() => UserSession());

  getIt.registerLazySingleton<LocalStorageService>(() => LocalStorageService());

  getIt.registerLazySingleton<ProjectRepository>(
    () => ProjectRepository(getIt<LocalStorageService>(), getIt<UserSession>()),
  );
  getIt.registerFactory<LoginBloc>(() => LoginBloc(getIt<AuthRepository>()));
  getIt.registerLazySingleton<ProjectBloc>(() => ProjectBloc(getIt()));
}
