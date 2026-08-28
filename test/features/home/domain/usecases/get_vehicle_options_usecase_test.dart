import 'package:acepool/features/home/domain/entities/vehicle_option.dart';
import 'package:acepool/features/home/domain/repositories/home_repository.dart';
import 'package:acepool/features/home/domain/usecases/get_vehicle_options_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockHomeRepository extends Mock implements HomeRepository {}

void main() {
  late MockHomeRepository repository;
  late GetVehicleOptionsUseCase useCase;

  setUp(() {
    repository = MockHomeRepository();
    useCase = GetVehicleOptionsUseCase(repository);
  });

  group('GetVehicleOptionsUseCase', () {
    test('forwards vehicleType to repository and returns its result', () async {
      const options = [VehicleOption(id: 'v1', label: 'Activa', type: 'two_wheeler')];
      when(() => repository.getVehicleOptions('bike')).thenAnswer((_) async => options);

      final result = await useCase('bike');

      expect(result, options);
      verify(() => repository.getVehicleOptions('bike')).called(1);
    });

    test('returns empty list when repository returns empty', () async {
      when(() => repository.getVehicleOptions('car')).thenAnswer((_) async => []);

      final result = await useCase('car');

      expect(result, isEmpty);
    });

    test('propagates exceptions thrown by the repository', () async {
      when(() => repository.getVehicleOptions(any())).thenThrow(Exception('failed'));

      expect(() => useCase('car'), throwsA(isA<Exception>()));
    });
  });
}
