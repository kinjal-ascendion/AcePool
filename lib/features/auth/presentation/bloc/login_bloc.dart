import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:acepool/features/onboarding/domain/onboarding_selection.dart';

import '../../domain/entities/auth_exception.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/usecases/sign_in_usecase.dart';
import '../../domain/usecases/sign_in_with_microsoft_usecase.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc({
    required SignInUseCase signIn,
    required SignInWithMicrosoftUseCase signInWithMicrosoft,
  }) : _signIn = signIn,
       _signInWithMicrosoft = signInWithMicrosoft,
       super(const LoginInitial()) {
    on<LoginSubmitted>(_onLoginSubmitted);
    on<LoginFieldEdited>(_onLoginFieldEdited);
    on<LoginMicrosoftRequested>(_onLoginMicrosoftRequested);
  }

  final SignInUseCase _signIn;
  final SignInWithMicrosoftUseCase _signInWithMicrosoft;

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    final username = event.username.trim();
    final password = event.password;

    final emailError = username.isEmpty ? 'Username is required' : null;
    final passwordError = password.isEmpty
        ? 'Password is required'
        : password.length < 6
        ? 'Password must be at least 6 characters'
        : null;

    if (emailError != null || passwordError != null) {
      emit(LoginFieldErrors(emailError: emailError, passwordError: passwordError));
      return;
    }

    emit(const LoginInProgress());
    try {
      final user = await _signIn(
        username: username,
        password: password.trim(),
        onboardingSelection: event.onboardingSelection,
      );
      emit(LoginSuccess(user));
    } on AuthException catch (e) {
      emit(LoginFailure(e.message));
    } catch (_) {
      emit(const LoginFailure('Login failed. Please try again.'));
    }
  }

  Future<void> _onLoginMicrosoftRequested(
    LoginMicrosoftRequested event,
    Emitter<LoginState> emit,
  ) async {
    emit(const LoginInProgress());
    try {
      final user = await _signInWithMicrosoft();
      emit(LoginSuccess(user));
    } on SsoCancelledException {
      emit(const LoginInitial());
    } on AuthException catch (e) {
      emit(LoginFailure(e.message));
    } catch (_) {
      emit(const LoginFailure('Microsoft sign-in failed. Please try again.'));
    }
  }

  void _onLoginFieldEdited(LoginFieldEdited event, Emitter<LoginState> emit) {
    final current = state;
    if (current is! LoginFieldErrors) return;
    emit(
      LoginFieldErrors(
        emailError: event.field == LoginField.email
            ? null
            : current.emailError,
        passwordError: event.field == LoginField.password
            ? null
            : current.passwordError,
      ),
    );
  }
}
