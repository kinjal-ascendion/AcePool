import 'package:acepool/features/onboarding/domain/onboarding_selection.dart';

import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

class SignInUseCase {
  SignInUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthUser> call({
    required String username,
    required String password,
    OnboardingSelection? onboardingSelection,
  }) {
    return _repository.signIn(
      username: username,
      password: password,
      onboardingSelection: onboardingSelection,
    );
  }
}
