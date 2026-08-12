import 'package:acepool/features/auth/domain/entities/auth_exception.dart';
import 'package:acepool/features/auth/domain/usecases/cancel_signup_usecase.dart';
import 'package:acepool/features/auth/domain/usecases/send_otp_usecase.dart';
import 'package:acepool/features/auth/domain/usecases/verify_otp_usecase.dart';
import 'package:acepool/features/auth/presentation/bloc/otp_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSendOtpUseCase extends Mock implements SendOtpUseCase {}

class MockVerifyOtpUseCase extends Mock implements VerifyOtpUseCase {}

class MockCancelSignupUseCase extends Mock implements CancelSignupUseCase {}

void main() {
  late MockSendOtpUseCase sendOtp;
  late MockVerifyOtpUseCase verifyOtp;
  late MockCancelSignupUseCase cancelSignup;

  setUp(() {
    sendOtp = MockSendOtpUseCase();
    verifyOtp = MockVerifyOtpUseCase();
    cancelSignup = MockCancelSignupUseCase();
    when(
      () => sendOtp(
        email: any(named: 'email'),
        uid: any(named: 'uid'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => cancelSignup(uid: any(named: 'uid')),
    ).thenAnswer((_) async {});
  });

  OtpBloc buildBloc() => OtpBloc(
    sendOtp: sendOtp,
    verifyOtp: verifyOtp,
    cancelSignup: cancelSignup,
  );

  group('OtpEvent equality', () {
    test('OtpStarted supports value equality based on props', () {
      expect(
        const OtpStarted(email: 'a@b.com', uid: 'u1'),
        const OtpStarted(email: 'a@b.com', uid: 'u1'),
      );
      expect(const OtpStarted(email: 'a@b.com', uid: 'u1').props, ['a@b.com', 'u1']);
      expect(
        const OtpStarted(email: 'a@b.com', uid: 'u1'),
        isNot(const OtpStarted(email: 'other@b.com', uid: 'u1')),
      );
    });

    test('OtpSubmitted supports value equality based on props', () {
      expect(const OtpSubmitted('123456'), const OtpSubmitted('123456'));
      expect(const OtpSubmitted('123456').props, ['123456']);
      expect(const OtpSubmitted('123456'), isNot(const OtpSubmitted('000000')));
    });

    test(
      'OtpResendRequested, OtpCancelled, and OtpErrorCleared support value '
      'equality',
      () {
        expect(const OtpResendRequested(), const OtpResendRequested());
        expect(const OtpCancelled(), const OtpCancelled());
        expect(const OtpErrorCleared(), const OtpErrorCleared());
      },
    );
  });

  group('OtpStarted', () {
    blocTest<OtpBloc, OtpState>(
      'emits sending then awaitingCode and sends the OTP',
      build: buildBloc,
      act: (bloc) => bloc.add(
        const OtpStarted(email: 'jdoe@ascendion.com', uid: 'uid-1'),
      ),
      expect: () => [
        const OtpState(status: OtpStatus.sending),
        const OtpState(status: OtpStatus.awaitingCode),
      ],
      verify: (_) {
        verify(
          () => sendOtp(email: 'jdoe@ascendion.com', uid: 'uid-1'),
        ).called(1);
      },
    );
  });

  group('OtpSubmitted', () {
    blocTest<OtpBloc, OtpState>(
      'emits an error and stays awaitingCode when the code is not 6 digits',
      build: buildBloc,
      seed: () => const OtpState(status: OtpStatus.awaitingCode),
      act: (bloc) => bloc.add(const OtpSubmitted('123')),
      expect: () => [
        const OtpState(
          status: OtpStatus.awaitingCode,
          errorMessage: 'Please enter the complete 6-digit OTP',
        ),
      ],
      verify: (_) {
        verifyNever(
          () => verifyOtp(
            uid: any(named: 'uid'),
            enteredOtp: any(named: 'enteredOtp'),
          ),
        );
      },
    );

    blocTest<OtpBloc, OtpState>(
      'emits [verifying, verified] on a successful 6-digit OTP',
      setUp: () {
        when(
          () => verifyOtp(
            uid: any(named: 'uid'),
            enteredOtp: any(named: 'enteredOtp'),
          ),
        ).thenAnswer((_) async => true);
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const OtpStarted(email: 'jdoe@ascendion.com', uid: 'uid-1'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const OtpSubmitted('123456'));
      },
      skip: 2,
      expect: () => [
        const OtpState(status: OtpStatus.verifying),
        const OtpState(status: OtpStatus.verified),
      ],
      verify: (_) {
        verify(
          () => verifyOtp(uid: 'uid-1', enteredOtp: '123456'),
        ).called(1);
      },
    );

    blocTest<OtpBloc, OtpState>(
      'emits an AuthException message and returns to awaitingCode on failure',
      setUp: () {
        when(
          () => verifyOtp(
            uid: any(named: 'uid'),
            enteredOtp: any(named: 'enteredOtp'),
          ),
        ).thenThrow(const AuthException('Incorrect OTP. Please try again.'));
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const OtpStarted(email: 'jdoe@ascendion.com', uid: 'uid-1'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const OtpSubmitted('000000'));
      },
      skip: 2,
      expect: () => [
        const OtpState(status: OtpStatus.verifying),
        const OtpState(
          status: OtpStatus.awaitingCode,
          errorMessage: 'Incorrect OTP. Please try again.',
        ),
      ],
    );

    blocTest<OtpBloc, OtpState>(
      'emits a generic error message and returns to awaitingCode on unexpected errors',
      setUp: () {
        when(
          () => verifyOtp(
            uid: any(named: 'uid'),
            enteredOtp: any(named: 'enteredOtp'),
          ),
        ).thenThrow(Exception('boom'));
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const OtpStarted(email: 'jdoe@ascendion.com', uid: 'uid-1'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const OtpSubmitted('000000'));
      },
      skip: 2,
      expect: () => [
        const OtpState(status: OtpStatus.verifying),
        const OtpState(
          status: OtpStatus.awaitingCode,
          errorMessage: 'Verification failed. Please try again.',
        ),
      ],
    );
  });

  group('OtpResendRequested', () {
    blocTest<OtpBloc, OtpState>(
      'emits [resending, resent] and resends the OTP',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const OtpStarted(email: 'jdoe@ascendion.com', uid: 'uid-1'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const OtpResendRequested());
      },
      skip: 2,
      expect: () => [
        const OtpState(status: OtpStatus.resending),
        const OtpState(status: OtpStatus.resent),
      ],
      verify: (_) {
        verify(
          () => sendOtp(email: 'jdoe@ascendion.com', uid: 'uid-1'),
        ).called(2);
      },
    );

    blocTest<OtpBloc, OtpState>(
      'does nothing when already resending',
      build: buildBloc,
      seed: () => const OtpState(status: OtpStatus.resending),
      act: (bloc) => bloc.add(const OtpResendRequested()),
      expect: () => <OtpState>[],
      verify: (_) {
        verifyNever(
          () => sendOtp(
            email: any(named: 'email'),
            uid: any(named: 'uid'),
          ),
        );
      },
    );
  });

  group('OtpCancelled', () {
    blocTest<OtpBloc, OtpState>(
      'cancels the signup and emits cancelled',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const OtpStarted(email: 'jdoe@ascendion.com', uid: 'uid-1'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const OtpCancelled());
      },
      skip: 2,
      expect: () => [const OtpState(status: OtpStatus.cancelled)],
      verify: (_) {
        verify(() => cancelSignup(uid: 'uid-1')).called(1);
      },
    );
  });

  group('OtpErrorCleared', () {
    blocTest<OtpBloc, OtpState>(
      'clears the error message while preserving status',
      build: buildBloc,
      seed: () => const OtpState(
        status: OtpStatus.awaitingCode,
        errorMessage: 'Incorrect OTP. Please try again.',
      ),
      act: (bloc) => bloc.add(const OtpErrorCleared()),
      expect: () => [const OtpState(status: OtpStatus.awaitingCode)],
    );

    blocTest<OtpBloc, OtpState>(
      'does nothing when there is no error message',
      build: buildBloc,
      seed: () => const OtpState(status: OtpStatus.awaitingCode),
      act: (bloc) => bloc.add(const OtpErrorCleared()),
      expect: () => <OtpState>[],
    );
  });
}
