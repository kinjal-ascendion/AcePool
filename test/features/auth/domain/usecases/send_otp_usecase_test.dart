import 'package:acepool/features/auth/domain/repositories/auth_repository.dart';
import 'package:acepool/features/auth/domain/usecases/send_otp_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;
  late SendOtpUseCase useCase;

  setUp(() {
    repository = MockAuthRepository();
    useCase = SendOtpUseCase(repository);
  });

  test('forwards email and uid to the repository', () async {
    when(
      () => repository.sendOtp(
        email: any(named: 'email'),
        uid: any(named: 'uid'),
      ),
    ).thenAnswer((_) async {});

    await useCase(email: 'jane@ascendion.com', uid: 'uid-1');

    verify(
      () => repository.sendOtp(email: 'jane@ascendion.com', uid: 'uid-1'),
    ).called(1);
  });

  test('propagates exceptions thrown by the repository', () async {
    when(
      () => repository.sendOtp(
        email: any(named: 'email'),
        uid: any(named: 'uid'),
      ),
    ).thenThrow(Exception('boom'));

    expect(
      () => useCase(email: 'jane@ascendion.com', uid: 'uid-1'),
      throwsA(isA<Exception>()),
    );
  });
}
