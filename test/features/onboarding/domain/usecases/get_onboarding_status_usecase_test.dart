import 'package:acepool/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:acepool/features/onboarding/domain/usecases/get_onboarding_status_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockOnboardingRepository extends Mock implements OnboardingRepository {}

void main() {
  late MockOnboardingRepository repository;
  late GetOnboardingStatusUseCase useCase;

  setUp(() {
    repository = MockOnboardingRepository();
    useCase = GetOnboardingStatusUseCase(repository);
  });

  group('GetOnboardingStatusUseCase', () {
    test('forwards call to repository.hasCompletedOnboarding and returns true',
        () async {
      when(() => repository.hasCompletedOnboarding())
          .thenAnswer((_) async => true);

      final result = await useCase();

      expect(result, isTrue);
      verify(() => repository.hasCompletedOnboarding()).called(1);
      verifyNoMoreInteractions(repository);
    });

    test('returns false when repository reports onboarding incomplete',
        () async {
      when(() => repository.hasCompletedOnboarding())
          .thenAnswer((_) async => false);

      final result = await useCase();

      expect(result, isFalse);
    });

    test('propagates exceptions thrown by the repository', () async {
      final exception = Exception('failed to read status');
      when(() => repository.hasCompletedOnboarding()).thenThrow(exception);

      expect(() => useCase(), throwsA(exception));
    });
  });
}
