import '../repositories/onboarding_repository.dart';

class GetOnboardingStatusUseCase {
  final OnboardingRepository _repository;

  GetOnboardingStatusUseCase(this._repository);

  Future<bool> call() => _repository.hasCompletedOnboarding();
}
