import '../entities/auth_user.dart';
import '../entities/signup_details.dart';
import '../repositories/auth_repository.dart';

class SignUpUseCase {
  SignUpUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthUser> call(SignupDetails details) => _repository.signUp(details);
}
