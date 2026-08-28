import 'package:acepool/features/home/domain/entities/upcoming_trip.dart';
import 'package:acepool/features/home/domain/repositories/home_repository.dart';

class GetUpcomingTripsUseCase {
  GetUpcomingTripsUseCase(this._repository);

  final HomeRepository _repository;

  Future<List<UpcomingTrip>> call() => _repository.getUpcomingTrips();
}
