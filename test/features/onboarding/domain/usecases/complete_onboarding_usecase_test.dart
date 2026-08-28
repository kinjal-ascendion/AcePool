import 'package:acepool/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:acepool/features/onboarding/domain/usecases/complete_onboarding_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockOnboardingRepository extends Mock implements OnboardingRepository {}

void main() {
  late MockOnboardingRepository repository;
  late CompleteOnboardingUseCase useCase;

  setUp(() {
    repository = MockOnboardingRepository();
    useCase = CompleteOnboardingUseCase(repository);
  });

  group('CompleteOnboardingUseCase', () {
    test('forwards call to repository.markOnboardingCompleted', () async {
      when(() => repository.markOnboardingCompleted())
          .thenAnswer((_) async {});

      await useCase();

      verify(() => repository.markOnboardingCompleted()).called(1);
      verifyNoMoreInteractions(repository);
    });

    test('completes successfully when repository succeeds', () async {
      when(() => repository.markOnboardingCompleted())
          .thenAnswer((_) async {});

      await expectLater(useCase(), completes);
    });

    test('propagates exceptions thrown by the repository', () async {
      final exception = Exception('failed to persist');
      when(() => repository.markOnboardingCompleted()).thenThrow(exception);

      expect(() => useCase(), throwsA(exception));
    });
  });
}
