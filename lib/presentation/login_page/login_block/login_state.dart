import 'package:equatable/equatable.dart';

enum LoginStatus { idle, authenticating, syncing, success, failure }

class LoginState extends Equatable {
  final LoginStatus status;
  final String? message;
  final String? error;
  final bool isObscure;
  final bool navToHome;
  const LoginState({
    this.status = LoginStatus.idle,
    this.message,
    this.error,
    this.isObscure = false,
    this.navToHome = false,
  });

  bool get isLoading =>
      status == LoginStatus.authenticating || status == LoginStatus.syncing;

  bool get isSuccess => status == LoginStatus.success;

  LoginState copyWith({
    LoginStatus? status,
    String? message,
    String? error,
    bool? isObscure,
    bool? navToHome,
    bool clearMessage = false,
    bool clearError = false,
  }) {
    return LoginState(
      status: status ?? this.status,
      message: clearMessage ? null : (message ?? this.message),
      error: clearError ? null : (error ?? this.error),
      isObscure: isObscure ?? this.isObscure,
      navToHome: navToHome ?? this.navToHome,
    );
  }

  @override
  List<Object?> get props => [status, message, error, isObscure, navToHome];
}
