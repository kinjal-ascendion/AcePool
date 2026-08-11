import '../repositories/auth_repository.dart';

class SendOtpUseCase {
  SendOtpUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call({required String email, required String uid}) {
    return _repository.sendOtp(email: email, uid: uid);
  }
}
