import '../repositories/auth_repository.dart';

class VerifyOtpUseCase {
  VerifyOtpUseCase(this._repository);

  final AuthRepository _repository;

  Future<bool> call({required String uid, required String enteredOtp}) {
    return _repository.verifyOtp(uid: uid, enteredOtp: enteredOtp);
  }
}
