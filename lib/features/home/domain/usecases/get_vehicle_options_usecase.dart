import 'package:acepool/features/home/domain/entities/vehicle_option.dart';
import 'package:acepool/features/home/domain/repositories/home_repository.dart';

class GetVehicleOptionsUseCase {
  GetVehicleOptionsUseCase(this._repository);

  final HomeRepository _repository;

  Future<List<VehicleOption>> call(String vehicleType) =>
      _repository.getVehicleOptions(vehicleType);
}
