import 'package:acepool/features/profile/domain/entities/vehicle.dart';
import 'package:acepool/features/profile/domain/repositories/vehicle_repository.dart';
import 'package:acepool/features/profile/presentation/bloc/vehicle_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockVehicleRepository extends Mock implements VehicleRepository {}

void main() {
  late MockVehicleRepository repository;

  const vehicle = Vehicle(
    id: 'v1',
    type: 'four_wheeler',
    number: 'MH12AB1234',
    brand: 'Toyota',
    model: 'Corolla',
    seats: 4,
    isDefault: true,
  );

  const vehicle2 = Vehicle(
    id: 'v2',
    type: 'two_wheeler',
    number: 'MH12CD5678',
    brand: 'Honda',
    model: 'Activa',
    seats: 2,
    isDefault: false,
  );

  setUp(() {
    repository = MockVehicleRepository();
  });

  group('VehicleEvent equality', () {
    test('supports value equality', () {
      expect(const VehicleListStarted(), const VehicleListStarted());
    });
  });

  group('VehicleState equality', () {
    test('supports value equality based on props', () {
      expect(const VehicleState(), const VehicleState());
      expect(
        const VehicleState().props,
        [VehicleListStatus.initial, const <Vehicle>[], null],
      );
      expect(
        const VehicleState(status: VehicleListStatus.loaded, vehicles: [vehicle]),
        const VehicleState(status: VehicleListStatus.loaded, vehicles: [vehicle]),
      );
      expect(
        const VehicleState(status: VehicleListStatus.loaded, vehicles: [vehicle]),
        isNot(const VehicleState(status: VehicleListStatus.loaded, vehicles: [vehicle2])),
      );
    });
  });

  group('VehicleBloc', () {
    test('initial state is VehicleState()', () {
      expect(
        VehicleBloc(vehicleRepository: repository).state,
        const VehicleState(),
      );
    });

    blocTest<VehicleBloc, VehicleState>(
      'emits [loading, loaded] with vehicles when watchVehicles emits a '
      'list',
      build: () {
        when(() => repository.watchVehicles()).thenAnswer(
          (_) => Stream.value([vehicle]),
        );
        return VehicleBloc(vehicleRepository: repository);
      },
      act: (bloc) => bloc.add(const VehicleListStarted()),
      expect: () => const [
        VehicleState(status: VehicleListStatus.loading),
        VehicleState(status: VehicleListStatus.loaded, vehicles: [vehicle]),
      ],
    );

    blocTest<VehicleBloc, VehicleState>(
      'emits [loading, loaded] with an empty list when there are no '
      'vehicles',
      build: () {
        when(() => repository.watchVehicles()).thenAnswer(
          (_) => Stream.value(const []),
        );
        return VehicleBloc(vehicleRepository: repository);
      },
      act: (bloc) => bloc.add(const VehicleListStarted()),
      expect: () => const [
        VehicleState(status: VehicleListStatus.loading),
        VehicleState(status: VehicleListStatus.loaded, vehicles: []),
      ],
    );

    blocTest<VehicleBloc, VehicleState>(
      'emits [loading, loaded, loaded] when watchVehicles emits multiple '
      'updates',
      build: () {
        when(() => repository.watchVehicles()).thenAnswer(
          (_) => Stream.fromIterable([
            [vehicle],
            [vehicle, vehicle2],
          ]),
        );
        return VehicleBloc(vehicleRepository: repository);
      },
      act: (bloc) => bloc.add(const VehicleListStarted()),
      expect: () => const [
        VehicleState(status: VehicleListStatus.loading),
        VehicleState(status: VehicleListStatus.loaded, vehicles: [vehicle]),
        VehicleState(status: VehicleListStatus.loaded, vehicles: [vehicle, vehicle2]),
      ],
    );

    blocTest<VehicleBloc, VehicleState>(
      'emits [loading, error] when watchVehicles errors',
      build: () {
        when(() => repository.watchVehicles()).thenAnswer(
          (_) => Stream<List<Vehicle>>.error(Exception('stream failed')),
        );
        return VehicleBloc(vehicleRepository: repository);
      },
      act: (bloc) => bloc.add(const VehicleListStarted()),
      expect: () => [
        const VehicleState(status: VehicleListStatus.loading),
        isA<VehicleState>()
            .having((s) => s.status, 'status', VehicleListStatus.error)
            .having(
              (s) => s.errorMessage,
              'errorMessage',
              contains('stream failed'),
            ),
      ],
    );
  });
}
