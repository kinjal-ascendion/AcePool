import 'package:acepool/features/auth/domain/entities/auth_exception.dart';
import 'package:acepool/features/auth/domain/entities/auth_user.dart';
import 'package:acepool/features/auth/domain/entities/signup_details.dart';
import 'package:acepool/features/auth/domain/repositories/auth_repository.dart';
import 'package:acepool/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class FakeSignupDetails extends Fake implements SignupDetails {}

void main() {
  late MockAuthRepository repository;
  late SignUpUseCase useCase;

  setUpAll(() {
    registerFallbackValue(FakeSignupDetails());
  });

  setUp(() {
    repository = MockAuthRepository();
    useCase = SignUpUseCase(repository);
  });

  const details = SignupDetails(
    fullName: 'Jane Doe',
    employeeId: 'EMP123',
    phone: '1234567890',
    emailUsername: 'jane',
    password: 'secret1',
  );
  const user = AuthUser(uid: 'uid-1', email: 'jane@ascendion.com');

  test('forwards details to the repository and returns the resulting user', () async {
    when(() => repository.signUp(any())).thenAnswer((_) async => user);

    final result = await useCase(details);

    expect(result, user);
    verify(() => repository.signUp(details)).called(1);
  });

  test('propagates AuthException thrown by the repository', () async {
    when(
      () => repository.signUp(any()),
    ).thenThrow(const AuthException('Sign up failed. Please try again.'));

    expect(() => useCase(details), throwsA(isA<AuthException>()));
  });
}
