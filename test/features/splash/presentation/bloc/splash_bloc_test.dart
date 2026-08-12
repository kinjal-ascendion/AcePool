import 'package:acepool/features/splash/domain/usecases/initialize_app_usecase.dart';
import 'package:acepool/features/splash/presentation/bloc/splash_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockInitializeAppUseCase extends Mock implements InitializeAppUseCase {}

void main() {
  late MockInitializeAppUseCase initializeApp;

  setUp(() {
    initializeApp = MockInitializeAppUseCase();
  });

  group('SplashEvent equality', () {
    test('SplashStarted supports value equality', () {
      expect(const SplashStarted(), const SplashStarted());
    });
  });

  group('SplashBloc', () {
    test('initial state is SplashInitial', () {
      expect(
        SplashBloc(initializeApp: initializeApp).state,
        const SplashInitial(),
      );
    });

    blocTest<SplashBloc, SplashState>(
      'emits [SplashLoading, SplashComplete] when SplashStarted succeeds',
      setUp: () {
        when(() => initializeApp()).thenAnswer((_) async {});
      },
      build: () => SplashBloc(initializeApp: initializeApp),
      act: (bloc) => bloc.add(const SplashStarted()),
      expect: () => const [
        SplashLoading(),
        SplashComplete(),
      ],
      verify: (_) {
        verify(() => initializeApp()).called(1);
      },
    );

    blocTest<SplashBloc, SplashState>(
      'emits [SplashLoading, SplashError] when SplashStarted throws',
      setUp: () {
        when(() => initializeApp()).thenThrow(Exception('boom'));
      },
      build: () => SplashBloc(initializeApp: initializeApp),
      act: (bloc) => bloc.add(const SplashStarted()),
      expect: () => [
        const SplashLoading(),
        const SplashError('Exception: boom'),
      ],
    );

    blocTest<SplashBloc, SplashState>(
      'SplashError message reflects the thrown error\'s toString()',
      setUp: () {
        when(() => initializeApp()).thenThrow(StateError('bad state'));
      },
      build: () => SplashBloc(initializeApp: initializeApp),
      act: (bloc) => bloc.add(const SplashStarted()),
      expect: () => [
        const SplashLoading(),
        isA<SplashError>()
            .having((s) => s.message, 'message', 'Bad state: bad state'),
      ],
    );

    test('SplashError supports value equality on message', () {
      expect(const SplashError('a'), const SplashError('a'));
      expect(const SplashError('a') == const SplashError('b'), isFalse);
    });
  });
}
