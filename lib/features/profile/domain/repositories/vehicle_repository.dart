import 'package:acepool/features/profile/domain/entities/vehicle.dart';

abstract class VehicleRepository {
  Stream<List<Vehicle>> watchVehicles();

  Future<void> deleteVehicle(String vehicleId);

  /// If [isDefault], unsets `isDefault` on all existing vehicles first
  /// (batched), then adds the new vehicle.
  Future<void> addVehicle({
    required String type,
    required String number,
    required String brand,
    required String model,
    required int seats,
    required bool isDefault,
  });
}
