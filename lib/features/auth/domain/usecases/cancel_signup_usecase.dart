import '../repositories/auth_repository.dart';

class CancelSignupUseCase {
  CancelSignupUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call({required String uid}) => _repository.cancelSignup(uid: uid);
}
