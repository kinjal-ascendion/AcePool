import 'package:acepool/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late OnboardingRepositoryImpl repository;

  group('OnboardingRepositoryImpl', () {
    group('hasCompletedOnboarding', () {
      test('returns false when no value has been persisted yet', () async {
        SharedPreferences.setMockInitialValues({});
        repository = OnboardingRepositoryImpl();

        final result = await repository.hasCompletedOnboarding();

        expect(result, isFalse);
      });

      test('returns true when has_completed_onboarding is set to true',
          () async {
        SharedPreferences.setMockInitialValues({
          'has_completed_onboarding': true,
        });
        repository = OnboardingRepositoryImpl();

        final result = await repository.hasCompletedOnboarding();

        expect(result, isTrue);
      });

      test('returns false when has_completed_onboarding is explicitly false',
          () async {
        SharedPreferences.setMockInitialValues({
          'has_completed_onboarding': false,
        });
        repository = OnboardingRepositoryImpl();

        final result = await repository.hasCompletedOnboarding();

        expect(result, isFalse);
      });
    });

    group('markOnboardingCompleted', () {
      test('persists true so a subsequent read reflects completion',
          () async {
        SharedPreferences.setMockInitialValues({});
        repository = OnboardingRepositoryImpl();

        await repository.markOnboardingCompleted();

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('has_completed_onboarding'), isTrue);
        expect(await repository.hasCompletedOnboarding(), isTrue);
      });

      test('overwrites a previously persisted false value with true',
          () async {
        SharedPreferences.setMockInitialValues({
          'has_completed_onboarding': false,
        });
        repository = OnboardingRepositoryImpl();

        await repository.markOnboardingCompleted();

        expect(await repository.hasCompletedOnboarding(), isTrue);
      });
    });
  });
}
