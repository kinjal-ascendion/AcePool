import 'package:acepool/core/services/directions_service.dart';
import 'package:acepool/features/home/domain/repositories/home_repository.dart';

class EstimateRouteUseCase {
  EstimateRouteUseCase(this._repository);

  final HomeRepository _repository;

  Future<RouteDetails> call({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) {
    return _repository.estimateRoute(
      originLat: originLat,
      originLng: originLng,
      destLat: destLat,
      destLng: destLng,
    );
  }
}
