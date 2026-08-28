import 'package:acepool/features/home/domain/repositories/home_repository.dart';

class GetTravelPreferenceUseCase {
  GetTravelPreferenceUseCase(this._repository);

  final HomeRepository _repository;

  Future<String?> call() => _repository.getTravelPreference();
}
