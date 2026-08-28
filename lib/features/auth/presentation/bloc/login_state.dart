part of 'login_bloc.dart';

abstract class LoginState extends Equatable {
  const LoginState();

  @override
  List<Object?> get props => [];
}

class LoginInitial extends LoginState {
  const LoginInitial();
}

class LoginFieldErrors extends LoginState {
  const LoginFieldErrors({this.emailError, this.passwordError});

  final String? emailError;
  final String? passwordError;

  @override
  List<Object?> get props => [emailError, passwordError];
}

class LoginInProgress extends LoginState {
  const LoginInProgress();
}

class LoginSuccess extends LoginState {
  const LoginSuccess(this.user);

  final AuthUser user;

  @override
  List<Object?> get props => [user];
}

class LoginFailure extends LoginState {
  const LoginFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
