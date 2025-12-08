import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/auth_repository.dart';
import 'login_event.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthRepository authRepository;

  LoginBloc(this.authRepository) : super(const LoginState()) {
    on<LoginSubmitted>(_onLogin);
  }

  Future<void> _onLogin(LoginSubmitted event, Emitter<LoginState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      await authRepository.login(event.email, event.password);
      emit(state.copyWith(isLoading: false, isSuccess: true));
    } catch (e) {
      emit(
        state.copyWith(isLoading: false, error: "Invalid email or password"),
      );
    }
  }
}
