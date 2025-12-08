import 'package:apg_scanner/data/repositories/auth_repository.dart';
import 'package:get_it/get_it.dart';

import '../../data/services/supabase_service.dart';
import '../../presentation/login_page/login_block/login_bloc.dart';

final getIt = GetIt.instance;

void setupGetIt() {
  getIt.registerLazySingleton<AuthService>(() => AuthService());
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(getIt<AuthService>()),
  );

  getIt.registerFactory<LoginBloc>(() => LoginBloc(getIt<AuthRepository>()));
}
