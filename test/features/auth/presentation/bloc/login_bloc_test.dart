import 'package:acepool/features/auth/domain/entities/auth_exception.dart';
import 'package:acepool/features/auth/domain/entities/auth_user.dart';
import 'package:acepool/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:acepool/features/auth/presentation/bloc/login_bloc.dart';
import 'package:acepool/features/onboarding/domain/entities/travel_preference.dart';
import 'package:acepool/features/onboarding/domain/entities/vehicle_preference.dart';
import 'package:acepool/features/onboarding/domain/onboarding_selection.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSignInUseCase extends Mock implements SignInUseCase {}

void main() {
  late MockSignInUseCase signIn;

  setUpAll(() {
    registerFallbackValue(
      const OnboardingSelection(
        travelPreference: TravelPreference.ride,
        vehicleType: VehiclePreference.car,
      ),
    );
  });

  setUp(() {
    signIn = MockSignInUseCase();
  });

  const user = AuthUser(uid: 'uid-1', email: 'jdoe@ascendion.com');

  LoginBloc buildBloc() => LoginBloc(signIn: signIn);

  group('LoginEvent equality', () {
    test('LoginSubmitted supports value equality based on props', () {
      expect(
        const LoginSubmitted(username: 'jdoe', password: 'secret1'),
        const LoginSubmitted(username: 'jdoe', password: 'secret1'),
      );
      expect(
        const LoginSubmitted(username: 'jdoe', password: 'secret1').props,
        ['jdoe', 'secret1', null],
      );
      expect(
        const LoginSubmitted(username: 'jdoe', password: 'secret1'),
        isNot(const LoginSubmitted(username: 'other', password: 'secret1')),
      );
      expect(
        const LoginSubmitted(username: 'jdoe', password: 'secret1'),
        isNot(const LoginSubmitted(username: 'jdoe', password: 'other')),
      );
      const selection = OnboardingSelection(
        travelPreference: TravelPreference.ride,
        vehicleType: VehiclePreference.car,
      );
      expect(
        const LoginSubmitted(
          username: 'jdoe',
          password: 'secret1',
          onboardingSelection: selection,
        ),
        isNot(const LoginSubmitted(username: 'jdoe', password: 'secret1')),
      );
      expect(
        const LoginSubmitted(
          username: 'jdoe',
          password: 'secret1',
          onboardingSelection: selection,
        ).props,
        ['jdoe', 'secret1', selection],
      );
    });

    test('LoginFieldEdited supports value equality based on props', () {
      expect(
        const LoginFieldEdited(LoginField.email),
        const LoginFieldEdited(LoginField.email),
      );
      expect(
        const LoginFieldEdited(LoginField.email).props,
        [LoginField.email],
      );
      expect(
        const LoginFieldEdited(LoginField.email),
        isNot(const LoginFieldEdited(LoginField.password)),
      );
    });
  });

  group('LoginSubmitted validation', () {
    blocTest<LoginBloc, LoginState>(
      'emits field errors when username and password are empty',
      build: buildBloc,
      act: (bloc) =>
          bloc.add(const LoginSubmitted(username: '', password: '')),
      expect: () => [
        const LoginFieldErrors(
          emailError: 'Username is required',
          passwordError: 'Password is required',
        ),
      ],
      verify: (_) {
        verifyNever(
          () => signIn(
            username: any(named: 'username'),
            password: any(named: 'password'),
            onboardingSelection: any(named: 'onboardingSelection'),
          ),
        );
      },
    );

    blocTest<LoginBloc, LoginState>(
      'emits a password error when the password is shorter than 6 characters',
      build: buildBloc,
      act: (bloc) =>
          bloc.add(const LoginSubmitted(username: 'jdoe', password: '123')),
      expect: () => [
        const LoginFieldErrors(
          emailError: null,
          passwordError: 'Password must be at least 6 characters',
        ),
      ],
    );

    blocTest<LoginBloc, LoginState>(
      'treats a whitespace-only username as empty',
      build: buildBloc,
      act: (bloc) =>
          bloc.add(const LoginSubmitted(username: '   ', password: 'secret1')),
      expect: () => [
        const LoginFieldErrors(
          emailError: 'Username is required',
          passwordError: null,
        ),
      ],
    );
  });

  group('LoginSubmitted success/failure', () {
    blocTest<LoginBloc, LoginState>(
      'emits [LoginInProgress, LoginSuccess] on success',
      setUp: () {
        when(
          () => signIn(
            username: any(named: 'username'),
            password: any(named: 'password'),
            onboardingSelection: any(named: 'onboardingSelection'),
          ),
        ).thenAnswer((_) async => user);
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const LoginSubmitted(username: 'jdoe', password: 'secret1'),
      ),
      expect: () => [const LoginInProgress(), const LoginSuccess(user)],
      verify: (_) {
        verify(
          () => signIn(
            username: 'jdoe',
            password: 'secret1',
            onboardingSelection: null,
          ),
        ).called(1);
      },
    );

    blocTest<LoginBloc, LoginState>(
      'trims username and password before calling the use case',
      setUp: () {
        when(
          () => signIn(
            username: any(named: 'username'),
            password: any(named: 'password'),
            onboardingSelection: any(named: 'onboardingSelection'),
          ),
        ).thenAnswer((_) async => user);
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const LoginSubmitted(username: '  jdoe  ', password: '  secret1  '),
      ),
      expect: () => [const LoginInProgress(), const LoginSuccess(user)],
      verify: (_) {
        verify(
          () => signIn(
            username: 'jdoe',
            password: 'secret1',
            onboardingSelection: null,
          ),
        ).called(1);
      },
    );

    blocTest<LoginBloc, LoginState>(
      'forwards onboardingSelection to the use case',
      setUp: () {
        when(
          () => signIn(
            username: any(named: 'username'),
            password: any(named: 'password'),
            onboardingSelection: any(named: 'onboardingSelection'),
          ),
        ).thenAnswer((_) async => user);
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const LoginSubmitted(
          username: 'jdoe',
          password: 'secret1',
          onboardingSelection: OnboardingSelection(
            travelPreference: TravelPreference.both,
            vehicleType: VehiclePreference.both,
          ),
        ),
      ),
      expect: () => [const LoginInProgress(), const LoginSuccess(user)],
      verify: (_) {
        verify(
          () => signIn(
            username: 'jdoe',
            password: 'secret1',
            onboardingSelection: const OnboardingSelection(
              travelPreference: TravelPreference.both,
              vehicleType: VehiclePreference.both,
            ),
          ),
        ).called(1);
      },
    );

    blocTest<LoginBloc, LoginState>(
      'emits [LoginInProgress, LoginFailure] with the AuthException message on failure',
      setUp: () {
        when(
          () => signIn(
            username: any(named: 'username'),
            password: any(named: 'password'),
            onboardingSelection: any(named: 'onboardingSelection'),
          ),
        ).thenThrow(const AuthException('Invalid username or password'));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const LoginSubmitted(username: 'jdoe', password: 'secret1'),
      ),
      expect: () => [
        const LoginInProgress(),
        const LoginFailure('Invalid username or password'),
      ],
    );

    blocTest<LoginBloc, LoginState>(
      'emits [LoginInProgress, LoginFailure] with a generic message on unexpected errors',
      setUp: () {
        when(
          () => signIn(
            username: any(named: 'username'),
            password: any(named: 'password'),
            onboardingSelection: any(named: 'onboardingSelection'),
          ),
        ).thenThrow(Exception('boom'));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const LoginSubmitted(username: 'jdoe', password: 'secret1'),
      ),
      expect: () => [
        const LoginInProgress(),
        const LoginFailure('Login failed. Please try again.'),
      ],
    );
  });

  group('LoginFieldEdited', () {
    blocTest<LoginBloc, LoginState>(
      'does nothing when the current state is not LoginFieldErrors',
      build: buildBloc,
      act: (bloc) => bloc.add(const LoginFieldEdited(LoginField.email)),
      expect: () => <LoginState>[],
    );

    blocTest<LoginBloc, LoginState>(
      'clears the email error when the email field is edited',
      build: buildBloc,
      seed: () => const LoginFieldErrors(
        emailError: 'Username is required',
        passwordError: 'Password is required',
      ),
      act: (bloc) => bloc.add(const LoginFieldEdited(LoginField.email)),
      expect: () => [
        const LoginFieldErrors(
          emailError: null,
          passwordError: 'Password is required',
        ),
      ],
    );

    blocTest<LoginBloc, LoginState>(
      'clears the password error when the password field is edited',
      build: buildBloc,
      seed: () => const LoginFieldErrors(
        emailError: 'Username is required',
        passwordError: 'Password is required',
      ),
      act: (bloc) => bloc.add(const LoginFieldEdited(LoginField.password)),
      expect: () => [
        const LoginFieldErrors(
          emailError: 'Username is required',
          passwordError: null,
        ),
      ],
    );
  });
}
