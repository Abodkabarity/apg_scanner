import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/di/injection.dart';
import '../../../core/session/user_session.dart';
import '../../../data/repositories/auth_repository.dart';
import 'login_event.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthRepository authRepository;

  LoginBloc(this.authRepository) : super(const LoginState()) {
    on<LoginSubmitted>(_onLogin);
  }
  final user = Supabase.instance.client.auth.currentUser;

  Future<void> _onLogin(LoginSubmitted event, Emitter<LoginState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      await authRepository.login(event.email, event.password);
      final profile = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user!.id)
          .single();

      getIt<UserSession>().setUser(
        email: profile['email'],
        branch: profile['branch_name'],
      );

      /*final productsRepo = getIt<ProductsRepository>();
      // await productsRepo.syncProducts();*/
      emit(state.copyWith(isLoading: false, isSuccess: true));
    } catch (e) {
      emit(
        state.copyWith(isLoading: false, error: "Invalid email or password"),
      );
    }
  }
}
