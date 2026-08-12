import 'package:acepool/features/auth/domain/entities/auth_exception.dart';
import 'package:acepool/features/auth/domain/repositories/auth_repository.dart';
import 'package:acepool/features/auth/domain/usecases/verify_otp_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;
  late VerifyOtpUseCase useCase;

  setUp(() {
    repository = MockAuthRepository();
    useCase = VerifyOtpUseCase(repository);
  });

  test('forwards uid and enteredOtp to the repository and returns its result', () async {
    when(
      () => repository.verifyOtp(
        uid: any(named: 'uid'),
        enteredOtp: any(named: 'enteredOtp'),
      ),
    ).thenAnswer((_) async => true);

    final result = await useCase(uid: 'uid-1', enteredOtp: '123456');

    expect(result, isTrue);
    verify(
      () => repository.verifyOtp(uid: 'uid-1', enteredOtp: '123456'),
    ).called(1);
  });

  test('propagates AuthException thrown by the repository', () async {
    when(
      () => repository.verifyOtp(
        uid: any(named: 'uid'),
        enteredOtp: any(named: 'enteredOtp'),
      ),
    ).thenThrow(const AuthException('Incorrect OTP. Please try again.'));

    expect(
      () => useCase(uid: 'uid-1', enteredOtp: '000000'),
      throwsA(isA<AuthException>()),
    );
  });
}
