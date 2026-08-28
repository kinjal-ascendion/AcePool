import 'package:acepool/features/auth/domain/entities/auth_exception.dart';
import 'package:acepool/features/auth/domain/entities/auth_user.dart';
import 'package:acepool/features/auth/domain/repositories/auth_repository.dart';
import 'package:acepool/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:acepool/features/onboarding/domain/entities/travel_preference.dart';
import 'package:acepool/features/onboarding/domain/entities/vehicle_preference.dart';
import 'package:acepool/features/onboarding/domain/onboarding_selection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;
  late SignInUseCase useCase;

  setUpAll(() {
    registerFallbackValue(
      const OnboardingSelection(
        travelPreference: TravelPreference.ride,
        vehicleType: VehiclePreference.car,
      ),
    );
  });

  setUp(() {
    repository = MockAuthRepository();
    useCase = SignInUseCase(repository);
  });

  const user = AuthUser(uid: 'uid-1', email: 'jane@ascendion.com');

  test('forwards username, password and onboardingSelection to the repository', () async {
    const selection = OnboardingSelection(
      travelPreference: TravelPreference.drive,
      vehicleType: VehiclePreference.bike,
    );
    when(
      () => repository.signIn(
        username: any(named: 'username'),
        password: any(named: 'password'),
        onboardingSelection: any(named: 'onboardingSelection'),
      ),
    ).thenAnswer((_) async => user);

    final result = await useCase(
      username: 'jane',
      password: 'secret1',
      onboardingSelection: selection,
    );

    expect(result, user);
    verify(
      () => repository.signIn(
        username: 'jane',
        password: 'secret1',
        onboardingSelection: selection,
      ),
    ).called(1);
  });

  test('forwards a null onboardingSelection when not provided', () async {
    when(
      () => repository.signIn(
        username: any(named: 'username'),
        password: any(named: 'password'),
        onboardingSelection: any(named: 'onboardingSelection'),
      ),
    ).thenAnswer((_) async => user);

    final result = await useCase(username: 'jane', password: 'secret1');

    expect(result, user);
    verify(
      () => repository.signIn(
        username: 'jane',
        password: 'secret1',
        onboardingSelection: null,
      ),
    ).called(1);
  });

  test('propagates AuthException thrown by the repository', () async {
    when(
      () => repository.signIn(
        username: any(named: 'username'),
        password: any(named: 'password'),
        onboardingSelection: any(named: 'onboardingSelection'),
      ),
    ).thenThrow(const AuthException('Invalid username or password'));

    expect(
      () => useCase(username: 'jane', password: 'wrong'),
      throwsA(isA<AuthException>()),
    );
  });
}
