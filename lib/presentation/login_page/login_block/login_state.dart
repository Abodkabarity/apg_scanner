import 'package:equatable/equatable.dart';

enum LoginStatus { idle, authenticating, syncing, success, failure }

class LoginState extends Equatable {
  final LoginStatus status;
  final String? message;
  final String? error;
  final bool isObscure;

  const LoginState({
    this.status = LoginStatus.idle,
    this.message,
    this.error,
    this.isObscure = false,
  });

  bool get isLoading =>
      status == LoginStatus.authenticating || status == LoginStatus.syncing;

  bool get isSuccess => status == LoginStatus.success;

  LoginState copyWith({
    LoginStatus? status,
    String? message,
    String? error,
    bool? isObscure,
  }) {
    return LoginState(
      status: status ?? this.status,
      message: message ?? this.message,
      isObscure: isObscure ?? this.isObscure,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, message, error, isObscure];
}
