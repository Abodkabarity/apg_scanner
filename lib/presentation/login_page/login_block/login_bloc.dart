import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/di/injection.dart';
import '../../../core/session/user_session.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/products_sync_service.dart';
import 'login_event.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthRepository authRepository;

  LoginBloc(this.authRepository) : super(const LoginState()) {
    on<LoginSubmitted>(_onLogin);
    on<ChangeObscureStatusEvent>((event, emit) {
      emit(state.copyWith(isObscure: !state.isObscure));
    });
  }

  Future<void> _onLogin(LoginSubmitted event, Emitter<LoginState> emit) async {
    /// 1️⃣ Start login loading
    emit(
      state.copyWith(
        status: LoginStatus.authenticating,
        message: "Signing in...",
        error: null,
      ),
    );

    try {
      await authRepository.login(event.email, event.password);

      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        emit(
          state.copyWith(
            status: LoginStatus.failure,
            error: "Login failed — try again",
            message: null,
          ),
        );
        return;
      }

      /// 2️⃣ Login succeeded → show syncing message (keep loading)
      emit(
        state.copyWith(
          status: LoginStatus.syncing,
          message: "Login successful ✅\nLoading product data...",
          error: null,
        ),
      );

      final profile = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', currentUser.id)
          .single();

      getIt<UserSession>().setUser(
        email: profile['email'],
        branch: profile['branch_name'],
      );

      final productsSync = getIt<ProductsSyncService>();
      await productsSync.initialSync();

      /// 3️⃣ All done
      emit(
        state.copyWith(status: LoginStatus.success, message: null, error: null),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: LoginStatus.failure,
          error: "Invalid email or password",
          message: null,
        ),
      );
    }
  }
}
