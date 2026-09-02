import 'package:acepool/features/home/domain/repositories/home_repository.dart';

class UpdateRideUseCase {
  UpdateRideUseCase(this._repository);

  final HomeRepository _repository;

  Future<void> call({
    required String rideId,
    Map<String, dynamic>? fare,
    int? seatCount,
  }) {
    return _repository.updateRide(
      rideId: rideId,
      fare: fare,
      seatCount: seatCount,
    );
  }
}
