import 'package:acepool/features/auth/domain/repositories/auth_repository.dart';
import 'package:acepool/features/auth/domain/usecases/cancel_signup_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;
  late CancelSignupUseCase useCase;

  setUp(() {
    repository = MockAuthRepository();
    useCase = CancelSignupUseCase(repository);
  });

  test('forwards uid to the repository', () async {
    when(
      () => repository.cancelSignup(uid: any(named: 'uid')),
    ).thenAnswer((_) async {});

    await useCase(uid: 'uid-1');

    verify(() => repository.cancelSignup(uid: 'uid-1')).called(1);
  });

  test('propagates exceptions thrown by the repository', () async {
    when(
      () => repository.cancelSignup(uid: any(named: 'uid')),
    ).thenThrow(Exception('boom'));

    expect(() => useCase(uid: 'uid-1'), throwsA(isA<Exception>()));
  });
}
