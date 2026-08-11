part of 'login_bloc.dart';

abstract class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object?> get props => [];
}

class LoginSubmitted extends LoginEvent {
  const LoginSubmitted({
    required this.username,
    required this.password,
    this.onboardingSelection,
  });

  final String username;
  final String password;
  final OnboardingSelection? onboardingSelection;

  @override
  List<Object?> get props => [username, password, onboardingSelection];
}

enum LoginField { email, password }

class LoginFieldEdited extends LoginEvent {
  const LoginFieldEdited(this.field);

  final LoginField field;

  @override
  List<Object?> get props => [field];
}
